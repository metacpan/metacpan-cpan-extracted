use strict;
use Test::More 0.98;

use DBI;

my $dbh = DBI->connect('dbi:BlackHole:', undef, undef);

is $dbh->quote('foo'), q!'foo'!;
is $dbh->quote_identifier('foo'), q!`foo`!;

done_testing;

