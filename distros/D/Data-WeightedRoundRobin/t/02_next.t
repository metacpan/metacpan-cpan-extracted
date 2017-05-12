use strict;
use warnings;
use Test::More;

our $RAND = sub { 0 };

BEGIN {
    *CORE::GLOBAL::rand = sub { $RAND->() };
}

use Data::WeightedRoundRobin;

my $looped;
RERUN:

subtest 'empty' => sub {
    my $dwr = Data::WeightedRoundRobin->new;
    is $dwr->next, undef, 'next ok' for 1..3;
};

subtest 'a value' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo/]);
    is $dwr->next, 'foo', 'next ok' for 1..3;
};

subtest 'foo: 100, bar: 100' => sub {
    my $dwr = Data::WeightedRoundRobin->new([qw/foo bar/]);
    my $rands = [0, 100, 10, 200];
    local $RAND = sub { shift @$rands };

    is $dwr->next, 'bar', 'rand 0';
    is $dwr->next, 'foo', 'rand 100';
    is $dwr->next, 'bar', 'rand 10';
    is $dwr->next, 'foo', 'rand 200';
};

subtest 'foo: 50, bar: 100' => sub {
    my $dwr = Data::WeightedRoundRobin->new([
        { value => 'foo', weight => 50 },
        { value => 'bar', weight => 100 },
    ]);
    my $rands = [0, 100, 99, 150];
    local $RAND = sub { shift @$rands };

    is $dwr->next, 'bar', 'rand 0';
    is $dwr->next, 'foo', 'rand 100';
    is $dwr->next, 'bar', 'rand 99';
    is $dwr->next, 'foo', 'rand 150';
};

subtest 'foo: 50, bar: 100, baz: 20' => sub {
    my $dwr = Data::WeightedRoundRobin->new([
        { value => 'foo', weight => 50 },
        { value => 'bar', weight => 100 },
        { value => 'baz', weight => 20 },
    ]);
    my $rands = [0, 100, 99, 150, 110, 120];
    local $RAND = sub { shift @$rands };

    is $dwr->next, 'bar', 'rand 0';
    is $dwr->next, 'baz', 'rand 100';
    is $dwr->next, 'bar', 'rand 99';
    is $dwr->next, 'foo', 'rand 150';
    is $dwr->next, 'baz', 'rand 110';
    is $dwr->next, 'foo', 'rand 120';
};

subtest 'with refarenced data' => sub {
    my $dwr = Data::WeightedRoundRobin->new([
        { key => 'foo', value => [qw/f o o/], weight => 50 },
        { value => 'bar', weight => 100 },
        { value => 'baz', weight => 20 },
    ]);
    my $rands = [0, 100, 99, 150, 110, 120];
    local $RAND = sub { shift @$rands };

    is $dwr->next, 'bar', 'rand 0';
    is $dwr->next, 'baz', 'rand 100';
    is $dwr->next, 'bar', 'rand 99';
    is_deeply $dwr->next, [qw/f o o/], 'rand 150';
    is $dwr->next, 'baz', 'rand 110';
    is_deeply $dwr->next, [qw/f o o/], 'rand 120';
};

subtest 'support 0' => sub {
    my $dwr = Data::WeightedRoundRobin->new([
        { value => 'foo', weight => 0 },
        { value => 'bar', weight => 0 },
    ]);
    my $rands = [0, 1, 0, 1, 0, 1];
    local $RAND = sub { shift @$rands };
    is $dwr->next, 'foo', 'rand 0';
    is $dwr->next, 'bar', 'rand 1';
    is $dwr->next, 'foo', 'rand 0';
    is $dwr->next, 'bar', 'rand 1';
    is $dwr->next, 'foo', 'rand 0';
    is $dwr->next, 'bar', 'rand 1';
};

unless ($looped++) {
    local $Data::WeightedRoundRobin::BTREE_BORDER = 0;
    goto RERUN;
}

done_testing;
