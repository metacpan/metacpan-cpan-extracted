use strict;
use warnings;

use Test::More;
use Time::HiRes qw(time);

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a valid CI testing platform...";
    }
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};
}

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

# Test timed interval

my $e = $mod->new(1.6, \&perform);

my $t = $e->shared_scalar;
$$t = time;
$e->start;
sleep 2;
$e->stop;

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

sub perform {
    my $time = time;
    is $time - $$t > 1.6 && $time - $$t < 1.85, 1, "Event is 1.6 seconds ok";
    done_testing();
}
