use strict;
use warnings;
use Test::More;

use constant {
    F_GET_SEALS   => 1034,
    F_SEAL_SHRINK => 0x0002,
    F_SEAL_GROW   => 0x0004,
};

use Data::RingBuffer::Shared;

my $r = Data::RingBuffer::Shared::Int->new_memfd("seal", 16);
ok $r, "ring created";

open(my $fh, '<&=', $r->memfd) or die;
my $seals = fcntl($fh, F_GET_SEALS, 0);
ok $seals & F_SEAL_SHRINK, "F_SEAL_SHRINK set";
ok $seals & F_SEAL_GROW,   "F_SEAL_GROW set";

ok !truncate($fh, 0), "truncate on sealed memfd fails";

$r->write(42);
ok defined($r->latest), "ops still work after sealing";

done_testing;
