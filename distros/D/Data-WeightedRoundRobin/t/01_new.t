use strict;
use warnings;
use Test::More;

use Data::WeightedRoundRobin;

subtest 'empty' => sub {
    my $dwr = Data::WeightedRoundRobin->new;
    isa_ok $dwr, 'Data::WeightedRoundRobin';
    is_deeply $dwr->{rrlist}, [], 'rrlist';
    is $dwr->{weights}, 0, 'weights';
    is $dwr->{default_weight}, 100, 'default_weight';
};

subtest 'basic' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
    isa_ok $dwr, 'Data::WeightedRoundRobin';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => 'foo', weight => 100, range => 100 },
        { key => 'bar', value => 'bar', weight => 100, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 200, 'weights';
    is $dwr->{default_weight}, 100, 'default_weight';
};

subtest 'with weight' => sub {
    my $dwr = Data::WeightedRoundRobin->new([
        { value => 'foo', weight => 50 },
        { value => 'bar', weight => 100 },
    ]);
    isa_ok $dwr, 'Data::WeightedRoundRobin';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => 'foo', weight => 50, range => 100 },
        { key => 'bar', value => 'bar', weight => 100, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 150, 'weights';
    is $dwr->{default_weight}, 100, 'default_weight';
};

subtest 'multi' => sub {
    my $dwr = Data::WeightedRoundRobin->new([
        { value => 'foo', weight => 50 },
        qw/bar baz/,
    ]);
    isa_ok $dwr, 'Data::WeightedRoundRobin';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => 'foo', weight => 50, range => 200 },
        { key => 'baz', value => 'baz', weight => 100, range => 100 },
        { key => 'bar', value => 'bar', weight => 100, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 250, 'weights';
    is $dwr->{default_weight}, 100, 'default_weight';
};

subtest 'default_weight' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/], { default_weight => 20 });
    isa_ok $dwr, 'Data::WeightedRoundRobin';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => 'foo', weight => 20, range => 20 },
        { key => 'bar', value => 'bar', weight => 20, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 40, 'weights';
    is $dwr->{default_weight}, 20, 'default_weight';
};

subtest '$DEFAULT_WEIGHT' => sub {
    local $Data::WeightedRoundRobin::DEFAULT_WEIGHT = 20;
    my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
    isa_ok $dwr, 'Data::WeightedRoundRobin';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => 'foo', weight => 20, range => 20 },
        { key => 'bar', value => 'bar', weight => 20, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 40, 'weights';
    is $dwr->{default_weight}, 20, 'default_weight';
};

subtest 'referenced value' => sub {
    my $dwr = Data::WeightedRoundRobin->new([
        { key => 'foo', value => [qw/f o o/] },
    ]);
    isa_ok $dwr, 'Data::WeightedRoundRobin';
    is_deeply $dwr->{rrlist}, [
        { key => 'foo', value => [qw/f o o/], weight => 100, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 100, 'weights';
    is $dwr->{default_weight}, 100, 'default_weight';
};

subtest 'HASHREF-REF' => sub {
    my $data = { foo => 'bar' };
    my $dwr = Data::WeightedRoundRobin->new([\$data]);
    isa_ok $dwr, 'Data::WeightedRoundRobin';
    is_deeply $dwr->{rrlist}, [
        { key => "$data", value => $data, weight => 100, range => 0 },
    ], 'rrlist';
    is $dwr->{weights}, 100, 'weights';
    is $dwr->{default_weight}, 100, 'default_weight';
};

done_testing;
