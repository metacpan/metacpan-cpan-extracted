use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k67: the future_io transport can deploy, and what it
# deploys is what the sync path deploys.
#
# WHAT THIS TEST PROVES: DBIO::PostgreSQL::Storage::Async->deploy_async puts
# byte-identical DDL on the wire to what DBIO::PostgreSQL::Deploy installs.
# Not "_ddl_class is set" -- the assertion is on the statements that actually
# reached the connection after the REAL inherited deploy_async ran: DDL
# generation, the ADR 0026 transactional bracket, the statement split, the
# per-statement _transform_sql pass and _submit_query. A second DDL generator
# on this transport, or a _ddl_class naming a different class than the sync
# DBIO::PostgreSQL::Deploy names, turns the comparison red.
#
# Until k67 this transport defined no _ddl_class at all, so deploy_async died
# in core's abstract seam ("Subclass must override _ddl_class to support
# deploy_async") while dbio-postgresql-ev had it -- ADR 0030's "reach parity"
# item. That failure mode is covered by simply getting here at all.
#
# THE SUBSTITUTIONS, and nothing else (same shape dbio-async t/04 uses):
#   * _create_pool_connection hands back a fake DBD::Pg handle instead of
#     DBI->connect -- there is no server. The fake answers exactly the DBD::Pg
#     primitives this transport uses: prepare/execute, pg_ready, pg_result,
#     NUM_OF_FIELDS, Active, pg_socket.
#   * _await_readable resolves immediately instead of Future::IO->poll on a
#     real socket fd. Future::IO auto-routes to whichever Impl happens to be
#     installed, so a real fd would exercise a different implementation per box.
# Everything from deploy_async down to _submit_query is the shipped code.

use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Deploy;
use DBIO::Deploy::Base ();

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async,
# which is only a recommends -- a minimal install may not have it. Load the
# adapter (which pulls the base) defensively so this offline suite skips
# cleanly instead of dying at compile time when dbio-async is absent.
BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use DBIO::PostgreSQL::Storage;

# -----------------------------------------------------------------------
# The schema to deploy. Deliberately more than one statement and more than
# one KIND of statement (extension, namespace, table, index), so a parity
# comparison that happened to be empty could not pass unnoticed.
# -----------------------------------------------------------------------
{
  package DeployAsync::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('pgcrypto');
  __PACKAGE__->pg_schemas('auth');
}
{
  package DeployAsync::Schema::Result::User;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('auth');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id => {
      data_type         => 'integer',
      is_auto_increment => 1,
      is_nullable       => 0,
    },
    email => {
      data_type   => 'varchar',
      size        => 255,
      is_nullable => 0,
    },
    metadata => {
      data_type   => 'jsonb',
      is_nullable => 1,
    },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->pg_index('users_metadata_gin_idx' => {
    using   => 'gin',
    columns => ['metadata'],
  });
}
DeployAsync::Schema->register_class(User => 'DeployAsync::Schema::Result::User');

# -----------------------------------------------------------------------
# Fake DBD::Pg primitives: a handle that records every statement handed to
# it instead of speaking to a server.
# -----------------------------------------------------------------------
{
  package DeployAsync::STH;
  sub new { my ($class, %args) = @_; return bless { %args }, $class }
  sub execute {
    my $self = shift;
    push @{ $self->{dbh}{wire} }, { sql => $self->{sql}, bind => [ @_ ] };
    return 1;
  }
  sub fetchall_arrayref { [] }
}
{
  package DeployAsync::DBH;
  sub new {
    my ($class) = @_;
    # Active / pg_socket are read as hash keys by _conn_ready / _conn_fileno.
    return bless { wire => [], Active => 1, pg_socket => -1 }, $class;
  }
  sub prepare {
    my ($self, $sql, $attrs) = @_;
    push @{ $self->{prepare_attrs} }, $attrs;
    # NUM_OF_FIELDS is read as a hash key by _collect_result; DDL yields none.
    # the one question deploy_async asks first (karr k142): the schemas the
    # control files of the declared extensions fix -- none here
    my $fields = $sql =~ /pg_available_extension_versions/ ? 2 : 0;
    return DeployAsync::STH->new(dbh => $self, sql => $sql, NUM_OF_FIELDS => $fields);
  }
  sub pg_ready  { 1 }
  sub pg_result { 0 }   # affected-row count for a statement with no result set
  sub state     { q{} }  # SQLSTATE, read after pg_result: none (karr k83)
}
{
  package DeployAsync::Transport;
  use base 'DBIO::PostgreSQL::Storage::Async';
  sub _create_pool_connection { return { dbh => DeployAsync::DBH->new } }
  sub _await_readable { return $_[0]->future_class->done }
  # the fake has no socket, and a connection without one is taken for gone
  sub _idle_connection_alive { 1 }
  # the fake counts what goes on the wire; the reset between borrows
  # (DISCARD ALL, k154) is not what this file is about (t/195, t/196)
  sub _reset_pool_connection { $_[0]->future_class->done }
}

# -----------------------------------------------------------------------
# 1. Both deploy paths name the SAME DDL generator
# -----------------------------------------------------------------------
is(
  DBIO::PostgreSQL::Storage::Async->_ddl_class,
  'DBIO::PostgreSQL::DDL',
  '_ddl_class is DBIO::PostgreSQL::DDL',
);
is(
  DBIO::PostgreSQL::Storage::Async->_ddl_class,
  DBIO::PostgreSQL::Deploy->_ddl_class,
  '... the same generator the sync DBIO::PostgreSQL::Deploy names',
);

