package App::FileSync::Verify;

use strict;
use warnings;

use Digest::SHA ();
use File::Spec;

use App::FileSync::Scan;

# Compare a tree with the record of what it should hold (the server index, or the
# client's cached base).  Returns a report; it never writes anything.
#
# Without "deep", entries whose size and mtime still match are trusted, which is
# what makes a verify of a large tree cheap.  "--deep" rehashes everything, and
# "sample" rehashes that many matching files at random.
sub verify {
    my (%args) = @_;

    my $root = $args{root};
    die "Verify: no root given\n" unless defined $root && length $root;
    die "Verify: $root is not a directory\n" unless -d $root;

    my $entries = $args{entries} || {};
    my $deep    = $args{deep} ? 1 : 0;

    my ($manifest, $stats) = App::FileSync::Scan::scan(
        root   => $root,
        ignore => $args{ignore},
        cache  => $deep ? {} : $entries,
    );

    my (@modified, @missing, @extra);
    my %seen;

    for my $path (sort keys %{$entries}) {
        my $entry = $entries->{$path};
        next unless ref($entry) eq 'HASH';

        my $type = defined $entry->{t} ? $entry->{t} : 'f';
        my $found = $manifest->{$path};

        if (!$found) {
            # The scanner only reports directories that are empty, so an empty
            # directory that has since gained a file is not missing.
            if ($type eq 'd' && -d File::Spec->catfile($root, split m{/}, $path)) {
                next;
            }

            push @missing, { p => $path, t => $type };
            $seen{$path} = 1;
            next;
        }

        my $found_type = defined $found->{t} ? $found->{t} : 'f';
        if ($type ne $found_type) {
            push @modified, { p => $path, reason => 'type changed' };
            $seen{$path} = 1;
            next;
        }

        next if $found_type eq 'd';

        next unless defined $entry->{h} && defined $found->{h};
        next if $entry->{h} eq $found->{h};

        push @modified, {
            p        => $path,
            expected => $entry->{h},
            got      => $found->{h},
        };
        $seen{$path} = 1;
    }

    for my $path (sort keys %{$manifest}) {
        next if $entries->{$path};
        next if $seen{$path};
        push @extra, {
            p => $path,
            t => defined $manifest->{$path}{t} ? $manifest->{$path}{t} : 'f',
        };
    }

    my $sampled = 0;
    my $sample = $args{sample};
    if (defined $sample && $sample > 0 && !$deep) {
        my @candidates = grep {
            $entries->{$_}
                && ref($entries->{$_}) eq 'HASH'
                && (defined $entries->{$_}{t} ? $entries->{$_}{t} : 'f') eq 'f'
                && $manifest->{$_}
                && (defined $manifest->{$_}{t} ? $manifest->{$_}{t} : 'f') eq 'f'
        } sort keys %{$entries};

        my $wanted = $sample > @candidates ? scalar @candidates : $sample;
        for my $path (_sample(\@candidates, $wanted)) {
            my $got = _hash(File::Spec->catfile($root, split m{/}, $path));
            next unless defined $got;
            $sampled++;
            next if !defined $entries->{$path}{h} || $got eq $entries->{$path}{h};
            next if $seen{$path};
            push @modified, {
                p        => $path,
                expected => $entries->{$path}{h},
                got      => $got,
                sampled  => 1,
            };
            $seen{$path} = 1;
        }
    }

    @modified = sort { $a->{p} cmp $b->{p} } @modified;
    @missing  = sort { $a->{p} cmp $b->{p} } @missing;
    @extra    = sort { $a->{p} cmp $b->{p} } @extra;

    my $files = scalar grep {
        (defined $manifest->{$_}{t} ? $manifest->{$_}{t} : 'f') eq 'f'
    } keys %{$manifest};

    return {
        root     => $root,
        ok       => (@modified || @missing || @extra) ? 0 : 1,
        deep     => $deep,
        files    => $files,
        known    => scalar(keys %{$entries}),
        rehashed => $stats->{hashed} + $sampled,
        trusted  => $stats->{cached},
        sampled  => $sampled,
        modified => \@modified,
        missing  => \@missing,
        extra    => \@extra,
    };
}

# A partial Fisher-Yates shuffle; only the first $count entries are needed.
sub _sample {
    my ($items, $count) = @_;

    my @copy = @{$items};
    return () if $count <= 0;
    $count = @copy if $count > @copy;

    for my $i (0 .. $count - 1) {
        my $j = $i + int(rand(@copy - $i));
        @copy[ $i, $j ] = @copy[ $j, $i ];
    }

    return @copy[ 0 .. $count - 1 ];
}

sub _hash {
    my ($path) = @_;

    return undef unless -f $path;
    my $sha = Digest::SHA->new(256);
    eval { $sha->addfile($path, 'b'); 1 } or return undef;
    return $sha->hexdigest();
}

1;
