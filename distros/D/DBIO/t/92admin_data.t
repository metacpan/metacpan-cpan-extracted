use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Admin;
use DBIO::Test;

my $schema = DBIO::Test->init_schema;
my $storage = $schema->storage;

my $admin = DBIO::Admin->new(
  schema    => $schema,
  quiet     => 1,
  _confirm  => 1,
);

isa_ok($admin, 'DBIO::Admin', 'admin object created');

# insert
$storage->reset_captured;
my $obj = $admin->insert('Artist', { name => 'Matt' });
ok($obj, 'insert returned an object');
my @queries = $storage->captured_queries;
my @inserts = grep { $_->{op} eq 'insert' } @queries;
ok(scalar @inserts, 'insert generated an INSERT query');
like($inserts[0]{sql}, qr/INSERT\s+INTO\s+artist/i, 'insert SQL targets artist table');

# update (update_all iterates rows, so mock both count and select)
$storage->reset_captured;
$storage->mock(qr/SELECT\s+COUNT/i, [[1]]);
$storage->mock(qr/SELECT.*FROM\s+artist/i, [[4, 'Matt']]);
$admin->update('Artist', { name => 'Trout' }, { name => 'Matt' });
@queries = $storage->captured_queries;
my @updates = grep { $_->{op} eq 'update' } @queries;
ok(scalar @updates, 'update generated UPDATE queries');
like($updates[0]{sql}, qr/UPDATE\s+artist/i, 'update SQL targets artist table');

# select
$storage->reset_captured;
$storage->mock(qr/SELECT.*FROM\s+artist/i, [
  [4, 'Aran'],
  [5, 'Trout'],
]);
my $data = $admin->select('Artist', { name => { -in => [qw(Trout Aran)] } }, { order_by => 'name' });
is(ref($data), 'ARRAY', 'select returns arrayref');
ok(scalar @$data >= 1, 'select returns header row');
is($data->[0][0], 'artistid', 'select header has column names');

# delete (delete_all iterates rows, so mock both count and select)
$storage->reset_captured;
$storage->mock(qr/SELECT\s+COUNT/i, [[1]]);
$storage->mock(qr/SELECT.*FROM\s+artist/i, [[5, 'Trout']]);
$admin->delete('Artist', { name => 'Trout' });
@queries = $storage->captured_queries;
my @deletes = grep { $_->{op} eq 'delete' } @queries;
ok(scalar @deletes, 'delete generated DELETE queries');
like($deletes[0]{sql}, qr/DELETE\s+FROM\s+artist/i, 'delete SQL targets artist table');

done_testing;
