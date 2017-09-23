#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";

use Async::Trampoline::Describe qw(describe it);
use Test::More;
use Test::Exception;

use Async::Trampoline ':all';

it q(reuses queue space successfully) => sub {
    my $scheduler = Async::Trampoline::Scheduler->new(5);
    my @values = (0 .. 40);
    my @results;

    $scheduler->enqueue(async_value 0);
    for my $x (@values[1 .. $#values]) {
        $scheduler->enqueue(async_value $x);
        push @results, $scheduler->dequeue->run_until_completion;
    }
    while (my ($async) = $scheduler->dequeue) {
        push @results, $async->run_until_completion;
    }
    is "@results", "@values";
};

it q(handles many Asyncs) => sub {
    my $scheduler = Async::Trampoline::Scheduler->new(2);
    my @values = (0 .. 40);
    $scheduler->enqueue(async_value $_) for @values;
    my @results;
    while (my ($async) = $scheduler->dequeue) {
        push @results, $async->run_until_completion;
    }
    is "@results", "@values";
};

it q(handles complicated access pattern) => sub {
    my $scheduler = Async::Trampoline::Scheduler->new(2);

    for my $round (2**0 .. 2**8) {
        subtest qq(round $round) => sub {
            my @results;
            $scheduler->enqueue(async_value $_) for 0 .. $round - 1;
            for my $x ($round .. 2 * $round) {
                $scheduler->enqueue(async_value $x);
                push @results, $scheduler->dequeue->run_until_completion;
            }
            while (my ($async) = $scheduler->dequeue) {
                push @results, $async->run_until_completion;
            }
            my @values = (0 .. 2 * $round);
            is "@results", "@values";
        };
    }
};

it q(discards dupes) => sub {
    my @values = (0 .. 4);
    my @async_values = map { async_value $_ } @values;
    my @asyncs;
    push @asyncs, @async_values[$_ .. 4] for @values;  # repeat objects
    is 0+@asyncs, (@values + 1 + 2 + 3 + 4), "precondition";

    my $scheduler = Async::Trampoline::Scheduler->new;
    $scheduler->enqueue($_) for @asyncs;

    my @result_asyncs;
    while (my ($async) = $scheduler->dequeue) {
        push @result_asyncs, $async;
    }

    is 0+@result_asyncs, 0+@values;

    my @results = map { $_->run_until_completion } @result_asyncs;

    is "@results", "@values";
};

it q(knows about task dependencies) => sub {
    my $scheduler = Async::Trampoline::Scheduler->new;

    my $starter = async_value 0;
    $scheduler->enqueue($starter => (async_value 1), (async_value 2));

    my $starter_again = $scheduler->dequeue;
    is $starter, $starter_again, q(got starter async back);
    is scalar $scheduler->dequeue, undef, q(queue has no further elems);
    $scheduler->complete($starter_again);

    my @results;
    while (my ($async) = $scheduler->dequeue) {
        push @results, $async->run_until_completion;
    }
    @results = sort @results;

    is "@results", "1 2", q(got blocked tasks back);
};

done_testing;
