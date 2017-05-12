use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh );

my $dump = $sc->_schemadump;
like( $dump, qr/first_table/,                   'found table' );
like( $dump, qr/columns/,                       'found columns' );
like( $dump, qr/column_name.*?id/i,             'found column id' );
like( $dump, qr/column_name.*?a_column/i,       'found column a_column' );
like( $dump, qr/column_name.*?another_column/i, 'found column another_column' );

done_testing();

