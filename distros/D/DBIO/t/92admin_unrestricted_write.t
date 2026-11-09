use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Admin;
use DBIO::Test;

# ADR 0069: update and delete without a condition need all => 1; the admin
# passes the release through (--all of dbioadmin) and throws like the core
# without it.

my $schema  = DBIO::Test->init_schema;
my $storage = $schema->storage;
$storage->mock(qr/SELECT/i, [[1, 'A']]);

my %args = (schema => $schema, resultset => 'Artist', quiet => 1, _confirm => 1);
my $plain = DBIO::Admin->new(%args);
my $all   = DBIO::Admin->new(%args, all => 1);

$storage->reset_captured;
throws_ok { $plain->delete } qr/delete_all on an unrestricted resultset: pass \{ all => 1 \}/,
  'delete without a condition throws';
throws_ok { $plain->update('Artist', { name => 'x' }) }
  qr/update_all on an unrestricted resultset: pass \{ all => 1 \}/,
  'update without a condition throws';
ok(! (grep { $_->{op} =~ /^(?:update|delete)$/ } $storage->captured_queries),
  'nothing was written');

lives_ok { $all->delete } 'delete without a condition runs with all';
$storage->mock(qr/SELECT/i, [[1, 'A']]);
lives_ok { $all->update('Artist', { name => 'x' }) } 'update without a condition runs with all';
ok((grep { $_->{op} eq 'delete' } $storage->captured_queries), 'a DELETE ran');
ok((grep { $_->{op} eq 'update' } $storage->captured_queries), 'an UPDATE ran');

ok($all->all, 'all reads back');
ok(! $plain->all, 'all is off by default');

lives_ok { $plain->delete('Artist', { name => 'A' }) } 'a condition needs no all';

done_testing;
