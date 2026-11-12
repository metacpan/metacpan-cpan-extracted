use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use Data::Shared ();

# $. and a bare eof follow perl's last-read handle, so a manifest read must not move them.
subtest 'a manifest read leaves the host its own input handle' => sub {
    my $dir = tempdir(CLEANUP => 1);
    Data::Shared->new($dir);            # publish, so the next open reads it
    my ($fh, $file) = tempfile(UNLINK => 1);
    print {$fh} "first\nsecond\nthird\n" or die $!;
    close $fh or die $!;

    open my $in, '<', $file or die $!;
    my $line = <$in>;
    is $line, "first\n", 'the host read its first record';
    is $., 1, 'and $. counts it';
    ok !eof($in), 'its input is not at end';

    Data::Shared->new($dir);            # the call under test

    ok !eof, 'bare eof still reports the host handle, not the manifest';
    is $., 1, 'and $. still belongs to the host handle';
    my @rest = <$in>;
    is scalar @rest, 2, 'the remaining records are still readable';
    close $in;
};

# flock does not nest across descriptors, so a reopen inside a factory would wait on its own caller.
subtest 'reopening a locked root from inside a factory is refused, not hung' => sub {
    my $dir = tempdir(CLEANUP => 1);
    Data::Shared->new($dir);
    my $root = Data::Shared->open($dir);

    my $entered = 0;
    my $ok = eval {
        local $SIG{ALRM} = sub { die "hung: the lock was never refused\n" };
        alarm 10;
        $root->mount('f', sub { $entered++; Data::Shared->open($dir) });
        alarm 0;
        1;
    };
    my $err = $@;
    alarm 0;
    ok $entered, 'the factory ran';
    ok !$ok, 'the mount did not succeed';
    like $err, qr/already holds the manifest lock/,
        'the reopen is refused by name rather than blocking';
    unlike $err, qr/^hung:/, 'and it did not have to be timed out';

    ok eval { Data::Shared->open($dir); 1 },
        'the lock is released, so the store opens afterwards' or diag $@;
    is_deeply [$root->mounts], [], 'the cancelled mount left no record';

    # The guard keys on the lock file's identity, so every spelling of the directory must hit it.
    my $link = "$dir/../" . 'link-' . $$;
    my $linked = eval { symlink $dir, $link; -d $link } ? "$link/" : undef;
    for my $spelling ("$dir/", "$dir//", "$dir/.", (defined $linked ? $linked : ())) {
        my $hung;
        my $refused = eval {
            local $SIG{ALRM} = sub { die "hung\n" };
            alarm 10;
            $root->mount('g', sub { Data::Shared->open($spelling) });
            alarm 0;
            0;
        };
        my $e = $@;
        alarm 0;
        $hung = $e =~ /^hung/;
        ok !$hung, "'$spelling' does not hang";
        like $e, qr/already holds the manifest lock/, "and is refused by name";
    }
    unlink $link if defined $linked;
};

subtest 'a shared holder may still open the same root' => sub {
    my $dir = tempdir(CLEANUP => 1);
    Data::Shared->new($dir);
    my $inner;
    my $ok = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 10;
        $inner = Data::Shared::Manifest::with_lock(
            Data::Shared->open($dir), 0, sub { Data::Shared->open($dir) });
        alarm 0;
        1;
    };
    alarm 0;
    ok $ok, 'a shared lock nested in a shared lock is allowed' or diag $@;
    ok $inner, 'and returns a usable root';
};

done_testing;
