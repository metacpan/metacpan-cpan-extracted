use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# Mock count results
$schema->storage->mock_persistent(qr/SELECT COUNT/i, [[3]]);

# test LIMIT
my $it = $schema->resultset("CD")->search( {},
    { rows => 3,
      order_by => 'title' }
);
is( $it->count, 3, "count ok" );

# Mock rows for ->next iteration
$schema->storage->mock(qr/SELECT.*FROM cd/i, [
  [3, 1, "Caterwaulin' Blues", 1997, undef, undef],
  [5, 3, "Come Be Depressed With Us", 1998, undef, undef],
  [2, 1, "Forkful of bees", 2001, undef, undef],
]);
is( $it->next->title, "Caterwaulin' Blues", "iterator->next ok" );
$it->next;
$it->next;
is( $it->next, undef, "next past end of resultset ok" );

# test OFFSET
$schema->storage->mock(qr/SELECT.*FROM cd/i, [
  [1, 1, "Spoonful of bees", 1999, 1, undef],
  [5, 3, "Come Be Depressed With Us", 1998, undef, undef],
]);
my @cds = $schema->resultset("CD")->search( {},
    { rows => 2,
      offset => 2,
      order_by => 'year' }
);
is( $cds[0]->title, "Spoonful of bees", "offset ok" );

# test software-based limiting
$schema->storage->clear_mocks;
$schema->storage->mock_persistent(qr/SELECT COUNT/i, [[3]]);
$it = $schema->resultset("CD")->search( {},
    { rows => 3,
      software_limit => 1,
      order_by => 'title' }
);
is( $it->count, 3, "software limit count ok" );

$schema->storage->mock(qr/SELECT.*FROM cd/i, [
  [3, 1, "Caterwaulin' Blues", 1997, undef, undef],
  [5, 3, "Come Be Depressed With Us", 1998, undef, undef],
  [2, 1, "Forkful of bees", 2001, undef, undef],
]);
is( $it->next->title, "Caterwaulin' Blues", "software iterator->next ok" );
$it->next;
$it->next;
is( $it->next, undef, "software next past end of resultset ok" );

$schema->storage->mock(qr/SELECT.*FROM cd/i, [
  [1, 1, "Spoonful of bees", 1999, 1, undef],
  [5, 3, "Come Be Depressed With Us", 1998, undef, undef],
]);
@cds = $schema->resultset("CD")->search( {},
    { rows => 2,
      offset => 2,
      software_limit => 1,
      order_by => 'year' }
);
is( $cds[0]->title, "Spoonful of bees", "software offset ok" );

throws_ok {
  $schema->resultset("CD")->search({}, {
    rows => 2,
    software_limit => 1,
  })->as_query;
} qr/Unable to generate limited query representation with 'software_limit' enabled/;

$schema->storage->mock(qr/SELECT.*FROM cd/i, [
  [1, 1, "Spoonful of bees", 1999, 1, undef],
  [5, 3, "Come Be Depressed With Us", 1998, undef, undef],
  [4, 2, "Generic Manufactured Singles", 2001, undef, undef],
]);
@cds = $schema->resultset("CD")->search( {},
    {
      offset => 2,
      order_by => 'year' }
);
is( $cds[0]->title, "Spoonful of bees", "offset with no limit" );

$schema->storage->clear_mocks;
$schema->storage->mock(qr/SELECT COUNT/i, [[1]]);
$it = $schema->resultset("CD")->search(
    { title => [
        -and =>
            {
                -like => '%bees'
            },
            {
                -not_like => 'Forkful%'
            }
        ]
    },
    { rows => 5 }
);
is( $it->count, 1, "complex abstract count ok" );

done_testing;
