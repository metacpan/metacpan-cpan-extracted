use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema(cursor_class => 'DBIO::Test::Cursor');

lives_ok {
  is($schema->resultset("Artist")->search(), 3, "Three artists returned");
} 'Custom cursor autoloaded';

SKIP: {
  eval { require Class::Unload }
    or skip 'component_class reentrancy test requires Class::Unload', 1;

  Class::Unload->unload('DBIO::Test::Cursor');

  lives_ok {
    is($schema->resultset("Artist")->search(), 3, "Three artists still returned");
  } 'Custom cursor auto re-loaded';
}

done_testing;
