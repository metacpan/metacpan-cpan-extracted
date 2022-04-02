use strict;
use warnings;

use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a valid CI testing platform...";
    }
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};
}

my $event = Async::Event::Interval->new(
    0.3,
    sub {
        kill 9, $$;
    },
);

use Async::Event::Interval;

$event->start;

is $event->status > 0, 1, "status ok at start";

select(undef, undef, undef, 0.6);

is $event->status, 0, "upon crash, status return ok";
is $event->error, 1, "upon crash, error return ok";

if ($event->error){
    $event->restart;
    is $event->status > 0, 1, "after restart, status ok again";
    is $event->error, 0, "...so is error";
}

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

done_testing();

