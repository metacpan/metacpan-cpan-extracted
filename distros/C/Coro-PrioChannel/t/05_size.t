use Test::More 0.88;
use strict;
use warnings;

use Coro qw(:prio);
use Coro::PrioChannel;

my $c = Coro::PrioChannel->new();

$c->put(2, PRIO_IDLE);
$c->put(0);
$c->put(1, PRIO_MAX);

is($c->size(), 3, "Add up all the items across all queues");
is($c->size(PRIO_NORMAL), 2, "Add up all the items of normal priority and higher");

done_testing();
