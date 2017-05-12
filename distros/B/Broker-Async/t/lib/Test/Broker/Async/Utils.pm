package Test::Broker::Async::Utils;
use strict;
use warnings;
use parent 'Exporter';
use Test::Broker::Async::Trace;

our @EXPORT = qw(
    new_tracer
    test_event_loop
);
our @EXPORT_OK = @EXPORT;

sub new_tracer {
    return Test::Broker::Async::Trace->new;
}

sub test_event_loop {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($broker, $tasks, $desc) = @_;
    $tasks = [1 .. 3] unless $tasks or @$tasks;
    $desc ||= '';
    my $failed = 0;

    my @futures = map $broker->do($_), @$tasks;
    Test::More::is(
        scalar(grep { $_->is_ready } @futures),
        0,
        ("$desc has no results ready immediately after queueing tasks")x!! $desc,
    ) or $failed++;

    $futures[-1]->get;
    Test::More::is(
        scalar(grep { $_->is_ready } @futures),
        scalar(@futures),
        ("$desc has all results ready after waiting for last result")x!! $desc,
    ) or $failed++;

    return not($failed);
}

1;
