use strict;
use warnings;
use Test::Most;
use lib qw(t);
use MakeTmpDb;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh );

my $checksum = $sc->checksum;

is( $checksum, '660d1e9b6aec2ac84c2ff6b1acb5fe3450fdd013', 'base checksum' );

done_testing();

