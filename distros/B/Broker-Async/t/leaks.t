use strict;
use warnings;
use Broker::Async;
use Broker::Async::Worker;
use Future;
use Test::LeakTrace qw( no_leaks_ok );
use Test::More;

subtest constructor => sub {
    no_leaks_ok {
        my $broker = Broker::Async->new(
            workers => [sub { Future->new }],
        );
    } 'no leaks constructing broker';

    no_leaks_ok {
        my $broker = Broker::Async::Worker->new(
            code => sub { Future->new },
        );
    } 'no leaks constructing worker';
};

subtest 'multi-worker concurrency' => sub {
    my $broker = Broker::Async->new(
        workers => [ (sub{ $_[0] })x 2 ],
    );

    no_leaks_ok {
        my @tasks = map Future->new, 1 .. 3;
        my @results = map $broker->do($_), @tasks;
        $_->done for @tasks;
        $_->get  for @results;
    } 'no leaks after resolving tasks in multi-worker broker';
};

subtest 'per worker concurrency' => sub {
    my $broker = Broker::Async->new(
        workers => [{code => sub{ $_[0] }, concurrency => 2}],
    );

    no_leaks_ok {
        my @tasks = map Future->new, 1 .. 3;
        my @results = map $broker->do($_), @tasks;
        $_->done for @tasks;
        $_->get  for @results;
    } 'no leaks after resolving tasks with high concurrency workers';
};

done_testing;
