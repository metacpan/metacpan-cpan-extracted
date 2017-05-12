use strict;
use warnings;

use Async::Selector;
use Async::Selector::Aggregator;

{
    ## Level-triggered vs. Edge-triggered
    
    my $selector = Async::Selector->new();
    my $a = 10;
    $selector->register(a => sub { my $t = shift; return $a >= $t ? $a : undef });

    ## Level-triggered watch
    $selector->watch_lt(a => 5, sub { ## => LT: 10
        my ($watcher, %res) = @_;
        print "LT: $res{a}\n";
    });
    $selector->trigger('a');          ## => LT: 10
    $a = 12;
    $selector->trigger('a');          ## => LT: 12
    $a = 3;
    $selector->trigger('a');          ## Nothing happens because $a == 3 < 5.

    ## Edge-triggered watch
    $selector->watch_et(a => 2, sub { ## Nothing happens because it's edge-triggered
        my ($watcher, %res) = @_;
        print "ET: $res{a}\n";
    });
    $selector->trigger('a');          ## => ET: 3
    $a = 0;
    $selector->trigger('a');          ## Nothing happens.
    $a = 10;
    $selector->trigger('a');          ## => LT: 10
                                      ## => ET: 10
}

print "=================\n";

{
    ## Multiple resources, multiple watches
    
    my $selector = Async::Selector->new();
    my $a = 5;
    my $b = 6;
    my $c = 7;
    $selector->register(
        a => sub { my $t = shift; return $a >= $t ? $a : undef },
        b => sub { my $t = shift; return $b >= $t ? $b : undef },
        c => sub { my $t = shift; return $c >= $t ? $c : undef },
    );
    $selector->watch(a => 10, sub {
        my ($watcher, %res) = @_;
        print "Select 1: a is $res{a}\n";
        $watcher->cancel();
    });
    $selector->watch(
        a => 12, b => 15, c => 15,
        sub {
            my ($watcher, %res) = @_;
            foreach my $key (sort keys %res) {
                print "Select 2: $key is $res{$key}\n";
            }
            $watcher->cancel();
        }
    );

    ($a, $b, $c) = (11, 14, 14);
    $selector->trigger(qw(a b c));  ## -> Select 1: a is 11
    print "---------\n";
    ($a, $b, $c) = (12, 14, 20);
    $selector->trigger(qw(a b c));  ## -> Select 2: a is 12
                                    ## -> Select 2: c is 20
}

print "==============\n";

{
    ## One-shot and persistent watches
    my $selector = Async::Selector->new();
    my $A = "";
    my $B = "";
    $selector->register(
        A => sub { my $in = shift; return length($A) >= $in ? $A : undef },
        B => sub { my $in = shift; return length($B) >= $in ? $B : undef },
    );

    my $watcher_a = $selector->watch(A => 5, sub {
        my ($watcher, %res) = @_;
        print "A: $res{A}\n";
        $watcher->cancel(); ## one-shot callback
    });
    my $watcher_b = $selector->watch(B => 5, sub {
        my ($watcher, %res) = @_;
        print "B: $res{B}\n";
        ## persistent callback
    });

    ## Trigger the resources.
    ## Execution order of watcher callbacks is not guaranteed.
    ($A, $B) = ('aaaaa', 'bbbbb');
    $selector->trigger('A', 'B');   ## -> A: aaaaa
                                    ## -> B: bbbbb
    print "--------\n";
    ## $watcher_a is already canceled.
    ($A, $B) = ('AAAAA', 'BBBBB');
    $selector->trigger('A', 'B');   ## -> B: BBBBB
    print "--------\n";

    $B = "CCCCCCC";
    $selector->trigger('A', 'B');   ## -> B: CCCCCCC
    print "--------\n";

    $watcher_b->cancel();
    $selector->trigger('A', 'B');   ## Nothing happens.
}

print "=================\n";

{
    ## Watcher aggregator
    
    my $selector_a = Async::Selector->new();
    my $selector_b = Async::Selector->new();
    my $A = "";
    my $B = "";
    $selector_a->register(resource => sub { my $in = shift; return length($A) >= $in ? $A : undef });
    $selector_b->register(resource => sub { my $in = shift; return length($B) >= $in ? $B : undef });
    
    my $watcher_a = $selector_a->watch(resource => 5, sub {
        my ($watcher, %res) = @_;
        print "A: $res{resource}\n";
    });
    my $watcher_b = $selector_b->watch(resource => 5, sub {
        my ($watcher, %res) = @_;
        print "B: $res{resource}\n";
    });
    
    ## Aggregates the two watchers into $aggregator
    my $aggregator = Async::Selector::Aggregator->new();
    $aggregator->add($watcher_a);
    $aggregator->add($watcher_b);
    
    ## This cancels both $watcher_a and $watcher_b
    $aggregator->cancel();
    
    print("watcher_a: " . ($watcher_a->active ? "active" : "inactive") . "\n"); ## -> watcher_a: inactive
    print("watcher_b: " . ($watcher_b->active ? "active" : "inactive") . "\n"); ## -> watcher_b: inactive
}

