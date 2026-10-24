package App::FileSync::Trash;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Copy ();
use File::Path qw(make_path remove_tree);
use File::Spec;
use Time::HiRes ();

# Move a file or directory into <root>/YYYY/MM/DD/<rel>.
# Returns the absolute destination path.
sub move_to_trash {
    my (%args) = @_;

    my $src = $args{src};
    my $rel = $args{rel};
    my $root = $args{root};
    my $epoch = defined $args{epoch} ? $args{epoch} : time;

    die "Trash: no source given\n" unless defined $src && length $src;
    die "Trash: no relative path given\n" unless defined $rel && length $rel;
    die "Trash: no root given\n" unless defined $root && length $root;

    my @t = gmtime($epoch);
    my $day_dir = File::Spec->catdir($root, sprintf('%04d', $t[5] + 1900),
        sprintf('%02d', $t[4] + 1), sprintf('%02d', $t[3]));

    my $destination = File::Spec->catfile($day_dir, split m{/}, $rel);
    make_path(dirname($destination)) unless -d dirname($destination);

    # Two deletions of the same path on the same day keep both.
    my $final = $destination;
    my $suffix = 1;
    while (-e $final || -l $final) {
        $final = "$destination.$suffix";
        $suffix++;
    }

    if (!rename($src, $final)) {
        my $rename_error = $!;
        if (-d $src) {
            die "Cannot move $src to $final: $rename_error\n";
        }
        # Different filesystem: copy, verify nothing was lost, then unlink.
        File::Copy::copy($src, $final)
            or die "Cannot copy $src to $final: " . ($! || $rename_error) . "\n";
        unlink $src or die "Copied $src to $final but cannot remove the original: $!\n";
    }

    return $final;
}

# Remove day buckets older than $days.  Returns the list of removed directories.
sub prune {
    my (%args) = @_;

    my $root = $args{root};
    my $days = defined $args{days} ? $args{days} : 30;
    my $now  = defined $args{now} ? $args{now} : time;

    return [] unless defined $root && length $root && -d $root;
    return [] unless $days && $days > 0;

    my $cutoff = $now - ($days * 24 * 60 * 60);

    my @removed;
    for my $year (_children($root)) {
        next unless $year =~ /\A\d{4}\z/;
        for my $month (_children(File::Spec->catdir($root, $year))) {
            next unless $month =~ /\A\d{2}\z/;
            for my $day (_children(File::Spec->catdir($root, $year, $month))) {
                next unless $day =~ /\A\d{2}\z/;

                # Compare whole days so a mid-day run does not prune a bucket
                # that only just crossed the boundary.
                my $bucket_epoch = _midnight_epoch($year, $month, $day);
                next if $bucket_epoch > $cutoff;

                my $dir = File::Spec->catdir($root, $year, $month, $day);
                if ($args{dry_run}) {
                    push @removed, $dir;
                } elsif (remove_tree($dir, { error => \my $errors })) {
                    push @removed, $dir;
                }
            }
        }
    }

    return \@removed;
}

# Every stored version of a path, newest first.
sub versions {
    my (%args) = @_;

    my $root = $args{root};
    my $rel = $args{rel};

    return [] unless defined $root && -d $root;

    my @found;
    for my $year (_children($root)) {
        next unless $year =~ /\A\d{4}\z/;
        for my $month (_children(File::Spec->catdir($root, $year))) {
            next unless $month =~ /\A\d{2}\z/;
            for my $day (_children(File::Spec->catdir($root, $year, $month))) {
                next unless $day =~ /\A\d{2}\z/;
                my $candidate = File::Spec->catfile($root, $year, $month, $day, split m{/}, $rel);
                if (-e $candidate || -l $candidate) {
                    push @found, $candidate;
                }

                # Collisions on the same day are stored as path.1, path.2, ...
                for my $suffix (1 .. 99) {
                    my $numbered = "$candidate.$suffix";
                    last unless -e $numbered || -l $numbered;
                    push @found, $numbered;
                }
            }
        }
    }

    return [ reverse sort @found ];
}

# Copy one trashed version to a destination, preserving mode and mtime.
# The trash entry is left in place, so the same version can be restored twice.
sub restore {
    my (%args) = @_;

    my $src = $args{src};
    my $to  = $args{to};

    die "Trash: no source given\n" unless defined $src && length $src;
    die "Trash: no destination given\n" unless defined $to && length $to;
    die "Trash: $src is not there\n" unless -e $src || -l $src;
    die "Trash: refusing to overwrite $to\n" if -e $to || -l $to;

    _restore_entry($src, $to);
    return $to;
}

sub _restore_entry {
    my ($src, $to) = @_;

    my @stat = Time::HiRes::lstat($src);
    die "Trash: cannot stat $src: $!\n" unless @stat;

    if (-d _) {
        make_path($to) unless -d $to;
        for my $name (_children($src)) {
            _restore_entry(File::Spec->catfile($src, $name), File::Spec->catfile($to, $name));
        }
        chmod($stat[2] & 07777, $to) unless $^O eq 'MSWin32';
        utime($stat[9], $stat[9], $to);
        return 1;
    }

    die "Trash: $src is not a regular file\n" unless -f _;

    make_path(dirname($to)) unless -d dirname($to);
    File::Copy::copy($src, $to) or die "Trash: cannot copy $src to $to: $!\n";
    chmod($stat[2] & 07777, $to) unless $^O eq 'MSWin32';
    utime($stat[9], $stat[9], $to);

    return 1;
}

# ".../trash/2026/10/22/a/b.txt" -> "2026-10-22"
sub date_of {
    my ($path) = @_;
    return $path =~ m{[/\\](\d{4})[/\\](\d{2})[/\\](\d{2})[/\\]}
        ? "$1-$2-$3"
        : undef;
}

sub _children {
    my ($dir) = @_;
    my $dh;
    return () unless opendir($dh, $dir);
    my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    closedir $dh;
    return @names;
}

sub _midnight_epoch {
    my ($year, $month, $day) = @_;
    require Time::Local;
    return Time::Local::timegm(0, 0, 0, $day, $month - 1, $year);
}

1;
