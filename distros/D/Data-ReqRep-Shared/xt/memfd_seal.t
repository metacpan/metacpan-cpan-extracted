use strict;
use warnings;
use Test::More;

use constant { F_GET_SEALS => 1034, F_SEAL_SHRINK => 2, F_SEAL_GROW => 4 };

use Data::ReqRep::Shared;

my $rr = Data::ReqRep::Shared->new_memfd("seal", 8, 4, 64);
open(my $fh, '<&=', $rr->memfd) or die;
my $seals = fcntl($fh, F_GET_SEALS, 0);
ok $seals & F_SEAL_SHRINK, "F_SEAL_SHRINK set";
ok $seals & F_SEAL_GROW,   "F_SEAL_GROW set";
ok !truncate($fh, 0), "truncate on sealed memfd fails";

ok $rr->capacity > 0, "ops still work after sealing";

done_testing;
