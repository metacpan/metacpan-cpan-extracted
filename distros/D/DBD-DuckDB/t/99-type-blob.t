#perl -T

use strict;
use warnings;

use Test::More;
use Time::Piece;

use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

my @TESTS = (
    [q{SELECT '\xAA'::BLOB},         "\xAA"],
    [q{SELECT '\xAA\xAB\xAC'::BLOB}, "\xAA\xAB\xAC"],
    [q{SELECT 'AB'::BLOB},           'AB'],
    [q{SELECT ''::BLOB},             ''],
);

foreach my $test (@TESTS) {
    is $dbh->selectrow_arrayref($test->[0])->[0], $test->[1], $test->[0];
}

done_testing;
