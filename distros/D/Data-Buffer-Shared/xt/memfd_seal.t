use strict;
use warnings;
use Test::More;

use constant { F_GET_SEALS => 1034, F_SEAL_SHRINK => 2, F_SEAL_GROW => 4 };

use Data::Buffer::Shared::I64;

my $b = Data::Buffer::Shared::I64->new_memfd("seal", 16);
open(my $fh, '<&=', $b->fd) or die;
my $seals = fcntl($fh, F_GET_SEALS, 0);
ok $seals & F_SEAL_SHRINK, "F_SEAL_SHRINK set";
ok $seals & F_SEAL_GROW,   "F_SEAL_GROW set";
ok !truncate($fh, 0), "truncate on sealed memfd fails";

$b->set(0, 42);
is $b->get(0), 42, "ops still work after sealing";

done_testing;
