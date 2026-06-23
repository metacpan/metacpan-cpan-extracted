use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

my $new_artist = $schema->resultset('Artist')->create({ name => 'new kid behind the block' });

# see how many cds do we have, and relink them all to the new guy
my $cds = $schema->resultset('CD');
my $cds_count = $cds->count;
cmp_ok($cds_count, '>', 0, 'have some cds');

$cds->update_all({ artist => $new_artist });

is( $new_artist->cds->count, $cds_count, 'All cds properly relinked');

done_testing;
