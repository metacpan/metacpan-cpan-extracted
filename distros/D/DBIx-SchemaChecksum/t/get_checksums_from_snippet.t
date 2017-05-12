use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh );

my ($pre,$post) = $sc->get_checksums_from_snippet( 't/dbs/snippets/first_change.sql');
is($pre,'660d1e9b6aec2ac84c2ff6b1acb5fe3450fdd013','preSHA1sum');
is($post,'e63a31c18566148984a317006dad897b75d8bdbe','postSHA1sum');

done_testing();
