use strict;
use warnings;

use Test::More;
use Test::Warn;
use Test::Exception;
use DBIO::SQLite::Test;
{
  package DBIO::Test::Legacy::Storage;
  use base 'DBIO::SQLite::Storage';

  use Data::Dumper::Concise;

  sub source_bind_attributes { return {} }
}


my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('DBIO::Test::Legacy::Storage');
$schema->connection('dbi:SQLite::memory:');

lives_ok
  { $schema->storage->ensure_connected }
  'legacy source_bind_attributes no longer throws',
;

done_testing;
