use strict;
use warnings;

use Async::Event::Interval;
use Test::More;

my $mod = 'Async::Event::Interval';

# Test timed interval

my $e = $mod->new(0.2, \&perform);

my $x = $e->shared_scalar;
$$x = 0;

is $$x, 0, "baseline var ok";

$e->start;

sleep 1;

is $$x >= 20, 1, "event is async and correct";

$e->stop;

sub perform {
    $$x += 10;
}

done_testing();
