use 5.008;
use strict;
use warnings;

use Test::More;
use AnyEvent;
use AnyEvent::Promise;

plan tests => 7;

# Test nonblocking
my $p = AnyEvent::Promise->new(sub {
    fail('Executed block without fulfillment');
});

# Non blocking promise order
my $order = 1;

sub check_order {
    my $expect = shift;
    is($order, $expect, sprintf('Expecting order %d', $order));
    $order++;
}

my $p_in = AnyEvent::Promise->new(sub {
    check_order(5);
    my $cv = AnyEvent->condvar;
    my $w; $w = AnyEvent->timer(
        after => 1,
        cb => sub {
            check_order(6);
            $cv->send('foobar');
            undef $w;
        }
    );
    return $cv;
})->then(sub {
    check_order(7);
});

my $p_out = AnyEvent::Promise->new(sub {
    check_order(2);
    my $cv = AnyEvent->condvar;
    my $w; $w = AnyEvent->timer(
        after => 1,
        cb => sub {
            check_order(3);
            $cv->send($p_in);
            undef $w;
        }
    );
    return $cv;
})->then(sub {
    check_order(4);
    return $p_in->cv;
});

check_order(1);
$p_out->fulfill;
