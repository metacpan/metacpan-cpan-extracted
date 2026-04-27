use strict;
use warnings;
use Test::More;

use constant { F_GET_SEALS => 1034, F_SEAL_SHRINK => 2, F_SEAL_GROW => 4 };

use Data::PubSub::Shared::Int;

my $p = Data::PubSub::Shared::Int->new_memfd("seal", 32);
open(my $fh, '<&=', $p->memfd) or die;
my $seals = fcntl($fh, F_GET_SEALS, 0);
ok $seals & F_SEAL_SHRINK, "F_SEAL_SHRINK set";
ok $seals & F_SEAL_GROW,   "F_SEAL_GROW set";
ok !truncate($fh, 0), "truncate on sealed memfd fails";

$p->publish(42);
my $sub = $p->subscribe_all;
is $sub->poll, 42, "ops still work after sealing";

done_testing;
