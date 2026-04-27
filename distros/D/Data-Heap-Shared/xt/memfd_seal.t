use strict;
use warnings;
use Test::More;

use constant {
    F_GET_SEALS   => 1034,
    F_SEAL_SHRINK => 0x0002,
    F_SEAL_GROW   => 0x0004,
};

use Data::Heap::Shared;

my $h = Data::Heap::Shared->new_memfd("seal", 32);
ok $h, "heap created";

open(my $fh, '<&=', $h->memfd) or die;
my $seals = fcntl($fh, F_GET_SEALS, 0);
ok $seals & F_SEAL_SHRINK, "F_SEAL_SHRINK set";
ok $seals & F_SEAL_GROW,   "F_SEAL_GROW set";

ok !truncate($fh, 0), "truncate on sealed memfd fails";

$h->push(5, 42);
my @r = $h->pop;
is_deeply \@r, [5, 42], "ops still work after sealing";

done_testing;
