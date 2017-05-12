package Async::Selector::Test::Dummy;
use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

package main;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Async::Selector;
use Carp;
use Test::Memory::Cycle;

BEGIN {
    use_ok('Async::Selector::Aggregator');
}

sub create_selector {
    my $selector = Async::Selector->new();
    $selector->register(a => sub { undef });
    return $selector;
}

sub create_child {
    my ($selector, $type) = @_;
    if($type eq 'watcher') {
        return $selector->watch(a => 0, sub {});
    }elsif($type eq 'aggregator') {
        my $agg = Async::Selector::Aggregator->new();
        $agg->add(create_child($selector, 'watcher'));
        return $agg;
    }
    croak('This should not happen');
}

sub test_pure_children {
    my ($child_type) = @_;
    note("--- --- child: $child_type");
    {
        my $selector = create_selector();
        my @watchers = map { create_child($selector, $child_type) } 1..3;
        my $agg = new_ok('Async::Selector::Aggregator');
        $agg->add($_) foreach @watchers;
        foreach my $i (0 .. $#watchers) {
            ok($watchers[$i]->active, "watcher $i is active");
        }
        ok($agg->active, 'agg is active');
        is_deeply([$agg->watchers], \@watchers, 'watchers OK');
        is(scalar($selector->watchers), 3, "3 active watchers in selector");
        memory_cycle_ok($agg, "no cyclic ref in agg");
        $agg->cancel();
        foreach my $i (0 .. $#watchers) {
            ok(!$watchers[$i]->active, "watcher $i is inactive");
        }
        ok(!$agg->active, 'agg is inactive');
        is_deeply([$agg->watchers], \@watchers, 'watchers OK');
        is(scalar($selector->watchers), 0, "0 active watcher in selector");

        my $new_watcher = create_child($selector, $child_type);
        ok($new_watcher->active, 'new_watcher is active at first');
        push(@watchers, $new_watcher);
        $agg->add($new_watcher);
        ok(!$new_watcher->active, 'new_watcher becomes inactive because agg is inactive');
        ok(!$agg->active, 'agg is inactive');
        is_deeply([$agg->watchers], \@watchers, 'watchers OK');
        is(scalar($selector->watchers), 0, "0 active watcher in selector");

        $new_watcher = create_child($selector, $child_type);
        $new_watcher->cancel();
        ok(!$new_watcher->active, 'new_watcher is inactive');
        push(@watchers, $new_watcher);
        $agg->add($new_watcher);
        ok(!$new_watcher->active, 'new_watcher is still inactive');
        ok(!$agg->active, 'agg is inactive');
        is_deeply([$agg->watchers], \@watchers, 'watchers OK');
        is(scalar($selector->watchers), 0, "0 active watcher in selector");
    }
    {
        my $agg = new_ok('Async::Selector::Aggregator');
        ok($agg->active, "agg is active at first");
        my $selector = create_selector();
        my @watchers = ();
        my $new_watcher = create_child($selector, $child_type);
        $new_watcher->cancel();
        ok(!$new_watcher->active, 'new_watcher is inactive');
        push(@watchers, $new_watcher);
        $agg->add($new_watcher);
        ok(!$new_watcher->active, 'new_watcher is inactive');
        ok(!$agg->active, 'agg becomes inactive because an inactive watcher is added');
        is_deeply([$agg->watchers], \@watchers, 'watchers OK');
        is(scalar($selector->watchers), 0, '0 active watchers');

        $new_watcher = create_child($selector, $child_type);
        push(@watchers, $new_watcher);
        ok($new_watcher->active, 'new_watcher is active');
        is(scalar($selector->watchers), 1, '1 active watcher');
        $agg->add($new_watcher);
        ok(!$new_watcher->active, 'new_watcher becomes inactive');
        is(scalar($selector->watchers), 0, '0 active watcher');
        ok(!$agg->active, 'agg is inactive');
        is_deeply([$agg->watchers], \@watchers, 'watchers OK');

        $new_watcher = create_child($selector, $child_type);
        push(@watchers, $new_watcher);
        $new_watcher->cancel();
        ok(!$new_watcher->active, 'new_watcher is inactive');
        $agg->add($new_watcher);
        ok(!$new_watcher->active, 'new_watcher is still inactive');
        ok(!$agg->active, 'agg is inactive');
        is_deeply([$agg->watchers], \@watchers, 'watchers OK');
    }
    {
        my $agg = new_ok('Async::Selector::Aggregator');
        my $selector = create_selector();
        my @watchers = map { create_child($selector, $child_type) } 1..3;
        $agg->add($_) foreach @watchers;
        foreach my $i (0 .. $#watchers) {
            ok($watchers[$i]->active, "watcher $i is active");
        }
        ok($agg->active, 'agg is active');
        is_deeply([$agg->watchers], \@watchers, "watchers OK");
        is(scalar($selector->watchers), 3, "3 active watchers");
        my $new_watcher = create_child($selector, $child_type);
        $new_watcher->cancel();
        ok(!$new_watcher->active, 'new_watcher is inactive');
        push(@watchers, $new_watcher);
        $agg->add($new_watcher);
        foreach my $i (0 .. $#watchers) {
            ok(!$watchers[$i]->active, "watcher $i is inactive");
        }
        ok(!$agg->active, "agg becomes inactive because an inactive watcher is added.");
        is_deeply([$agg->watchers], \@watchers, "watchers OK");
        is(scalar($selector->watchers), 0, "0 active watcher");
    }

    {
        my $selector = create_selector();
        my $agg = new_ok('Async::Selector::Aggregator');
        ok($agg->active, 'agg is active at first');
        $agg->cancel();
        ok(!$agg->active, 'agg becomes inactive although there is no watchers in it');
        my @watchers = ();
        my $new_watcher = create_child($selector, $child_type);
        ok($new_watcher->active, 'new_watcher is active');
        is(scalar($selector->watchers), 1, '1 active watcher');
        push(@watchers, $new_watcher);
        $agg->add($new_watcher);
        ok(!$new_watcher->active, 'new_watcher becomes inactive because it is added to an inactive aggregator');
        is_deeply([$agg->watchers], \@watchers, 'watchers OK');
        is(scalar($selector->watchers), 0, '0 active watcher');
    }
}



