#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Complete::Util qw(combine_answers);

test_combine(
    name   => 'empty',
    input  => [],
    result => undef,
);

test_combine(
    name   => 'arrays of scalars',
    input  => [[1, 2], [4, 2, 3]],
    result => [1, 2, 4, 3],
);

test_combine(
    name   => 'arrays of scalars+hashes',
    input  => [[1, 2], [4, 2, 3], [{word=>5, description=>"five"}], [5, 7]],
    result => [1, 2, 4, 3, {word=>5, description=>"five"}, 7],
);

test_combine(
    name   => 'arrays + hashes',
    input  => [
        [1, 2],
        {words=>[4, 2, 3], path_sep=>'::', esc_mode=>'none'},
        [{word=>5, description=>"five"}],
        {words=>[5, 7], path_sep=>'/'},
    ],
    result => {
        words => [1, 2, 4, 3, {word=>5, description=>"five"}, 7],
        path_sep => '/',
        esc_mode => 'none',
    },
);

subtest "hashes" => sub {
    test_combine(
        name   => 'static stays 1 if all answer have static=1',
        input  => [{static=>1, words=>[1,2]},
                   {static=>1, words=>[3]},
                   {static=>1, words=>[4,5]}],
        result => {static=>1, words=>[1,2,3,4,5]},
    );
    test_combine(
        name   => 'static becomes 0 if any answer has static=0',
        input  => [{static=>1, words=>[1,2]},
                   {static=>1, words=>[3]},
                   {static=>0, words=>[4,5]}],
        result => {static=>0, words=>[1,2,3,4,5]},
    );
};

subtest "final" => sub {
    test_combine(
        name   => 'one of the answers has final=1 -> combined answer is only that single answer',
        input  => [ [1,2,3], {final=>1, words=>[4,5]} ],
        result => {final=>1, words=>[4,5]},
    );
    test_combine(
        name   => 'one of the answers has final=1 -> combined answer is only that single answer (2)',
        input  => [ {final=>1, words=>[4,5]}, [1,2,3] ],
        result => {final=>1, words=>[4,5]},
    );
    test_combine(
        name   => 'one of the answers has final=1 -> combined answer is only that single answer (2)',
        input  => [ {final=>1, words=>[4,5]}, {final=>1, words=>[1,2,3]} ],
        result => {final=>1, words=>[4,5]},
    );
};

done_testing();

sub test_combine {
    my (%args) = @_;

    subtest $args{name} => sub {
        my $res = combine_answers(@{ $args{input} });
        is_deeply($res, $args{result}) or diag explain($res);
    };
}
