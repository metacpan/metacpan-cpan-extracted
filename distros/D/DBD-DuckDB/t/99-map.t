#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

my @TESTS = (
    ["SELECT MAP {'key1': 10, 'key2': 20, 'key3': 30} AS m",                     {key1 => 10, key2 => 20, key3 => 30}],
    ["SELECT map_from_entries([('key1', 10), ('key2', 20), ('key3', 30)]) AS m", {key1 => 10, key2 => 20, key3 => 30}],
    ["SELECT MAP(['key1', 'key2', 'key3'], [10, 20, 30]) AS m",                  {key1 => 10, key2 => 20, key3 => 30}],
    ["SELECT MAP {1: 42.001, 5: -32.1} AS m",                                    {1    => '42.001', 5 => '-32.100'}],

    # Map cast (/test/sql/types/map/map_cast.test)
    ["SELECT MAP(['a', 'b', 'c'], [1, 2, NULL])::MAP(VARCHAR, VARCHAR) AS m", {a => '1', b => '2', c => undef}],
    ["SELECT MAP(['a', 'b', 'c'], [1, 2, NULL])::MAP(VARCHAR, BIGINT) AS m",  {a => 1,   b => 2,   c => undef}],
    ["SELECT MAP([1, 2, 3], [1, 2, NULL])::MAP(VARCHAR, BIGINT) AS m",        {1 => 1,   2 => 2,   3 => undef}],
    ["SELECT MAP([1, 2, 3], ['A', 'B', 'C'])::MAP(TINYINT, VARCHAR) AS m",    {1 => 'A', 2 => 'B', 3 => 'C'}],

    # Map NULL (/test/sql/types/map/map_null.test)
    ["select map(NULL::INT[], [1,2,3]) AS m", undef], ["select map(NULL, [1,2,3]) AS m",         undef],
    ["select map(NULL, NULL) AS m",           undef], ["select map(NULL, [1,2,3]) IS NULL AS m", !!1],
    ["select map([1,2,3], NULL) AS m",        undef], ["select map([1,2,3], NULL::INT[]) AS m",  undef],
);

for my $test (@TESTS) {
    my ($sql, $expected) = @$test;

    my $row = $dbh->selectrow_hashref($sql);

    diag $sql;
    diag explain $row;

    if (!defined $expected) {
        is $row->{m}, undef, 'map is NULL';
    }
    elsif (ref($expected) eq 'HASH') {
        is ref($row->{m}), 'HASH', 'map is a hashref';
        is_deeply $row->{m}, $expected, 'map matches expected';
    }
    else {
        is_deeply $row, {m => $expected}, 'map matches expected';
    }
}

done_testing;
