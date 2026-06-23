use strict;
use warnings;

use Test::More;
use Test::Warn;
use DBIO::Test;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# Mock find for CD id 1 - persistent so update's internal check also works
$schema->storage->mock_persistent(qr/SELECT me\.cdid.*FROM cd me/i, [[1, 1, 'Spoonful of bees', 1999, 1, undef]]);

my $cd = $schema->resultset("CD")->find(1);
$cd->title('test');

$schema->is_executed_querycount( sub {
  $cd->update;
}, {
  BEGIN => 1,
  UPDATE => 1,
  COMMIT => 1,
}, 'liner_notes (might_have) not prefetched - do not load liner_notes on update' );

$schema->storage->clear_mocks;

# Mock find for CD id 2 with prefetch of liner_notes
$schema->storage->mock_persistent(qr/SELECT me\.cdid.*liner_notes/i, [[2, 1, 'Forkful of bees', 2001, undef, undef, 2, 'Buy Whiskey!']]);
# Also mock plain CD select for update's needs
$schema->storage->mock_persistent(qr/SELECT me\.cdid.*FROM cd me/i, [[2, 1, 'Forkful of bees', 2001, undef, undef]]);

my $cd2 = $schema->resultset("CD")->find(2, {prefetch => 'liner_notes'});
$cd2->title('test2');

$schema->is_executed_querycount( sub {
  $cd2->update;
}, {
  BEGIN => 1,
  UPDATE => 1,
  COMMIT => 1,
}, 'liner_notes (might_have) prefetched - do not load liner_notes on update');

warning_like {
  local $ENV{DBIO_DONT_VALIDATE_RELS};

  DBIO::Test::Schema::Bookmark->might_have(
    linky => 'DBIO::Test::Schema::Link',
    { "foreign.id" => "self.link" },
  );
}
  qr{"might_have/has_one" must not be on columns with is_nullable set to true},
  'might_have should warn if the self.id column is nullable';

{
  local $ENV{DBIO_DONT_VALIDATE_RELS} = 1;
  warning_is {
    DBIO::Test::Schema::Bookmark->might_have(
      slinky => 'DBIO::Test::Schema::Link',
      { "foreign.id" => "self.link" },
    );
  }
  undef,
  'Setting DBIO_DONT_VALIDATE_RELS suppresses nullable relation warnings';
}

done_testing();
