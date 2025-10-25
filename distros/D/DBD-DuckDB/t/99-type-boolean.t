#perl -T

use strict;
use warnings;

use Test::More;
use Time::Piece;

use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

my $row = $dbh->selectrow_arrayref('SELECT true, false, NULL::BOOLEAN');

is $row->[0], !!1,   'True';
is $row->[1], !!0,   'False';
is $row->[2], undef, 'NULL';

done_testing;
