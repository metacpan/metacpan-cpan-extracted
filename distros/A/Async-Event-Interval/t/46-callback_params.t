use warnings;
use strict;

use lib 't/lib';
use TestHelper;
use Test::More;
use Test::SharedFork;

use Async::Event::Interval;

my @params = (
    { 0 => 'a' },
    { 1 => 'b' },
    { 2 => 'c' },
);

{
    my $event = Async::Event::Interval->new(
        0,
        \&callback
    );

    for (0..2) {
        $event->start($_, $params[$_]);
        while (! $event->waiting) {}
    }

    $event->stop;
}

sub callback {
    my ($iter, $href) = @_;

    if ($iter == 0) {
        is $href->{$iter}, 'a', "start() param on iter $iter ok";
    }
    elsif ($iter == 1) {
        is $href->{$iter}, 'b', "start() param on iter $iter ok";
    }
    elsif ($iter == 2) {
        is $href->{$iter}, 'c', "start() param on iter $iter ok";
    }
}