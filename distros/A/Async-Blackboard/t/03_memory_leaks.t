#!/usr/bin/env perl

use strict;
use warnings FATAL => "all";
use EV;
use Async::Blackboard;
use BSD::Resource;
use Devel::Leak;

use Test::More;

=head1 TESTS

A battery of tests proving there are no memory leaks.

=over 4

=cut

{
    package okayer;
    use Test::More;

    sub new {
        my ($class, %expect) = @_;
        bless {%expect}, $class;
    }

    sub foo {
        my ($self, $arg) = @_;

        $self->{foo} eq $arg or die "$self->{foo} eq $arg";
    }

    sub bar {
        my ($self, $arg) = @_;

        $self->{bar} eq $arg or die "$self->{bar} eq $arg";
    }

    sub foobar {
        my ($self, $foo, $bar) = @_;

        $self->{foo} eq $foo &&
        $self->{bar} eq $bar or die "both args match expect";
    }
}

sub run_extensive_tests {
    {
        my $blackboard = Async::Blackboard->new();
        my $okayer     = okayer->new(
            foo => "foo",
            bar => "bar",
        );

        $blackboard->watch([qw( foo bar )], [ $okayer, "foobar" ]);
        $blackboard->watch(foo => [ $okayer, "foo" ]);
        $blackboard->watch(bar => [ $okayer, "bar" ]);

        $blackboard->put(foo => "foo");
        $blackboard->put(bar => "bar");

        $blackboard->clear;

        # Put a list of keys.
        $blackboard->put(foo => "foo", bar => "bar");
    }

    {
        my $blackboard = Async::Blackboard->new();

        $blackboard->put(key => "value");

        my $clone = $blackboard->clone;

        $blackboard->get("key") eq $clone->get("key") or die
        "\$blackboard and \$clone shall both have \"key\"";
    }
    {
        my $blackboard = Async::Blackboard->new();

        my $value = "test";

        $blackboard->put(foo => $value);

        $blackboard->get("foo") eq $value or die "Value is the same";
    }

    {
        my $blackboard = Async::Blackboard->build(
            watchers => [
                [qw( foo )] => sub { shift eq 1 or die "foo" },
                [qw( bar )] => sub { shift eq 1 or die "bar" },
            ],
        )->clone;

        $blackboard->put(foo => 1);
        $blackboard->put(bar => 1);

        $blackboard->clear;
        $blackboard->hangup;

        $blackboard->put(foo => 1);
    }

    {
        my $i = 0;
        my $blackboard = Async::Blackboard->build(
            watchers => [
                foo => sub { shift eq $i or die "foo" },
            ],
        )->clone;

        $blackboard->put(foo => ++$i);

        $blackboard->remove("foo");

        ! $blackboard->has("foo") or die "foo should have been removed";

        $blackboard->put(foo => ++$i);
    }

    {
        my $i = 0;

        my $blackboard = Async::Blackboard->build(
            watchers => [
                foo => sub { shift eq $i or die "foo" },
            ],
        )->clone;

        # Make sure that we only dispatch one event.
        $blackboard->replace(foo => ++$i) for 1 .. 2;

        $blackboard->get("foo") eq 2
            or die "get results in changed value after replace";
    }

    {
        my $blackboard = Async::Blackboard->new;

        $blackboard->watch(foo => sub {
                my ($blackboard) = @_;

                $blackboard->put(bar => "Cause Failure");
            }
        );

        $blackboard->watch([qw( foo bar )] => sub { "Saw event for foo bar" });

        $blackboard->put(foo => $blackboard);

        $blackboard->clear;
        $blackboard->hangup;
    }

    {
        my $blackboard = Async::Blackboard->new();

        $blackboard->watch(foo => sub { $blackboard->hangup });
        $blackboard->watch(foo => sub { die "Expected hangup" });

        $blackboard->put(foo => 1);

        $blackboard->hungup or die "Blackboard was hung up";

        $blackboard->hangup;
    }

    {
        my $blackboard = Async::Blackboard->new();

        $blackboard->put(blackboard => $blackboard);
        $blackboard->weaken("blackboard");
    }
}

=item Watcher in loop

Run most of the tests from t/01_watcher.t in a loop (not using the actual test
harness, that proved too problematic) some 20 times and verify that the
resident footprint and number of tracked objects did not change.

=cut

subtest "Watcher in loop" => sub {
    no warnings "redefine";

    run_extensive_tests for 1 .. 10;

    # This will shut off some of the random output from Devel::Leak;
    close STDERR;

    my $handle;

    BSD::Resource::getrusage->maxrss;

    my $start_count = Devel::Leak::NoteSV($handle);
    my $resident = BSD::Resource::getrusage->maxrss;

    run_extensive_tests for 1 .. 20;

    my $end_count = Devel::Leak::CheckSV($handle);

    is $start_count, $end_count,
    "Object counts are the same";

    is BSD::Resource::getrusage->maxrss, $resident,
    "We don't seem to leak";
};

=back

=cut

done_testing;
