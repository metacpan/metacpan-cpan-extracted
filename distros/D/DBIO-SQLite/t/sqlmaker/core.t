use strict;
use warnings;

use Test::More;

use DBIO::SQLite::Test ':DiffSQL';

my $schema = DBIO::SQLite::Test->init_schema(no_deploy => 1);

my $sql_maker = $schema->storage->sql_maker;

{
  my ($sql, @bind) = $sql_maker->insert(
            'lottery',
            {
              'day' => '2008-11-16',
              'numbers' => [13, 21, 34, 55, 89]
            }
  );

  is_same_sql_bind(
    $sql, \@bind,
    q/INSERT INTO "lottery" ("day", "numbers") VALUES (?, ?)/,
      [ ['day' => '2008-11-16'], ['numbers' => [13, 21, 34, 55, 89]] ],
    'sql_maker passes arrayrefs in insert'
  );
}

done_testing;
