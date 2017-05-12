use 5.008;
use strict;
use warnings;

use Test::More;
use AnyEvent;
use AnyEvent::Promise;

plan tests => 11;

# Test reject setup, fail outside callback
my $p = AnyEvent::Promise->new(sub {
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
    die('FAIL: OUTSIDE');
    my $w; $w = AnyEvent->idle(
        cb => sub {
            die('FAIL: INSIDE');
        }
    );
    return $cv;
})->then(sub {
    fail('This callback should not run');
});

isa_ok($p, 'AnyEvent::Promise', 'Promise type');
ok(defined $p->{fulfill}, 'Promise fulfill defined');
ok(defined $p->{reject}, 'Promise reject defined');
isa_ok($p->{fulfill}, 'AnyEvent::CondVar', 'Promise fulfill type');
isa_ok($p->{reject}, 'AnyEvent::CondVar', 'Promise reject type');

# Add catch
$p = $p->catch(sub {
    my $err = shift;
    ok($err =~ '^FAIL: OUTSIDE', 'Failure outside');
});

$p->fulfill;

# Test reject setup, fail outside callback
my $p1 = AnyEvent::Promise->new(sub {
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
            $cv->croak('FAIL: INSIDE');
            undef $w;
        }
    );
    return $cv;
})->then(sub {
    fail('This callback should not run');
})->catch(sub {
    my $err = shift;
    ok($err =~ '^FAIL: INSIDE', 'Failure inside');
});

# Test catch die errors
my $p2 = AnyEvent::Promise->new(sub {
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
    die('FAIL: OUTSIDE');
    my $w; $w = AnyEvent->idle(
        cb => sub {
            die('FAIL: INSIDE');
        }
    );
    return $cv;
})->then(sub {
    fail('This callback should not run');
})->catch(sub {
    my $err = shift;
    ok($err =~ '^FAIL: OUTSIDE', 'Catch outside failure');
});

$p1->fulfill;
$p2->fulfill;
