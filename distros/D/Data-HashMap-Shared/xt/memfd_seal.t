use strict;
use warnings;
use Test::More;

use constant { F_GET_SEALS => 1034, F_SEAL_SHRINK => 2, F_SEAL_GROW => 4 };

use Data::HashMap::Shared::II;

my $m = Data::HashMap::Shared::II->new_memfd("seal", 64);
open(my $fh, '<&=', $m->memfd) or die;
my $seals = fcntl($fh, F_GET_SEALS, 0);
ok $seals & F_SEAL_SHRINK, "F_SEAL_SHRINK set";
ok $seals & F_SEAL_GROW,   "F_SEAL_GROW set";
ok !truncate($fh, 0), "truncate on sealed memfd fails";

$m->put(1, 100);
is $m->get(1), 100, "ops still work after sealing";

done_testing;
