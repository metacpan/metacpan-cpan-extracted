#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use EV;
use AnyEvent::Blackboard;

no warnings "redefine";
{
    package okayer;
    use Test::More;

    sub new {
        my ($class, %expect) = @_;
        bless {%expect}, $class;
    }

    sub foo {
        my ($self, $arg) = @_;

        ok $self->{foo} eq $arg, "$self->{foo} eq $arg";
    }

    sub bar {
        my ($self, $arg) = @_;

        ok $self->{bar} eq $arg, "$self->{bar} eq $arg";
    }

    sub foobar {
        my ($self, $foo, $bar) = @_;

        ok $self->{foo} eq $foo &&
        $self->{bar} eq $bar, "both args match expect";
    }
}

isa_ok(AnyEvent::Blackboard->new(), "AnyEvent::Blackboard",
    "AnyEvent::Blackboard constructor");

=head1 TESTS

=over 4

=item Default Timeout

Time out all values by diving into the AnyEvent event loop without putting down
any events.

=cut

subtest "Default Timeout" => sub {
    my $blackboard = AnyEvent::Blackboard->new(default_timeout => 0.02);

    ok defined $blackboard, "Created blackboard...";

    my $condvar = AnyEvent->condvar;

    $condvar->begin;

    $blackboard->watch(foo => sub {
            my ($foo) = @_;

            ok !defined $foo, "foo should be undefined as default";

            $condvar->end;
        });

    note "Entering watch mode...";

    $condvar->recv;

    note "Got condvar interrupt...";

    ok $blackboard->has("foo"), "foo should exist";

    done_testing;
};

=item Timeout

Timeotu a specific key with a default value.

=cut

subtest "Timeout" => sub {
    plan tests => 2;

    my $blackboard = AnyEvent::Blackboard->new();

    my $condvar = AnyEvent->condvar;

    $condvar->begin;

    $blackboard->timeout(0.01, foo => "default");

    $blackboard->watch(foo => sub {
            my ($foo) = @_;

            ok $foo eq "default", "foo should be defined as default";

            $condvar->end;
        });

    $condvar->recv;

    ok $blackboard->has("foo"), "foo should be defined";
};

=item Timeout Canceled

Verify that timeouts result in no event when a value was provided, and that
it's the value that the is available not the undef provided by default by
timeouts.

=cut

subtest "Timeout Canceled" => sub {
    my $blackboard = AnyEvent::Blackboard->new();

    my $condvar = AnyEvent->condvar;

    $condvar->begin;

    $blackboard->timeout(0.01, foo => "default");

    $blackboard->watch(foo => sub {
            my ($foo) = @_;

            ok $foo eq "provided", "foo should be defined as provided";

            $condvar->end;
        });

    $blackboard->put(foo => "provided");

    $condvar->recv;

    ok $blackboard->has("foo"), "foo should be defined";

    done_testing;
};

=item Default timeout doesn't stringify arrayrefs.

Ensure ``default_timeout'' doesn't create a bug in ``watch'' where it adds a
watcher to an array refernece.

=cut

subtest "Default timeout doesn't stringify arrayrefs." => sub {
    my $blackboard = AnyEvent::Blackboard->new(
        default_timeout => 1
    );

    my $keys = [ sort qw( foo bar ) ];

    $blackboard->watch($keys, sub { fail });

    is_deeply [ sort $blackboard->watched ], $keys,
    "watched list contains the expected results";
};

=item Clone

Clone the blackboard and make sure it retains its default values.

=cut

subtest "Clone" => sub {
    my $blackboard = AnyEvent::Blackboard->new();

    $blackboard->put(key => "value");

    my $clone = $blackboard->clone;

    ok $blackboard->get("key") eq $clone->get("key"),
        "\$blackboard and \$clone shall both have \"key\"";

    done_testing;
};

=back

=cut

done_testing;
