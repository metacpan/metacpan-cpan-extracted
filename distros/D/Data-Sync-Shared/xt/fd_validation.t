use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Sync::Shared;

# /dev/null rejection
SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::Sync::Shared::Semaphore->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

# Wrong-type fd (valid primitive but wrong type requested)
{
    my $sem = Data::Sync::Shared::Semaphore->new_memfd("t", 3);
    my $r = eval { Data::Sync::Shared::Barrier->new_from_fd($sem->memfd) };
    ok !defined($r), 'wrong-type fd rejected';
    like $@, qr/(invalid|type|incompatible)/i, 'meaningful error';
}

# Valid roundtrip
{
    my $sem = Data::Sync::Shared::Semaphore->new_memfd("t", 3);
    my $sem2 = Data::Sync::Shared::Semaphore->new_from_fd($sem->memfd);
    ok $sem2->try_acquire, 'valid semaphore accepted';
}

done_testing;
