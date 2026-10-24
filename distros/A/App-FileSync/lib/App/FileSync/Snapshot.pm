package App::FileSync::Snapshot;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Copy ();
use File::Path qw(make_path remove_tree);
use File::Spec;
use Time::HiRes ();

use App::FileSync qw(validate_relpath);

our $DIR_NAME = '.filesync-snapshots';

sub snapshot_root {
    my ($root) = @_;
    die "Snapshot: no sync root given\n" unless defined $root && length $root;
    return File::Spec->catdir($root, $DIR_NAME);
}

sub date_for_epoch {
    my ($epoch) = @_;
    my @t = gmtime(defined $epoch ? $epoch : time);
    return sprintf('%04d-%02d-%02d', $t[5] + 1900, $t[4] + 1, $t[3]);
}

sub is_date {
    my ($date) = @_;
    return 0 unless defined $date;
    return $date =~ /\A\d{4}-\d{2}-\d{2}\z/ ? 1 : 0;
}

sub default_mode {
    return $^O eq 'MSWin32' ? 'copy' : 'hardlink';
}

# Snapshot the mirrored tree into <root>/.filesync-snapshots/YYYY-MM-DD/.
#
# A day is never overwritten: the first snapshot of the day is the state before
# that day's first sync, which is the one worth keeping.
sub create {
    my (%args) = @_;

    my $root = $args{root};
    die "Snapshot: no sync root given\n" unless defined $root && length $root;
    die "Snapshot: $root is not a directory\n" unless -d $root;

    my $date = defined $args{date} ? $args{date} : date_for_epoch($args{now});
    die "Snapshot: bad date '$date' (want YYYY-MM-DD)\n" unless is_date($date);

    my $mode = defined $args{mode} ? $args{mode} : default_mode();
    die "Snapshot: bad mode '$mode' (want hardlink or copy)\n"
        unless $mode eq 'hardlink' || $mode eq 'copy';

    my $dir = snapshot_root($root);
    my $target = File::Spec->catdir($dir, $date);

    if (-e $target) {
        return {
            date    => $date,
            path    => $target,
            created => 0,
            files   => 0,
            bytes   => 0,
            mode    => $mode,
        };
    }

    make_path($dir) unless -d $dir;
    _clean_stale_temps($dir);

    my $temp = File::Spec->catdir($dir, '.tmp-' . $$ . '-' . int(rand(1_000_000)));
    make_path($temp);

    my $counts = { files => 0, bytes => 0, linked => 0, copied => 0 };

    my $ok = eval {
        _mirror(src => $root, dst => $temp, mode => $mode, counts => $counts);
        rename($temp, $target)
            or die "Snapshot: cannot rename $temp to $target: $!\n";
        1;
    };

    unless ($ok) {
        my $error = $@;
        eval { remove_tree($temp) };
        die $error;
    }

    return {
        date    => $date,
        path    => $target,
        created => 1,
        files   => $counts->{files},
        bytes   => $counts->{bytes},
        linked  => $counts->{linked},
        copied  => $counts->{copied},
        mode    => $mode,
    };
}

sub _mirror {
    my (%args) = @_;

    my ($src, $dst) = @args{qw(src dst)};
    my $counts = $args{counts};

    my $dh;
    unless (opendir($dh, $src)) {
        die "Snapshot: cannot read $src: $!\n";
    }
    my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    closedir $dh;

    for my $name (@names) {
        my $from = File::Spec->catfile($src, $name);
        my $to   = File::Spec->catfile($dst, $name);

        # The snapshot directory itself and the marker/temp files are not part
        # of the mirror, so they must not be captured either.
        next if $name eq $DIR_NAME;
        next if $name =~ /\A\.filesync-/;

        my @stat = Time::HiRes::lstat($from);
        next unless @stat;

        if (-d _) {
            make_path($to) unless -d $to;
            _mirror(src => $from, dst => $to, mode => $args{mode}, counts => $counts);
            chmod($stat[2] & 07777, $to) unless $^O eq 'MSWin32';
            next;
        }

        next unless -f _;

        my $made = 0;
        if ($args{mode} eq 'hardlink') {
            $made = link($from, $to);
            $counts->{linked}++ if $made;
        }

        unless ($made) {
            File::Copy::copy($from, $to)
                or die "Snapshot: cannot copy $from to $to: $!\n";
            $counts->{copied}++;
        }

        chmod($stat[2] & 07777, $to) unless $^O eq 'MSWin32';
        utime($stat[9], $stat[9], $to);

        $counts->{files}++;
        $counts->{bytes} += $stat[7];
    }

    return 1;
}

# Remove interrupted attempts older than an hour; a concurrent snapshot keeps its
# own temporaries because they are newer than that.
sub _clean_stale_temps {
    my ($dir) = @_;

    my $dh;
    return 0 unless opendir($dh, $dir);
    my @names = readdir($dh);
    closedir $dh;

    my $now = time;
    for my $name (@names) {
        next unless $name =~ /\A\.tmp-\d+-\d+\z/;
        my $path = File::Spec->catdir($dir, $name);
        my @stat = Time::HiRes::lstat($path);
        next unless @stat && -d _;
        next if $now - $stat[9] < 3600;
        eval { remove_tree($path) };
    }

    return 1;
}

# Every snapshot, newest first.  Each entry has date, path, files and bytes.
sub list {
    my (%args) = @_;

    my $root = $args{root};
    die "Snapshot: no sync root given\n" unless defined $root && length $root;

    my $dir = snapshot_root($root);
    return [] unless -d $dir;

    my $dh;
    unless (opendir($dh, $dir)) {
        die "Snapshot: cannot read $dir: $!\n";
    }
    my @dates = sort grep { /\A\d{4}-\d{2}-\d{2}\z/ && -d File::Spec->catdir($dir, $_) }
        readdir($dh);
    closedir $dh;

    my @snapshots;
    for my $date (reverse @dates) {
        my $path = File::Spec->catdir($dir, $date);
        my $counts = { files => 0, bytes => 0 };
        _count($path, $counts);
        push @snapshots, {
            date  => $date,
            path  => $path,
            files => $counts->{files},
            bytes => $counts->{bytes},
        };
    }

    return \@snapshots;
}

