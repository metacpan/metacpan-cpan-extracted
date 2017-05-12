use strict;
use warnings;
use Test::More;
use Test::Builder;
use Test::Memory::Cycle;

## dummies for SYNOPSIS
sub handle_a {}
sub handle_b {}


###################### SYNOPSIS ###############

use Async::Selector;
use Async::Selector::Aggregator;

## Setup resources with 3 selectors, each of which registers 'resource'
my %resources = (
    a => { val => 0, selector => Async::Selector->new },
    b => { val => 0, selector => Async::Selector->new },
    c => { val => 0, selector => Async::Selector->new },
);
foreach my $res (values %resources) {
    $res->{selector}->register(resource => sub {
        my ($threshold) = @_;
        return $res->{val} >= $threshold ? $res->{val} : undef;
    });
}

## Aggregate 3 selectors into one. Resource names are now ('a', 'b', 'c')
sub aggregate_watch {
    my $callback = pop;
    my %watch_spec = @_;
    my $aggregator = Async::Selector::Aggregator->new();
    foreach my $key (keys %watch_spec) {
        my $watcher = $resources{$key}{selector}->watch(
            resource => $watch_spec{$key}, sub {
                my ($w, %res) = @_;
                $callback->($aggregator, $key => $res{resource});
            }
        );
        $aggregator->add($watcher);
        last if !$aggregator->active;
    }
    return $aggregator;
}

## Treat 3 selectors like a single selector almost transparently.
## $w and $watcher are actually an Async::Selector::Aggregator.
my $watcher = aggregate_watch(a => 3, b => 0, sub {
    my ($w, %res) = @_;
    handle_a($res{a}) if exists $res{a};
    handle_b($res{b}) if exists $res{b};
    $w->cancel;
});

## In this case, the callback is called immediately and $w->cancel is called.

$watcher->active;  ## => false

#################################

sub test_active_nums {
    my ($exp_active_nums, $label) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $label ||= "";
    foreach my $key (keys %$exp_active_nums) {
        my $exp_num = $exp_active_nums->{$key};
        is(scalar($resources{$key}{selector}->watchers), $exp_num, "$label: $exp_num active watchers in selector $key");
    }
}

sub set {
    my ($name, $val) = @_;
    $resources{$name}{val} = $val;
    $resources{$name}{selector}->trigger('resource');
}

ok(!$watcher->active, "watcher is inactive because resource b fired.");
test_active_nums({a => 0, b => 0, c => 0}, 'initial watch');

{
    my @results = ();
    my $agg = aggregate_watch(a => 3, b => 1, sub {
        my ($aggregator, %res) = @_;
        push(@results, \%res);
    });
    ok($agg->active, 'agg is active');
    is_deeply(\@results, [], 'results empty');
    test_active_nums({a => 1, b => 1, c => 0}, 'watch 1');
    set(b => 3);
    is_deeply(\@results, [{b => 3}], 'b fired.');
    ok($agg->active, "agg is still active.");
    memory_cycle_ok($agg, 'no cyclic refs in agg even if agg is active');

    @results = ();
    set(a => 3);
    is_deeply(\@results, [{a => 3}], 'a fired.');
    ok($agg->active, 'agg is still active.');

    @results = ();
    set(c => 0);
    is_deeply(\@results, [], 'none fired.');
    ok($agg->active, 'agg is still active.');

    $agg->cancel;
    ok(!$agg->active, 'agg is inactive');
    test_active_nums({a => 0, b => 0, c => 0}, 'no watch');
    memory_cycle_ok($agg, 'no cyclic refs in agg');
}

