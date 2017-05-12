#!/usr/bin/env perl

use Test::More;
use common::sense;
use Async::ResourcePool;

=head1 TESTS

=over 4

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

=item Resources cannot be released twice.

The same resource may not be released twice.

=cut

subtest "Resources cannot be released twice." => sub {
    my $pool = Async::ResourcePool->new(
        limit   => 1,
        factory => sub {
            my ($pool, $available) = @_;

            $available->(Resource->new);
        },
    );

    $pool->lease(
        sub {
            my ($resource, $message) = @_;

            $pool->release($resource);

            eval {
                $pool->release($resource);
            };

            ok $@, "Expected exception from duplicate release";
        }
    );

    $pool->lease(sub { pass "We get the resource once" });
    $pool->lease(sub { fail "We get the resource twice" });
};

done_testing;