sub _count {
    my ($dir, $counts) = @_;

    my $dh;
    return 0 unless opendir($dh, $dir);
    my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    closedir $dh;

    for my $name (@names) {
        my $path = File::Spec->catfile($dir, $name);
        my @stat = Time::HiRes::lstat($path);
        next unless @stat;
        if (-d _) {
            _count($path, $counts);
            next;
        }
        next unless -f _;
        $counts->{files}++;
        $counts->{bytes} += $stat[7];
    }

    return 1;
}

# Keep the newest $keep snapshots, remove the rest.  Returns removed and kept dates.
sub prune {
    my (%args) = @_;

    my $root = $args{root};
    die "Snapshot: no sync root given\n" unless defined $root && length $root;

    my $keep = $args{keep};
    my $snapshots = list(root => $root);

    return { removed => [], kept => [ map { $_->{date} } @{$snapshots} ] }
        unless defined $keep && $keep > 0 && @{$snapshots} > $keep;

    my @kept = map { $_->{date} } @{$snapshots}[ 0 .. $keep - 1 ];
    my @removed = map { $_->{date} } @{$snapshots}[ $keep .. $#{$snapshots} ];

    unless ($args{dry_run}) {
        for my $date (@removed) {
            my $path = File::Spec->catdir(snapshot_root($root), $date);
            my $errors;
            remove_tree($path, { error => \$errors }) or do {
                my ($first) = map { "$_: $errors->{$_}" } sort keys %{$errors};
                die "Snapshot: cannot remove $path" . (defined $first ? " ($first)" : '') . "\n";
            };
        }
    }

    return { removed => \@removed, kept => \@kept };
}

# Copy DATE/[PATH] out of a snapshot into $to.  Existing destinations are
# replaced: this is a rollback, not a merge.
sub restore {
    my (%args) = @_;

    my $root = $args{root};
    die "Snapshot: no sync root given\n" unless defined $root && length $root;

    my $date = $args{date};
    die "Snapshot: --date is required\n" unless defined $date && length $date;
    die "Snapshot: bad date '$date' (want YYYY-MM-DD)\n" unless is_date($date);

    my $snapshot = File::Spec->catdir(snapshot_root($root), $date);
    die "Snapshot: no snapshot for $date under " . snapshot_root($root) . "\n"
        unless -d $snapshot;

    my $to = $args{to};
    die "Snapshot: no destination given\n" unless defined $to && length $to;
    make_path($to) unless -d $to;
    die "Snapshot: destination $to is not a directory\n" unless -d $to;

    my @paths = @{ $args{paths} || [] };
    if (!@paths) {
        my $dh;
        opendir($dh, $snapshot) or die "Snapshot: cannot read $snapshot: $!\n";
        @paths = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
        closedir $dh;
    }

    my $counts = { files => 0, bytes => 0, paths => [] };

    for my $rel (@paths) {
        my ($safe, $reason) = validate_relpath($rel);
        die "Unsafe snapshot path '$rel': $reason\n" unless $safe;

        my $from = File::Spec->catfile($snapshot, split m{/}, $rel);
        die "Snapshot $date has no path '$rel'\n" unless -e $from || -l $from;

        my $dst = File::Spec->catfile($to, split m{/}, $rel);
        _copy_out(src => $from, dst => $dst, counts => $counts, dry_run => $args{dry_run});
        push @{ $counts->{paths} }, $rel;
    }

    return {
        date  => $date,
        from  => $snapshot,
        to    => $to,
        files => $counts->{files},
        bytes => $counts->{bytes},
        paths => $counts->{paths},
    };
}

sub _copy_out {
    my (%args) = @_;

    my ($src, $dst) = @args{qw(src dst)};
    my $counts = $args{counts};

    my @stat = Time::HiRes::lstat($src);
    die "Snapshot: cannot stat $src: $!\n" unless @stat;

    if (-d _) {
        make_path($dst) unless -d $dst;
        my $dh;
        opendir($dh, $src) or die "Snapshot: cannot read $src: $!\n";
        my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
        closedir $dh;
        for my $name (@names) {
            _copy_out(
                src    => File::Spec->catfile($src, $name),
                dst    => File::Spec->catfile($dst, $name),
                counts => $counts,
                dry_run => $args{dry_run},
            );
        }
        unless ($args{dry_run}) {
            chmod($stat[2] & 07777, $dst) unless $^O eq 'MSWin32';
            utime($stat[9], $stat[9], $dst);
        }
        return 1;
    }

    die "Snapshot: $src is not a regular file\n" unless -f _;

    $counts->{files}++;
    $counts->{bytes} += $stat[7];

    return 1 if $args{dry_run};

    if (-d $dst && !-l $dst) {
        my $errors;
        remove_tree($dst, { error => \$errors })
            or die "Snapshot: cannot replace directory $dst\n";
    } elsif (-e $dst || -l $dst) {
        unlink $dst or die "Snapshot: cannot replace $dst: $!\n";
    }

    my $parent = dirname($dst);
    make_path($parent) unless -d $parent;

    File::Copy::copy($src, $dst)
        or die "Snapshot: cannot copy $src to $dst: $!\n";

    chmod($stat[2] & 07777, $dst) unless $^O eq 'MSWin32';
    utime($stat[9], $stat[9], $dst);

    return 1;
}

1;
