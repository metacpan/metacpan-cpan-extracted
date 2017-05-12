#!/usr/bin/env perl

use strict;
use warnings FATAL => "all";
use Test::More;
use Benchmark qw( :all );
use Async::Blackboard;

=head1 TESTS

Collection of benchmark tests.

=over 4

=item Dispatch rate test.

A test which validates the rate of dispatch is greater than 30,000/s.  The goal
being to ensure that L<Async::Blackboard> is never particularly slow at
calculating constraints for dispatching or at cloning - cloning being
particularly important for most use cases.

=cut


my $blackboard = Async::Blackboard->build(
    watch => [ test => \&pass ]
);

sub rate {
    my ($benchmark) = @_;
    # This copies some funk from the Benchmark internals, which I should say
    # are not particularly legible.
    my ($r, $pu, $ps, $cu, $cs, $n) = @$benchmark;

    my $elapsed = $cu + $cs + $pu + $ps;

    return $n / $elapsed;
}

subtest "Dispatch rate test." => sub {
    my $benchmark = timeit 100_000, sub {
        $blackboard->clone->put(test => 1);
    };

    my $rate = rate($benchmark);

    ok $rate > 30000, "Rate of $rate is above 30,000/second";
};

=back

=cut

done_testing;
