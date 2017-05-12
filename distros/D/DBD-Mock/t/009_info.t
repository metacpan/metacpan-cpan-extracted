use strict;

use Test::More tests => 3;

BEGIN {
    use_ok('DBI');
}

my $dbh = DBI->connect( 'dbi:Mock:', '', '' );
isa_ok($dbh, 'DBI::db');

$dbh->{mock_get_info} = { foo => 4 };
is( $dbh->get_info( 'foo' ), '4', "Retrieved info successfully" );
