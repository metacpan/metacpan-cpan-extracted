use warnings;
use strict;

use Async::Event::Interval;
use Test::More;


my @params = qw(1 2 3);

my $event = Async::Event::Interval->new(
    1,
    \&callback_multi,
    @params
);

$event->start;

sleep 1; # your app does other stuff here

$event->stop;

sub callback_multi {
    is $_[0], 1, "first param of array ok: 1";
    is $_[1], 2, "first param of array ok: 2";
    is $_[2], 3, "first param of array ok: 3";
    done_testing();
}


