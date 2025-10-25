#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

my @TESTS = (
    ['SELECT typeof(1)',                                 'INTEGER'],
    ['SELECT typeof(TRUE)',                              'BOOLEAN'],
    ['SELECT typeof(FALSE)',                             'BOOLEAN'],
    ['SELECT typeof(NULL)',                              '"NULL"'],
    ["SELECT typeof($])",                                'DECIMAL(7,6)'],
    ["SELECT typeof('JAPH')",                            'VARCHAR'],
    [q{SELECT typeof('\xAA'::BLOB)},                     'BLOB'],
    [q{SELECT typeof('2025-01-01'::DATE)},               'DATE'],
    [q{SELECT typeof('13:37:00'::TIME)},                 'TIME'],
    [q{SELECT typeof('2025-01-01 13:37:00'::TIMESTAMP)}, 'TIMESTAMP'],
    [q{SELECT typeof([1,2,3])},                          'INTEGER[]'],
    ["SELECT typeof(MAP {'key':'value'})",               'MAP(VARCHAR, VARCHAR)'],
    ["SELECT typeof(MAP {'key':123})",                   'MAP(VARCHAR, INTEGER)'],
);

foreach my $test (@TESTS) {
    is $dbh->selectrow_arrayref($test->[0])->[0], $test->[1], sprintf('%s == %s', $test->[0], $test->[1]);
}

done_testing;
