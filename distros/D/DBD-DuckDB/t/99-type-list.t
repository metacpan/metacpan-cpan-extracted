#perl -T

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

my @TESTS = (
    ["SELECT [1, 2, 3]", [1, 2, 3]],
    ["SELECT ['duck', 'goose', NULL, 'heron']", ['duck', 'goose', undef, 'heron']],
    [
        "SELECT [['duck', 'goose', 'heron'], NULL, ['frog', 'toad'], []]",
        [['duck', 'goose', 'heron'], undef, ['frog', 'toad'], []]
    ],
    ["SELECT list_value(1, 2, 3)", [1, 2, 3]],

    ["SELECT ['a', 'b', 'c'][3]",                 'c'],
    ["SELECT ['a', 'b', 'c'][-1]",                'c'],
    ["SELECT ['a', 'b', 'c'][2 + 1]",             'c'],
    ["SELECT list_extract(['a', 'b', 'c'], 3)",   'c'],
    ["SELECT ['a', 'b', 'c'][1:2]",               ['a', 'b']],
    ["SELECT ['a', 'b', 'c'][:2]",                ['a', 'b']],
    ["SELECT ['a', 'b', 'c'][-2:]",               ['b', 'c']],
    ["SELECT list_slice(['a', 'b', 'c'], 2, 3)",  ['b', 'c']],
    ["SELECT [1, 2] < [1, 3] AS result",          !!1],
    ["SELECT [[1], [2, 4, 5]] < [[2]] AS result", !!1],
    ["SELECT [ ] < [ ] AS result",                !!0],
    ["SELECT [1, 2] < [1] AS result",             !!0],
    ["SELECT [1, 2] < [1, NULL, 4] AS result",    !!1],
);

foreach my $test (@TESTS) {
    my $desc     = $test->[0];
    my $got      = $dbh->selectrow_arrayref($test->[0]);
    my $expected = $test->[1];
    is_deeply $got->[0], $expected, $desc;
}

done_testing;
