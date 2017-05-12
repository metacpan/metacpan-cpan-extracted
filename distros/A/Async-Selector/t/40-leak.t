use strict;
use warnings;
use Test::Builder;
use Test::More;
use Async::Selector;
use Test::Memory::Cycle;


note('--- test for memory leak');

my $destroyed_selectors = 0;
my $destroyed_watchers = 0;

sub resetCount {
    $destroyed_selectors = $destroyed_watchers = 0;
}

sub checkCount {
    my ($exp_selectors, $exp_watchers) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is($destroyed_selectors, $exp_selectors, "destroyed selectors: $exp_selectors");
    is($destroyed_watchers, $exp_watchers, "destroyed watchers: $exp_watchers");
}

package Async::Selector;

sub DESTROY {
    $destroyed_selectors++;
}

package Async::Selector::Watcher;

sub DESTROY {
    $destroyed_watchers++;
}

package main;

{
    resetCount();
    my $s = Async::Selector->new();
    checkCount(0,0);
}
checkCount(1,0);


{
    resetCount();
    my $s = Async::Selector->new();
    my $w = $s->watch(a => 1, sub {});
    checkCount(0,0);
    memory_cycle_ok($s, "no cyclic ref in selector");
    memory_cycle_ok($w, 'no cyclic ref in watcher');
    $w->cancel();
    checkCount(0,0);
}
checkCount(1,1);

{
    resetCount();
    my $s = Async::Selector->new();
    $s->watch(a => 1, sub {});
    memory_cycle_ok($s, "no cyclic ref in selector");
    checkCount(0,0);
}
checkCount(1,1);

{
    resetCount();
    my $w;
    {
        my $s = Async::Selector->new();
        $w = $s->watch(a => 1, sub {});
        checkCount(0,0);
        ok($w->active, "w is active");
        memory_cycle_ok($s, "no cyclic ref in selector");
        memory_cycle_ok($w, 'no cyclic ref in watcher');
    }
    checkCount(1,0);
    ok(!$w->active, "w is inactive because selector is destroyed");
    memory_cycle_ok($w, 'no cyclic ref in watcher');
}
checkCount(1,1);

{
    resetCount();
    my $w;
    {
        my $s = Async::Selector->new();
        $w = $s->watch(a => 1, sub {});
        my $x = $s->watch(a => 1, sub {});
        checkCount(0,0);
        memory_cycle_ok($s, "no cyclic ref in selector");
        memory_cycle_ok($w, 'no cyclic ref in watcher $w');
        memory_cycle_ok($x, 'no cyclic ref in watcher $x');
    }
    checkCount(1,1);
    ok(!$w->active, "w is inactive because selector is destroyed");
}
checkCount(1,2);

{
    resetCount();
    my $s = Async::Selector->new();
    my $w;
    $w = $s->watch(a => 1, sub {
        undef $w;
    });
    memory_cycle_ok($w, 'there is no cyclic ref even when $w is included in the callback');
    memory_cycle_ok($s, 'there is no cyclic ref on $s');
    $w->cancel();
    memory_cycle_ok($w, 'there is no cyclic ref on $w after $w->cancel().');
    memory_cycle_ok($s, 'there is no cyclic ref on $s after $w->cancel().');
}
checkCount(1,1);

{
    resetCount();
    my $s = Async::Selector->new();
    my $w;
    $w = $s->watch(a => 1, sub { undef $w });
    memory_cycle_ok($w, 'there is no cyclic ref even when $w is included in the callback');
    memory_cycle_ok($s, 'there is no cyclic ref on $s');
    $s->cancel($w);
    memory_cycle_ok($w, 'there is no cyclic ref on $w after $s->cancel($w).');
    memory_cycle_ok($s, 'there is no cyclic ref on $s after $s->cancel($w).');
}
checkCount(1,1);

done_testing();



