#perl -T

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

my @TESTS = (
    ["SELECT DATE '1992-09-20'", [['1992-09-20']]],

    ["SELECT DATE '1992-03-22' + 5",              [['1992-03-27']]],
    ["SELECT DATE '1992-03-22' + INTERVAL 5 DAY", [['1992-03-27 00:00:00']]],
    [
        "SELECT DATE '1992-03-22' + INTERVAL (d.days) DAY FROM (VALUES (5), (11)) d(days)",
        [['1992-03-27 00:00:00'], ['1992-04-02 00:00:00']]
    ],

    ["SELECT DATE '1992-03-27' - DATE '1992-03-22'", [[5]]],
    ["SELECT DATE '1992-03-27' - INTERVAL 5 DAY",    [['1992-03-22 00:00:00']]],
    [
        "SELECT DATE '1992-03-27' - INTERVAL (d.days) DAY FROM (VALUES (5), (11)) d(days)",
        [['1992-03-22 00:00:00'], ['1992-03-16 00:00:00']]
    ],

    ["SELECT '-infinity'::DATE", [['-5877641-06-24']]],
    ["SELECT 'epoch'::DATE",     [['1970-01-01']]],
    ["SELECT 'infinity'::DATE",  [['5881580-07-11']]],
);

foreach my $test (@TESTS) {
    my $desc     = $test->[0];
    my $got      = $dbh->selectall_arrayref($test->[0]);
    my $expected = $test->[1];
    is_deeply $got, $expected, $desc;
}


done_testing;
