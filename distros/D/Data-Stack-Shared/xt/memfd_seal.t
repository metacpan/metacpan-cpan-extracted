use strict;
use warnings;
use Test::More;

use constant { F_GET_SEALS => 1034, F_SEAL_SHRINK => 2, F_SEAL_GROW => 4 };

use Data::Stack::Shared;

my $s = Data::Stack::Shared::Int->new_memfd("seal", 16);
open(my $fh, '<&=', $s->memfd) or die;
my $seals = fcntl($fh, F_GET_SEALS, 0);
ok $seals & F_SEAL_SHRINK, "F_SEAL_SHRINK set";
ok $seals & F_SEAL_GROW,   "F_SEAL_GROW set";
ok !truncate($fh, 0), "truncate on sealed memfd fails";

$s->push(42);
is $s->pop, 42, "ops still work after sealing";

done_testing;