{
    note('--- delayed. conditional cancel');
    set($_ => 0) foreach qw(a b c);
    my @results = ();
    my $agg; $agg = aggregate_watch(b => 3, c => 4, sub {
        my ($aggregator, %res) = @_;
        push(@results, \%res);
        if($res{c} && $res{c} >= 10) {
            $agg->cancel();  ## imported from outer scope.
        }
    });
    is_deeply(\@results, [], 'results empty');
    test_active_nums({a => 0, b => 1, c => 1}, 'watcher for b and c');
    set(b => 5);
    is_deeply(\@results, [{b => 5}], 'results OK');
    ok($agg->active, 'agg is still active');
    memory_cycle_ok($agg, 'no cyclic refs in agg even if agg is active');

    @results = ();
    set(c => 3);
    is_deeply(\@results, [], 'results empty');
    set(c => 5);
    is_deeply(\@results, [{c => 5}], 'results OK');
    ok($agg->active, 'agg is still active');

    @results = ();
    set(c => 15);
    is_deeply(\@results, [{c => 15}], 'results OK');
    ok(!$agg->active, 'agg is canceled');
    test_active_nums({a => 0, b => 0, c => 0}, 'no active watchers');
    memory_cycle_ok($agg, 'now no cyclic ref in agg');
}

{
    note('--- --- immediate, one-shot');
    set($_ => 5) foreach qw(a b c);

    note('--- all fire');
    my @results = ();
    my $agg = aggregate_watch(a => 2, b => 1, c => 2, sub {
        my ($aggregator, %res) = @_;
        push(@results, \%res);
        $aggregator->cancel();
    });
    ok(!$agg->active, 'agg is already inactive');
    is(scalar(@results), 1, "1 result") or diag(explain(\@results));
    like((keys %{$results[0]})[0], qr/[abc]/, 'it is undetermined which of the 3 resources fires.');
    is((values %{$results[0]})[0], 5, 'value is 5');
    test_active_nums({a => 0, b => 0, c => 0}, 'no watch');
    memory_cycle_ok($agg, 'no cyclic refs in agg');

    note('--- single fire');
    foreach my $fire_resource (qw(a b c)) {
        @results = ();
        my %watch_spec = (a => 10, b => 10, c => 10, $fire_resource => 0);
        my $agg = aggregate_watch(%watch_spec, sub {
            my ($aggregator, %res) = @_;
            push(@results, \%res);
            $aggregator->cancel();
        });
        ok(!$agg->active, 'agg is already inactive');
        is(scalar(@results), 1, '1 result') or diag(explain(\@results));
        is((keys %{$results[0]})[0], $fire_resource, "resource $fire_resource fired.");
        is($results[0]{$fire_resource}, 5, "value is 5");
        test_active_nums({a => 0, b => 0, c => 0}, "fire_resource = $fire_resource: no watch");
        memory_cycle_ok($agg, 'no cyclic refs in agg');
    }
}

{
    note('--- --- immediate, persistent');
    set($_ => 5) foreach qw(a b c);
    my @results = ();
    note('--- all fire');
    my $agg = aggregate_watch(a => 2, b => 2, c => 0, sub {
        my ($aggregator, %res) = @_;
        push(@results, \%res);
    });
    ok($agg->active, 'agg is active');
    memory_cycle_ok($agg, 'no cyclic refs in agg even if agg is active');
    test_active_nums({a => 1, b => 1, c => 1}, '1 active watcher in a,b,c');
    is(scalar(@results), 3, '3 results');
    {
        my %reduced_res = ();
        foreach my $r (@results) {
            $reduced_res{$_} += $r->{$_} foreach keys %$r;
        }
        is_deeply(\%reduced_res, {a => 5, b => 5, c => 5}, "results OK. order of execution is not determined.");
    }

    @results = ();
    set(a => 1);
    is_deeply(\@results, [], 'no results');

    @results = ();
    set(b => 10);
    is_deeply(\@results, [{b => 10}], 'got b = 10');
    ok($agg->active, 'agg is active');
    memory_cycle_ok($agg, 'no cyclic refs in agg even if agg is active');

    @results = ();
    $agg->cancel();
    ok(!$agg->active, 'agg becomes inactive');
    memory_cycle_ok($agg, 'no cyclic refs in agg');
    test_active_nums({a => 0, b => 0, c => 0}, 'no active watchers');
    set(c => 30);
    is_deeply(\@results, [], 'no results because watchers are cancelled.');
}


done_testing();
