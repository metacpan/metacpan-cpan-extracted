use strict;
use warnings;
use Test::More;

use Data::WeightedRoundRobin;

subtest 'emply' => sub {
    my $dwr = Data::WeightedRoundRobin->new;
    ok !$dwr->add(), 'add';
    is_deeply $dwr->{rrlist}, [], 'rrlist';
    is $dwr->{weights}, 0, 'weights';
};

subtest 'add foo' => sub {
    my $dwr = Data::WeightedRoundRobin->new;
    ok $dwr->add('foo'), 'add';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => 'foo', weight => 100, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 100, 'weights';
};

subtest 'add foo with weight' => sub {
    my $dwr = Data::WeightedRoundRobin->new;
    ok $dwr->add({ value => 'foo', weight => 10 }), 'add';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => 'foo', weight => 10, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 10, 'weights';
};

subtest 'confrict' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo/]);
    ok !$dwr->add({ value => 'foo', weight => 10 }), 'add';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => 'foo', weight => 100, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 100, 'weights';
};

done_testing;
