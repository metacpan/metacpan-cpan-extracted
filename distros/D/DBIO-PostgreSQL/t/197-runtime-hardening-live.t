use strict;
use warnings;
use Test::More;

# LIVE: the server accepts what the hardenings of karr k155 send (the offline
# half is t/196-runtime-hardening.t, t/26-jsonb.t).
#
# WHY: a bind in the place of a literal is only as good as the server's
# reading of it. Claimed here, against a real server:
#   1. an auto_nextval column fetches its value with nextval(?::regclass),
#      for a plain, a schema-qualified and a quoted sequence name;
#   2. jsonb() with its path as a bind finds the rows: a single key (->>?),
#      a nested path (#>>?::text[]) and a key that holds a quote, a comma
#      and a double quote; as_order orders by it;
#   3. a savepoint of a plain name works and one with a ';' is refused before
#      anything is sent;
#   4. the detail of a unique violation reaches the exception without the
#      value.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

use DBIO::PostgreSQL::JSONB qw(jsonb);
use JSON::MaybeXS ();
my $json = JSON::MaybeXS->new(canonical => 1);

BEGIN {
  package DBIO::Test::K155::Result::Doc;
  $INC{'DBIO/Test/K155/Result/Doc.pm'} = 1;
  use base 'DBIO::Core';

  __PACKAGE__->table('dbio_k155_doc');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', auto_nextval => 1, sequence => 'dbio_k155_seq' },
    name => { data_type => 'text', is_nullable => 1 },
    data => { data_type => 'jsonb', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(name_uq => ['name']);

  package DBIO::Test::K155;
  $INC{'DBIO/Test/K155.pm'} = 1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Doc => 'DBIO::Test::K155::Result::Doc');
}

my $dbh = LiveServer->control_dbh;
$dbh->do('DROP TABLE IF EXISTS dbio_k155_doc');
$dbh->do('DROP SEQUENCE IF EXISTS dbio_k155_seq');
$dbh->do('CREATE SEQUENCE dbio_k155_seq START 100');
$dbh->do('CREATE TABLE dbio_k155_doc (id integer PRIMARY KEY, name text UNIQUE, data jsonb)');

my $schema = DBIO::Test::K155->connect($dsn, $user, $pass);
my $rs = $schema->resultset('Doc');

# 1. sequence
my $first = $rs->create({ name => 'one', data => $json->encode({ a => 'x', n => { m => 'deep' } }) });
is $first->id, 100, 'auto_nextval fetched the value of the sequence through a bind';
is $schema->storage->_sequence_fetch('NEXTVAL', \'public.dbio_k155_seq'), 101,
  '... a schema-qualified name';
$dbh->do('CREATE SEQUENCE "dbio_K155 Seq" START 500');
is $schema->storage->_sequence_fetch('NEXTVAL', '"dbio_K155 Seq"'), 500,
  '... a quoted name keeps its quoting';
$dbh->do('DROP SEQUENCE "dbio_K155 Seq"');

# 2. jsonb path as a bind
my $tricky = qq{it's,"q"};
$rs->create({ name => 'two', data => $json->encode({ a => 'y', n => { m => 'other' }, $tricky => 'odd' }) });

is $rs->search(jsonb('me.data', 'a')->eq('x'))->count, 1, 'single key: ->>?';
is $rs->search(jsonb('me.data', 'n', 'm')->eq('deep'))->count, 1, 'nested path: #>>?::text[]';
is $rs->search(jsonb('me.data', $tricky)->eq('odd'))->count, 1, 'a key with quote, comma and double quote';
is $rs->search(jsonb('me.data', 'a')->is_not_null)->count, 2, 'IS NOT NULL';
is_deeply [ map { $_->name } $rs->search({}, { order_by => { -desc => jsonb('me.data', 'a')->as_order } })->all ],
  [ 'two', 'one' ], 'as_order orders by the extracted value';

# 3. savepoints
$schema->txn_do(sub {
  $schema->storage->svp_begin('k155_sp');
  $rs->create({ name => 'three' });
  $schema->storage->svp_rollback('k155_sp');
  $schema->storage->svp_release('k155_sp');
  is $rs->search({ name => 'three' })->count, 0, 'a savepoint of a plain name rolls back';
  ok !eval { $schema->storage->svp_begin('x; DELETE FROM dbio_k155_doc; --'); 1 },
    'a savepoint name with ; is refused';
});
is $rs->search({ name => 'one' })->count, 1, '... and nothing was deleted';

# 4. detail without the value
my $err;
eval { $rs->create({ name => 'one' }); 1 } or $err = $@;
isa_ok $err, 'DBIO::Exception::Server', 'the unique violation';
is $err && $err->detail, 'Key (name)=(***) already exists.', '... its detail has no value';
unlike "$err", qr/=\(one\)/, '... nor has its message';

$dbh->do('DROP TABLE dbio_k155_doc');
$dbh->do('DROP SEQUENCE dbio_k155_seq');

done_testing;
