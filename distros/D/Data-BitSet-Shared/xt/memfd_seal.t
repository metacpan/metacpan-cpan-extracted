use strict;
use warnings;
use Test::More;

use constant {
    F_GET_SEALS   => 1034,
    F_SEAL_SHRINK => 0x0002,
    F_SEAL_GROW   => 0x0004,
};

use Data::BitSet::Shared;

my $b = Data::BitSet::Shared->new_memfd("seal", 128);
ok $b, "bitset created";
my $fd = $b->memfd;
ok $fd >= 0, "fd=$fd";

open(my $fh, '<&=', $fd) or die;
my $seals = fcntl($fh, F_GET_SEALS, 0);
ok $seals & F_SEAL_SHRINK, "F_SEAL_SHRINK set";
ok $seals & F_SEAL_GROW,   "F_SEAL_GROW set";

ok !truncate($fh, 0), "truncate on sealed memfd fails";

$b->set(5);
ok $b->test(5), "operations still work after sealing";

done_testing;
