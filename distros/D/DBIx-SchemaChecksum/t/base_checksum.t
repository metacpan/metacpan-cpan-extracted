use strict;
use warnings;
use Test::Most;
use lib qw(t);
use MakeTmpDb;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh );

my $checksum = $sc->checksum;

is( $checksum, 'ee3a4db19fc06296306738ee6d4cdfd1204adf8c', 'base checksum' );

done_testing();