# -----------------------------------------------------------------------
# 2. Run the REAL deploy_async and capture the wire
# -----------------------------------------------------------------------
my $owner = DBIO::PostgreSQL::Storage->new;
ok $owner->_use_transactional_ddl,
  'the sync PostgreSQL storage declares transactional DDL (ADR 0026)';

my $async = DeployAsync::Transport->new(undef);
$async->connect_info([ 'dbi:Pg:dbname=deploy_async_test', 'u', 'p', {} ]);
# _owner_storage is what deploy_async probes for _use_transactional_ddl, so
# the async batch takes the same bracketed branch a real PG connection would.
$async->_owner_storage($owner);

my @warnings;
{
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $async->deploy_async('DeployAsync::Schema')->get;
}
is_deeply \@warnings, [],
  'deploy_async warns nothing -- PostgreSQL DDL is transactional, so no '
  . '"non-transactional DDL" notice';

my $conn = $async->pool->{_connections}[0];
ok $conn, 'deploy_async acquired a pooled connection';

my @wire = map { $_->{sql} } @{ $conn->{dbh}{wire} };
like shift(@wire), qr/pg_available_extension_versions/,
  'pgcrypto is declared: the control schemas are asked for first (karr k142)';
ok scalar(@wire) > 2, 'several statements reached the wire';

# -----------------------------------------------------------------------
# 3. The bracket: ADR 0026 / karr k50 -- PostgreSQL rolls DDL back
# -----------------------------------------------------------------------
is shift(@wire), 'BEGIN', 'the DDL batch opens a transaction';
is pop(@wire),   'COMMIT', '... and commits it';

# -----------------------------------------------------------------------
# 4. What is between them is byte-identical to the sync install DDL
# -----------------------------------------------------------------------
# The generator the deploy names, called as deploy_async calls it. The sync
# deploy's own _install_ddl adds the schemas control files fix, read from a
# server (karr k141) -- none here, no server, and none for this schema.
my $sync_ddl = DBIO::PostgreSQL::Deploy->_ddl_class
  ->install_ddl('DeployAsync::Schema');
my @sync_stmts = DBIO::Deploy::Base::_split_ddl($owner, $sync_ddl);

is_deeply \@wire, \@sync_stmts,
  'deploy_async put byte-identical DDL on the wire to what '
  . 'DBIO::PostgreSQL::Deploy installs';

# The comparison is not vacuous: name the kinds of statement it covered.
my $joined = join "\n", @wire;
like $joined, qr/CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public$/m,
  '... including the declared extension';
like $joined, qr/CREATE SCHEMA IF NOT EXISTS auth/,
  '... the declared PostgreSQL namespace';
like $joined, qr/CREATE TABLE auth\.users \(/,
  '... the table';
like $joined, qr/CREATE INDEX users_metadata_gin_idx ON auth\.users USING gin/,
  '... and the pg_index declaration';

# -----------------------------------------------------------------------
# 5. Each statement went out over the async binding, not $dbh->do
# -----------------------------------------------------------------------
my $attrs = $conn->{dbh}{prepare_attrs};
is scalar(@$attrs), scalar(@{ $conn->{dbh}{wire} }),
  'every statement was prepared through DBD::Pg';
ok !grep({ !$_->{pg_async} } @$attrs),
  '... each one with pg_async set -- the DDL really ran non-blocking';

# -----------------------------------------------------------------------
# 6. A schema WITHOUT the PostgreSQL component deploys too (karr k82).
#    Connecting with { async => ... } and no load_components('PostgreSQL') is
#    a documented shape (dbio-postgresql-ev k36); install_ddl used to ask such
#    a schema for pg_extensions and die, so deploy_async failed before a
#    single statement reached the wire. What t/69 pins at the install_ddl
#    level is pinned here through the real deploy_async.
# -----------------------------------------------------------------------
{
  package DeployAsync::PlainSchema;
  use base 'DBIO::Schema';
}
{
  package DeployAsync::PlainSchema::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    label => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
}
DeployAsync::PlainSchema->register_class(Item => 'DeployAsync::PlainSchema::Result::Item');

{
  ok !DeployAsync::PlainSchema->can('pg_extensions'),
    'the plain schema does not load the PostgreSQL component';

  my $plain = DeployAsync::Transport->new(undef);
  $plain->connect_info([ 'dbi:Pg:dbname=deploy_async_test', 'u', 'p', {} ]);
  $plain->_owner_storage($owner);

  my $ok = eval { $plain->deploy_async('DeployAsync::PlainSchema')->get; 1 };
  ok $ok, 'deploy_async deploys a schema without the PostgreSQL component'
    or diag "deploy_async failed: $@";

  my $pconn = $plain->pool->{_connections}[0];
  my @pwire = $pconn ? map { $_->{sql} } @{ $pconn->{dbh}{wire} } : ();
  is shift(@pwire), 'BEGIN',  '... in one transaction';
  is pop(@pwire),   'COMMIT', '... committed';

  my $want_ddl = eval { DBIO::PostgreSQL::DDL->install_ddl('DeployAsync::PlainSchema') } // '';
  my @want = DBIO::Deploy::Base::_split_ddl($owner, $want_ddl);
  is_deeply \@pwire, \@want, '... putting exactly its install DDL on the wire';
  like join("\n", @pwire), qr/CREATE TABLE item \(/, '... the table among it';
  unlike join("\n", @pwire), qr/CREATE EXTENSION/, '... and no extension';
}

done_testing;
