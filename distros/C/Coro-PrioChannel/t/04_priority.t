use Test::More 0.88;
use strict;
use warnings;

use Coro qw(:prio);
use Coro::PrioChannel;

my $c = Coro::PrioChannel->new();

$c->put(2, PRIO_IDLE);
$c->put(0);
$c->put(1, PRIO_MAX);

is($c->get(), 1);
is($c->get(), 0);
is($c->get(), 2);

done_testing();
