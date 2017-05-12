use strict;
use warnings;
use Test::More;
use List::Util qw(shuffle);
use Time::HiRes qw(time);
use Coro;
use Coro::AnyEvent;

sub async_test {
    my ($timeout, $f, @args) = @_;

    my ($test, $cancel) = @_;
    my $timedout = 0;
    my $result;

    $cancel = async {
        Coro::AnyEvent::sleep 0.1;
        $test->safe_cancel;
        $timedout = 1;
    };

    $test = async { $result = $f->(@_); $cancel->safe_cancel; } @args;

    $cancel->join, $test->join;

    return ($timedout, $result);
}

my $class = 'Coro::PriorityQueue';

use_ok($class) or BAIL_OUT;

subtest 'initial state' => sub {
    my $q = new_ok($class, [1]) or BAIL_OUT;
    ok($q->is_empty, 'queue empty initially');
    ok(!$q->is_full, 'queue not full initially');
};

subtest 'insert' => sub {
    my $q = new_ok($class, [4]) or BAIL_OUT;

    foreach my $i (1 .. 4) {
        is($q->insert($i), $i, 'insert');
        is($q->count, $i, 'count');
    }

    my ($timeout, $result) = async_test(0.2, sub { $q->insert(5) });
    ok($timeout, 'insert on full queue blocks');
};

subtest 'remove' => sub {
    my $n = 10;
    my $q = new_ok($class, [$n]) or BAIL_OUT;

    foreach my $i (shuffle 1 .. $n) {
        $q->insert($i);
    }

    ok($q->is_full, 'is_full');
    is($q->count, $n);

    foreach my $i (1 .. $n) {
        is($q->remove, $i, 'ordering');
    }

    ok($q->is_empty, 'is_empty');

    my ($timeout, $result) = async_test(0.2, sub { $q->remove });
    ok($timeout, 'remove on empty queue blocks');
};

subtest 'shutdown' => sub {
    my $n = 4;
    my $q = new_ok($class, [$n]) or BAIL_OUT;
    my @items = 1 .. $n;

    $q->insert($_) foreach @items;

    $q->shutdown;

    eval { $q->insert(42) };
    ok($@, 'insert fails after queue shutdown');

    foreach my $i (@items) {
        is($q->remove, $i, 'remove existing item ok after shutdown');
    }

    ok(!defined $q->remove, 'remove returns undef after queue shutdown when empty');
};

done_testing;
