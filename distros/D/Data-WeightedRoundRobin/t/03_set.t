use strict;
use warnings;
use Test::More;

use Data::WeightedRoundRobin;

subtest 'emply' => sub {
    my $dwr = Data::WeightedRoundRobin->new;
    ok !$dwr->set(), 'set';
    is_deeply $dwr->{rrlist}, [], 'rrlist';
    is $dwr->{weights}, 0, 'weights';
};

subtest 'set qw/foo bar/' => sub {
    my $dwr = Data::WeightedRoundRobin->new;
    ok $dwr->set([qw/foo bar/]), 'set';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => 'foo', weight => 100, range => 100 },
        { key => 'bar', value => 'bar', weight => 100, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 200, 'weights';
};

subtest 'over write' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
    ok $dwr->set([
        { value => 'hoge', weight => 50 },
        { value => 'fuga', weight => 100 },
    ]), 'set';
    is_deeply $dwr->{rrlist}, [
        { key => 'hoge', value => 'hoge', weight => 50, range => 100 },
        { key => 'fuga', value => 'fuga', weight => 100, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 150, 'weights';
};

done_testing;
