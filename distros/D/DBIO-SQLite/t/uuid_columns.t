use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;
eval { require Data::UUID }
  || eval { require UUID }
  || eval { require UUID::Random };

plan skip_all => 'No UUID module available (Data::UUID, UUID, or UUID::Random)'
  unless $INC{'Data/UUID.pm'} || $INC{'UUID.pm'} || $INC{'UUID/Random.pm'};

my $schema = DBIO::SQLite::Test->init_schema();

# Create a simple in-memory table for UUID testing
$schema->storage->dbh_do(sub {
  $_[1]->do(q{
    CREATE TABLE uuid_test (
      id VARCHAR(36) NOT NULL PRIMARY KEY,
      name VARCHAR(100)
    )
  });
});

# Define a quick result class
{
  package DBIO::Test::Schema::UUIDTest;
  use base 'DBIO::Test::BaseResult';
  __PACKAGE__->load_components(qw/UUIDColumns/);
  __PACKAGE__->table('uuid_test');
  __PACKAGE__->add_columns(
    id   => { data_type => 'varchar', size => 36, uuid_on_create => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

$schema->register_class('UUIDTest' => 'DBIO::Test::Schema::UUIDTest');

# Test: insert without providing id should auto-generate UUID
my $row = $schema->resultset('UUIDTest')->create({ name => 'Test Artist' });
ok($row->id, 'UUID was auto-generated on insert');
like($row->id, qr/^[0-9a-f-]{32,36}$/i, 'UUID looks valid');

# Test: insert with explicit id should use that id
my $explicit_id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
my $row2 = $schema->resultset('UUIDTest')->create({ id => $explicit_id, name => 'Explicit' });
is($row2->id, $explicit_id, 'Explicit UUID preserved on insert');

# Test: two auto-generated UUIDs should differ
my $row3 = $schema->resultset('UUIDTest')->create({ name => 'Another' });
isnt($row->id, $row3->id, 'Two auto-generated UUIDs are different');

# Test: column-info flag is recorded
ok(
  DBIO::Test::Schema::UUIDTest->column_info('id')->{_uuid_on_create},
  '_uuid_on_create flag set on column'
);

done_testing;
