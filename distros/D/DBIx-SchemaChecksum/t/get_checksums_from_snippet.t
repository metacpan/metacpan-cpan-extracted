use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh );

my ($pre,$post) = $sc->get_checksums_from_snippet( 't/dbs/snippets/first_change.sql');
is($pre,'ee3a4db19fc06296306738ee6d4cdfd1204adf8c','preSHA1sum');
is($post,'8f6643a8fc8b4e47caa30c70da5635f366075ea1','postSHA1sum');

done_testing();
