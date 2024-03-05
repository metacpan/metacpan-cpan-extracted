use warnings;
use strict;

use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a valid CI testing platform...";
    }
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};
}

use Async::Event::Interval;

my @params = qw(1 2 3);

my $event = Async::Event::Interval->new(
    0,
    \&callback_multi,
    @params
);

$event->start;

sleep 1;

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

sub callback_multi {
    is $_[0], 1, "first param of array ok: 1";
    is $_[1], 2, "first param of array ok: 2";
    is $_[2], 3, "first param of array ok: 3";
    done_testing();
}


