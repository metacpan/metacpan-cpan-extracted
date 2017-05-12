use Test::More 0.88;
use strict;
use warnings;

use Coro qw(:prio);

BEGIN {
    use_ok('Coro::PrioChannel::Multi');
}

my $c = Coro::PrioChannel::Multi->new();

my $l1 = $c->listen();
my $l2 = $c->listen();

$c->put(2, PRIO_IDLE);
$c->put(0);
$c->put(1, PRIO_MAX);

is($l1->get(), 1);
is($l1->get(), 0);
is($l1->get(), 2);

is($l2->get(), 1);
is($l2->get(), 0);
is($l2->get(), 2);

done_testing();
