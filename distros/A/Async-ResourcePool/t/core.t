#!/usr/bin/env perl

use strict;
use warnings FATAL => "all";
use Test::More;
use Async::ResourcePool;

=head1 TESTS

=over 4

=item 

=cut

use_ok("Async::ResourcePool", "Able to include module");

package Resource {
    our $instances = 0;
    use Test::More;

    sub new {
        my ($class, %args) = @_;

        $instances++;

        return bless { %args, closed => 0, events => [] }, $class;
    }

    sub make_use_of {
        my ($self) = @_;

        push $self->{events}, "make_use_of";

        fail "We're not supposed to be alive" if $self->{closed};
    }

    sub release {
        my ($self) = @_;

        pass "released";
        push $self->{events}, "release";

        local $, = "\n";

# this doesn't matter because these things will be ignored.
# It may occasionally happen since release() re-enters the dispatching of
# 
# Async::ResourcePool and if something is released and closed in rapid
# succession, by more than one task, the result will be two calls to ->close()
# one right before a call to ->release().
#
# This race condition should be allowed so long as the resource is still valid,
# but Async::ResourcePool may never dispatch it (there's a test below for
# that).
#
        die "We're not supposed to be alive in release:\n@{$self->{events}}"
        if $self->{closed};

        $self->{pool}->release($self);
    }

    sub close {
        my ($self) = @_;

        pass "closed";
        push $self->{events}, "close";

        $instances--;

        $self->{closed} = 1;

        $self->{pool}->invalidate($self);
    }
}

our @queue;

sub postpone (&) {
    splice @queue, rand(@queue), 0, shift;
}

sub run () {
    while (@queue) {
        (shift @queue)->();
    }
}

subtest "Simple Resource Management" => sub {
    plan tests => 303;

    my $pool;
    my $limit = 4;

    unless (defined $pool) {
        $pool = Async::ResourcePool->new(
            limit   => $limit,
            factory => sub {
                my ($pool, $available) = @_;

                postpone {
                    if (rand > 0.10) {
                        my $resource = Resource->new(pool => $pool);

                        $available->($resource);
                    }
                    else {
                        $available->(undef, "Crap we broke");
                    }
                };
            }
        );
    }

    my %active = ();

    # Then this is in place of ->run_when_ready...
    $pool->lease(sub {
            my ($resource, $message) = @_;

            if (defined $resource) {
                die "Duplicate lease on resource"
                if exists $active{$resource};

                die "Resource was closed"
                if $resource->{closed};

                $active{$resource} = $resource;

                $resource->make_use_of;

                ok $Resource::instances <= $limit,
                "Allocated ($resource), currently $Resource::instances";

                # Do this later...
                postpone {
                    delete $active{$resource}
                        or die "Expected resource to be tracked here";

                    if (rand() <= 0.2) {
                        # The other thing which saw the release might have
                        # closed us too...this appears to be a problem mainly
                        # with simulation.
                        $resource->close;
                    }
                    else {
                        $resource->release;
                    }
                };
            }
            else {
                ok defined $message, "The error passing is working";
                pass "Don't retry";
            }
        })
    for 1 .. 150;

    run;

    ok $pool->has_available, "Probabalistically some should be available";
    ok !$pool->has_waiters, "Expected no waiters to remain";
    ok $pool->size <= $pool->limit, "The size may not exceed the limit";
};

done_testing;
