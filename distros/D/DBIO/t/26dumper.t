use strict;
use warnings;
use Test::More;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use DBIO::Test;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# Mock: the joined query for CD + artist + liner_notes with the specific
# conditions matches exactly one row (CD #5: "Come Be Depressed With Us")
$schema->storage->mock_persistent(qr/SELECT COUNT/i, [[1]]);

my $rs = $schema->resultset('CD')->search({
  'artist.name' => 'We Are Goth',
  'liner_notes.notes' => 'Kill Yourself!',
}, {
  join => [ qw/artist liner_notes/ ],
});

Dumper($rs);

$rs = $schema->resultset('CD')->search({
  'artist.name' => 'We Are Goth',
  'liner_notes.notes' => 'Kill Yourself!',
}, {
  join => [ qw/artist liner_notes/ ],
});

cmp_ok( $rs->count(), '==', 1, "Single record in after death with dumper");

done_testing;
