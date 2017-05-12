use strict;
use warnings;
use Test::More;

use Data::WeightedRoundRobin;

subtest 'emply' => sub {
    my $dwr = Data::WeightedRoundRobin->new;
    ok !$dwr->remove(), 'replace';
    is_deeply $dwr->{rrlist}, [], 'rrlist';
    is $dwr->{weights}, 0, 'weights';
};

subtest 'not found' => sub {
    my $dwr = Data::WeightedRoundRobin->new;
    ok !$dwr->remove('foo'), 'remove';
    is_deeply $dwr->{rrlist}, [], 'rrlist';
    is $dwr->{weights}, 0, 'weights';
};

subtest 'removed foo' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo/]);
    ok $dwr->remove('foo'), 'remove';
    is_deeply $dwr->{rrlist}, [], 'rrlist';
    is $dwr->{weights}, 0, 'weights';
};

done_testing;
