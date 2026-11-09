use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::DDL ();
use DBIO::SQL::Util ();

# OFFLINE test for karr k96: deploy_async of the ev transport follows the same
# rule as the sync deploy and the future_io transport (dbio-postgresql k142)
# for the schema of a CREATE EXTENSION -- declared schema, else the schema the
# control file of the extension fixes (read from the server,
# pg_available_extension_versions), else public.
#
# WHAT IT PINS: before the DDL is built the transport asks the server, over a
# pooled connection, which schemas the control files of the declared
# extensions fix, and the DDL it puts on the wire is the one
# DBIO::PostgreSQL::DDL->install_ddl writes with that answer. A declared
# schema against a fixed one fails the Future before the first DDL statement.
# A schema that declares no extension asks nothing, and a second deploy on the
# same storage reads its own answer. The control file of the fake extension is
# made up: the rule is the server's answer, not a list of extensions.

our %FIXED;    # extension name => schema its (fake) control file fixes

{
  package FakeConn;
  sub new { bless { log => [] }, shift }
  sub query_params {
    my ($s, $sql, $bind, $cb) = @_;
    push @{ $s->{log} }, $sql;
    if ($sql =~ /pg_available_extension_versions/) {
      return $cb->([ map { [ $_, $main::FIXED{$_} ] } sort keys %main::FIXED ], undef);
    }
    return $cb->([], undef);
  }
}
{
  package FakePool;
  use Future ();
  sub new { bless { conns => [] }, shift }
  sub acquire {
    my $self = shift;
    $self->{conns}[0] ||= FakeConn->new;
    return Future->done($self->{conns}[0]);
  }
  sub acquire_txn { $_[0]->acquire }
  sub release     { }
  sub _lease      { 1 }
  sub shutdown    { }
  sub available   { 1 }
}
{
  package FakeOwner;
  sub _use_transactional_ddl { 1 }
}

{
  package K96::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('pgcrypto', 'citext');
}
{
  package K96::Clash;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('public', 'other');
  __PACKAGE__->pg_extensions(pgcrypto => { schema => 'other' });
}
{
  package K96::None;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

sub storage {
  my $s = DBIO::PostgreSQL::EV::Storage->new(undef);
  $s->{pool} = FakePool->new;
  $s->_owner_storage('FakeOwner');
  return $s;
}

sub wire { return @{ $_[0]{pool}{conns}[0]{log} || [] } }

sub ddl_statements {
  my ($schema, %opts) = @_;
  return grep { !/^\s*--/ } DBIO::SQL::Util::_split_statements(
    DBIO::PostgreSQL::DDL->install_ddl($schema, %opts));
}

# ---- a fixed schema is read before the DDL is built -------------------------
{
  local %FIXED = (pgcrypto => 'crypto_catalog');
  my $storage = storage();
  my $f = $storage->deploy_async('K96::Schema');
  my @log = wire($storage);
  ok $f->is_done, 'deploy_async lives' or diag scalar $f->failure;

  like $log[0], qr/pg_available_extension_versions/,
    'the first statement on the wire is the question to the server';
  like $log[0], qr/'pgcrypto'/, '... for the declared extensions';
  like $log[0], qr/'citext'/, '... all of them';
  is $log[1], 'BEGIN', 'the DDL batch follows, in its transaction';
  is $log[-1], 'COMMIT', '... and commits';

  is_deeply [ @log[2 .. $#log - 1] ],
    [ ddl_statements('K96::Schema', extension_control_schemas => { %FIXED }) ],
    'the DDL is the install DDL written with the control schemas';

  my $joined = join "\n", @log;
  like $joined, qr/^CREATE EXTENSION IF NOT EXISTS pgcrypto$/m,
    'an extension whose control file fixes a schema is written without a clause';
  like $joined, qr/^CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public$/m,
    'one without a fixed schema is written WITH SCHEMA public';
}

# ---- a second deploy on the same storage reads its own answer --------------
{
  my $storage = storage();
  {
    local %FIXED = (pgcrypto => 'crypto_catalog');
    my $first = $storage->deploy_async('K96::Schema');
  }
  my $before = () = wire($storage);
  local %FIXED = ();
  my $second = $storage->deploy_async('K96::Schema');
  my @all = wire($storage);
  like join("\n", @all[ $before .. $#all ]),
    qr/^CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public$/m,
    'the second deploy does not keep the control schemas of the first';
}

# ---- a declared schema against a fixed one is refused ----------------------
{
  local %FIXED = (pgcrypto => 'crypto_catalog');
  my $storage = storage();
  my $f = $storage->deploy_async('K96::Clash');
  ok $f->is_failed, 'a declared schema other than the fixed one fails the Future';
  like scalar($f->failure),
    qr/extension pgcrypto is declared in schema other, but its control file fixes schema crypto_catalog/,
    '... naming the extension and both schemas';
  ok !grep({ $_ eq 'BEGIN' } wire($storage)), '... before the first statement of the DDL';
}

# ---- no extension declared: the server is not asked ------------------------
{
  local %FIXED = (pgcrypto => 'crypto_catalog');
  my $storage = storage();
  my $f = $storage->deploy_async('K96::None');
  ok $f->is_done, 'deploy_async lives without a declared extension' or diag scalar $f->failure;
  ok !grep({ /pg_available_extension_versions/ } wire($storage)),
    '... and asks nothing about control files';
}

done_testing;
