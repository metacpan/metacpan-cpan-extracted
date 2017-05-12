use 5.008;
use strict;
use warnings;

use Test::More;
use AnyEvent;
use AnyEvent::Promise;

plan tests => 9;

# Test single then
AnyEvent::Promise->new(sub {
    my $cv = AnyEvent->condvar;
    my $w; $w = AnyEvent->idle(
        cb => sub {
            $cv->send('foobar');
            undef $w;
        }
    );
    return $cv;
})->then(sub {
    is(shift, 'foobar', 'Single then, return ok');
})->fulfill;

# Test chained then
AnyEvent::Promise->new(sub {
    my $cv = AnyEvent->condvar;
    my $w; $w = AnyEvent->idle(
        cb => sub {
            $cv->send('foobar');
            undef $w;
        }
    );
    return $cv;
})->then(sub {
    my $ret = shift;
    is($ret, 'foobar', 'Double then, first then return ok');

    my $cv = AnyEvent->condvar;
    my $w; $w = AnyEvent->idle(
        cb => sub {
            $cv->send(uc($ret));
            undef $w;
        }
    );
    return $cv;
})->then(sub {
    is(shift, 'FOOBAR', 'Double then, second then return ok');
})->fulfill;

# Test return types
my $p1 = AnyEvent::Promise->new(sub {
    my $cv = AnyEvent->condvar;
    my $w; $w = AnyEvent->idle(
        cb => sub {
            $cv->send('foobar');
            undef $w;
        }
    );
    return $cv;
});
isa_ok($p1, 'AnyEvent::Promise');
ok(defined $p1->{fulfill}, 'First promise has callback');
isa_ok($p1->{fulfill}, 'AnyEvent::CondVar', 'First promise has callback event');

my $p2 = $p1->then(sub {
    my $ret = shift;
    my $cv = AnyEvent->condvar;
    my $w; $w = AnyEvent->idle(
        cb => sub {
            $cv->send(uc($ret));
            undef $w;
        }
    );
    return $cv;
});
isa_ok($p2, 'AnyEvent::Promise');
ok(defined $p2->{fulfill}, 'Second promise has callback');
isa_ok($p2->{fulfill}, 'AnyEvent::CondVar', 'Second promise has callback event');
