use strict;
use warnings;
use Test::More;

use Data::WeightedRoundRobin;

subtest 'emply' => sub {
    my $dwr = Data::WeightedRoundRobin->new;
    ok !$dwr->replace(), 'replace';
    is_deeply $dwr->{rrlist}, [], 'rrlist';
    is $dwr->{weights}, 0, 'weights';
};

subtest 'not found' => sub {
    my $dwr = Data::WeightedRoundRobin->new;
    ok !$dwr->replace('foo'), 'replace';
    is_deeply $dwr->{rrlist}, [], 'rrlist';
    is $dwr->{weights}, 0, 'weights';
};

subtest 'replaced foo' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo/]);
    ok $dwr->replace('foo'), 'replace';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => 'foo', weight => 100, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 100, 'weights';
};

subtest 'replaced foo with weight' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo/]);
    ok $dwr->replace({ value => 'foo', weight => 50 }), 'replace';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => 'foo', weight => 50, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 50, 'weights';
};

subtest 'referenced data' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo/]);
    ok $dwr->replace({ key => 'foo', value => [qw/f o o/], weight => 50 }), 'replace';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => [qw/f o o/], weight => 50, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 50, 'weights';
};

done_testing;