####################

{
    my $agg = new_ok('Async::Selector::Aggregator');
    ok($agg->active, "agg is active when it's empty");
    dies_ok { $agg->add($agg) } "it croaks when you try to add the agg itself.";
    $agg->cancel;
    ok(!$agg->active, "agg becomes inactive after cancel() even when it's empty");
    dies_ok { $agg->add($agg) } "it croaks when you try to add the agg itself.";
}

test_pure_children('watcher');
test_pure_children('aggregator');

note("--- junk tests");
foreach my $case (
    {label => "undef", junk => undef},
    {label => "number", junk => 10},
    {label => "string", junk => "hoge"},
    {label => "arrayref", junk => []},
    {label => "hashref", junk => {}},
    {label => "coderef", junk => sub {}},
    {label => "other object", junk => Async::Selector::Test::Dummy->new()}
) {
    my $agg = Async::Selector::Aggregator->new();
    dies_ok { $agg->add($case->{junk}) } "add() dies when adding a junk like $case->{label}";
}

{
    note('--- heavy aggregation chain');
    my $selector = create_selector();
    my @watchers = ();
    local *make_aggregation_tree = sub {
        my ($depth) = @_;
        if($depth <= 0) {
            my $w = create_child($selector, 'watcher');
            push(@watchers, $w);
            return $w;
        }
        my $agg = Async::Selector::Aggregator->new();
        my $w = create_child($selector, 'watcher');
        push(@watchers, $w);
        $agg->add($w);
        $agg->add(make_aggregation_tree($depth - 1));
        return $agg;
    };
    my $agg = make_aggregation_tree(5);
    is(scalar(@watchers), 6, "6 watchers in the tree");
    foreach my $i (0 .. $#watchers) {
        ok($watchers[$i]->active, "watcher $i is active");
    }
    ok($agg->active, "agg is active");
    is(scalar($selector->watchers), 6, '6 active watchers');

    $agg->cancel();
    is(scalar(@watchers), 6, "6 watchers in the tree");
    foreach my $i (0 .. $#watchers) {
        ok(!$watchers[$i]->active, "watcher $i becomes inactive");
    }
    ok(!$agg->active, "agg becomes inactive by cancel()");
    is(scalar($selector->watchers), 0, '0 active watchers');

    @watchers = ();
    $agg = make_aggregation_tree(5);
    ok($agg->active, 'agg is active');
    is(scalar($selector->watchers), 6, '6 active watchers');
    my $new_watcher = create_child($selector, 'watcher');
    $new_watcher->cancel();
    $agg->add($new_watcher);
    ok(!$agg->active, 'agg becomes inactive by adding inactive watcher');
    is(scalar($selector->watchers), 0, '0 active watcher');

    @watchers = ();
    $agg = Async::Selector::Aggregator->new();
    $agg->add(create_child($selector, 'watcher'));
    $agg->cancel();
    ok(!$agg->active, 'agg is inactive');
    my $new_agg = make_aggregation_tree(5);
    ok($new_agg->active, 'new_agg is active');
    is(scalar($selector->watchers), 6, '6 active watchers');
    $agg->add($new_agg);
    ok(!$new_agg->active, 'new_agg becomes inactive because it is added to an inactive aggregator');
    is(scalar($selector->watchers), 0, '0 active watchers');
}

done_testing();

