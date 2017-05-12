#!/usr/bin/env perl

use Test::More;
use common::sense;
use Async::ResourcePool;

=head1 TESTS

=over 4

=cut

=item Invalidated resources are not dispatched

Description

=cut

package Resource {
    sub new {
        bless {}, shift;
    }

    sub close {
        shift->{closed} = 1
    }

    sub is_closed {
        shift->{closed} == 1
    }
}

subtest "Invalidated resources are not dispatched" => sub {
    my $pool = Async::ResourcePool->new(
        limit => 1,
        factory => sub {
            my ($pool, $available) = @_;

            $available->(Resource->new);
        }
    );

    our $invalidated;

    $pool->lease(
        sub {
            ($invalidated) = @_;

            # First release the resource...
            $pool->release($invalidated);
        }
    );

    # Then invalidate it.  It's now on the available queue.
    $pool->invalidate($invalidated);

    # Ensure we don't get it.
    $pool->lease(
        sub {
            my ($resource) = @_;

            ok $resource != $invalidated,
            "The given resource is not the one we invalidated."
        }
    );
};

done_testing;
