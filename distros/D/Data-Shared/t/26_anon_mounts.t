use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Shared qw(shared_get shared_set);

# Buffer variants reject an undef path with EFAULT; the facade falls back to their new_anon.
plan skip_all => 'Data::Buffer::Shared::I64 not installed'
    unless eval { require Data::Buffer::Shared::I64; 1 };

my $root = Data::Shared->new;
my $mounted = eval { $root->mount('b', 'buffer:i64', undef, 10); 1 };
ok $mounted, 'buffer mounts on an anonymous root' or diag $@;
shared_set($root, '/b/0', 42);
is shared_get($root, '/b/0'), 42, 'and round-trips';

# Every installed backend mounts anonymously, so a stand-in fails both ways:
# new_anon is tried second, and new's error is the one that must reach the caller.
{
    package Data::Shared::Test::NoAnon;
    sub new      { die "NoAnon needs a file\n" }
    sub new_anon { die "NoAnon has no anonymous form\n" }
}
$INC{'Data/Shared/Test/NoAnon.pm'} = 1;
my $other = Data::Shared->new;
ok !eval { $other->mount('p', 'Data::Shared::Test::NoAnon', undef, 8); 1 },
    'a backend with no working anonymous form still errors';
like $@, qr/NoAnon needs a file/, "with the constructor's own error, not the fallback's";

# An anonymous root has no directory; a missed guard for that costs only a warning.
SKIP: {
    my $anon = Data::Shared->new;
    my $file = tempdir(CLEANUP => 1) . '/explicit.shm';
    $anon->mount('m', 'buffer:i64', $file, 10);
    my (@warnings, $retained);
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $anon->unmount('m');
        $retained = -e $file;
        $anon->unlink_all;
    }
    is_deeply \@warnings, [], 'an anonymous teardown warns about nothing';
    ok $retained, 'the unmount retained the explicit file';
    ok !-e $file, 'and the teardown reclaimed it' or diag "left $file";
}

done_testing;
