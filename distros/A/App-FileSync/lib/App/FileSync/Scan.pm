package App::FileSync::Scan;

use strict;
use warnings;

use Digest::SHA ();
use File::Spec;
use Time::HiRes ();

# Returns (\%manifest, \%stats, \%skipped).
#
# Manifest entries are keyed by relative path:
#   file: { t => 'f', s => size, m => mtime, h => sha256, mode => perm bits }
#   dir:  { t => 'd' }              (only directories that are empty after ignores)
#
# %cache is a previous manifest; entries whose size and mtime still match are reused
# without reading the file.
sub scan {
    my (%args) = @_;

    my $root = $args{root};
    die "Scan: no root given\n" unless defined $root && length $root;

    my $context = {
        root     => $root,
        ignore   => $args{ignore},
        cache    => $args{cache} || {},
        manifest => {},
        skipped  => {},
        stats    => {
            files  => 0,
            dirs   => 0,
            bytes  => 0,
            hashed => 0,
            cached => 0,
            skipped => 0,
        },
    };

    _walk($context, $root, '');

    return ($context->{manifest}, $context->{stats}, $context->{skipped});
}

sub _walk {
    my ($context, $abs, $rel) = @_;

    my $dh;
    unless (opendir($dh, $abs)) {
        $context->{skipped}{ $rel || '.' } = "cannot read directory: $!";
        $context->{stats}{skipped}++;
        return 0;
    }

    my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    closedir $dh;

    my $entries = 0;

    for my $name (@names) {
        my $child_rel = length $rel ? "$rel/$name" : $name;

        next if $context->{ignore} && $context->{ignore}->match($child_rel);

        my $child_abs = File::Spec->catfile($abs, $name);
        my @stat = Time::HiRes::lstat($child_abs);
        unless (@stat) {
            $context->{skipped}{$child_rel} = "cannot stat: $!";
            $context->{stats}{skipped}++;
            next;
        }

        if (-d _) {
            $entries++;
            my $inside = _walk($context, $child_abs, $child_rel);
            if ($inside == 0) {
                $context->{manifest}{$child_rel} = { t => 'd' };
                $context->{stats}{dirs}++;
            }
            next;
        }

        if (-f _) {
            my $entry = _file_entry($context, $child_abs, $child_rel, \@stat);
            next unless $entry;
            $context->{manifest}{$child_rel} = $entry;
            $context->{stats}{files}++;
            $context->{stats}{bytes} += $entry->{s};
            $entries++;
            next;
        }

        if (-l _) {
            $context->{skipped}{$child_rel} = 'symbolic link';
            $context->{stats}{skipped}++;
            next;
        }

        $context->{skipped}{$child_rel} = 'not a regular file';
        $context->{stats}{skipped}++;
    }

    return $entries;
}

# Remove .filesync-tmp-* left behind by an interrupted run.  Only those older than
# max_age are touched, so a concurrent writer can never lose its file.
sub clean_stale_temps {
    my (%args) = @_;

    my $root = $args{root};
    my $max_age = defined $args{max_age} ? $args{max_age} : 3600;
    return 0 unless defined $root && length $root && -d $root;

    my $now = time;
    my $removed = 0;
    my @queue = ($root);

    while (@queue) {
        my $dir = shift @queue;
        my $dh;
        next unless opendir($dh, $dir);

        for my $name (readdir($dh)) {
            next if $name eq '.' || $name eq '..';
            my $path = File::Spec->catfile($dir, $name);
            my @stat = Time::HiRes::lstat($path);
            next unless @stat;
            if (-d _) {
                push @queue, $path;
                next;
            }
            next unless $name =~ /\A\.filesync-tmp-/;
            next if $now - $stat[9] < $max_age;
            unlink($path) and $removed++;
        }
        closedir $dh;
    }

    return $removed;
}

sub _file_entry {
    my ($context, $abs, $rel, $stat) = @_;

    my $size = $stat->[7];
    my $mtime = $stat->[9];
    my $mode = $stat->[2] & 07777;

    my $cached = $context->{cache}{$rel};
    my $hash;

    if ($cached
        && ($cached->{t} || '') eq 'f'
        && defined $cached->{h}
        && $cached->{s} == $size
        && abs(($cached->{m} // -1) - $mtime) < 0.001) {
        $hash = $cached->{h};
        $context->{stats}{cached}++;
    } else {
        my $sha = Digest::SHA->new(256);
        eval { $sha->addfile($abs, 'b'); 1 } or do {
            $context->{skipped}{$rel} = "cannot read: $@";
            $context->{stats}{skipped}++;
            return undef;
        };
        $hash = $sha->hexdigest;
        $context->{stats}{hashed}++;
    }

    return {
        t    => 'f',
        s    => $size,
        m    => $mtime,
        h    => $hash,
        mode => $mode,
    };
}

1;
