use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k142: deploy_async of the future_io transport follows
# the same rule as the sync deploy for the schema of a CREATE EXTENSION --
# declared schema, else the schema the control file of the extension fixes
# (read from the server, pg_available_extension_versions), else public.
#
# WHAT IT PINS: before the DDL is built, the transport asks the server over a
# pooled connection (asynchronously) which schemas the control files of the
# declared extensions fix, and the DDL it puts on the wire is the one
# DBIO::PostgreSQL::DDL->install_ddl writes with that answer
# (extension_control_schemas), the statement of such an extension without the
# WITH SCHEMA clause. A declared schema against a fixed one is refused before
# the first statement of the DDL. A schema that declares no extension asks
# nothing. The fake server is the one of t/60: no server is touched; the
# control file of the fake extension is made up, the rule is the server's
# answer and not a list of extensions.

use DBIO::PostgreSQL::DDL;
use DBIO::Deploy::Base ();

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use DBIO::PostgreSQL::Storage;

our %FIXED;    # extension name => schema its (fake) control file fixes

{
  package K142::STH;
  sub new { my ($class, %a) = @_; return bless { %a }, $class }
  sub execute {
    my $self = shift;
    push @{ $self->{dbh}{wire} }, { sql => $self->{sql}, bind => [ @_ ] };
    return 1;
  }
  sub fetchall_arrayref {
    return [ map { [ $_, $main::FIXED{$_} ] } sort keys %main::FIXED ];
  }
}
{
  package K142::DBH;
  sub new { bless { wire => [], Active => 1, pg_socket => -1 }, shift }
  sub prepare {
    my ($self, $sql, $attrs) = @_;
    push @{ $self->{prepare_attrs} }, $attrs;
    my $fields = $sql =~ /pg_available_extension_versions/ ? 2 : 0;
    return K142::STH->new(dbh => $self, sql => $sql, NUM_OF_FIELDS => $fields);
  }
  sub pg_ready  { 1 }
  sub pg_result { 0 }
  sub state     { q{} }
}
{
  package K142::Transport;
  use base 'DBIO::PostgreSQL::Storage::Async';
  sub _create_pool_connection { return { dbh => K142::DBH->new } }
  sub _await_readable { return $_[0]->future_class->done }
  # the question and the DDL run on one connection, as with a real socket:
  # the fake has none, and a connection without one is taken for gone
  sub _idle_connection_alive { 1 }
  # the fake counts what goes on the wire; the reset between borrows
  # (DISCARD ALL, k154) is not what this file is about (t/195, t/196)
  sub _reset_pool_connection { $_[0]->future_class->done }
}

{
  package K142::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('pgcrypto', 'citext');
}
{
  package K142::Clash;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('public', 'other');
  __PACKAGE__->pg_extensions(pgcrypto => { schema => 'other' });
}
{
  package K142::None;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

my $owner = DBIO::PostgreSQL::Storage->new;

sub run {
  my ($schema) = @_;
  my $t = K142::Transport->new(undef);
  $t->connect_info([ 'dbi:Pg:dbname=k142', 'u', 'p', {} ]);
  $t->_owner_storage($owner);
  my $ok = eval { $t->deploy_async($schema)->get; 1 };
  my $err = $@;
  my $conn = $t->pool->{_connections}[0];
  my @wire = $conn ? map { $_->{sql} } @{ $conn->{dbh}{wire} } : ();
  return ($ok, $err, \@wire, $conn);
}

# ---- a fixed schema is read before the DDL is built -------------------------
{
  local %FIXED = (pgcrypto => 'crypto_catalog');
  my ($ok, $err, $wire, $conn) = run('K142::Schema');
  ok $ok, 'deploy_async lives' or diag $err;

  like $wire->[0], qr/pg_available_extension_versions/,
    'the first statement on the wire is the question to the server';
  like $wire->[0], qr/'pgcrypto'/, '... for the declared extensions';
  like $wire->[0], qr/'citext'/, '... all of them';
  is $wire->[1], 'BEGIN', 'the DDL batch follows, in its transaction';
  is $wire->[-1], 'COMMIT', '... and commits';

  my $want = DBIO::PostgreSQL::DDL->install_ddl('K142::Schema',
    extension_control_schemas => { %FIXED });
  my @want = DBIO::Deploy::Base::_split_ddl($owner, $want);
  is_deeply [ @$wire[2 .. $#$wire - 1] ], \@want,
    'the DDL is the install DDL written with the control schemas';

  my $joined = join "\n", @$wire;
  like $joined, qr/^CREATE EXTENSION IF NOT EXISTS pgcrypto$/m,
    'an extension whose control file fixes a schema is written without a clause';
  like $joined, qr/^CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public$/m,
    'one without a fixed schema is written WITH SCHEMA public';

  ok !grep({ !$_->{pg_async} } @{ $conn->{dbh}{prepare_attrs} }),
    'the question too went out over the async binding';
}

# ---- nothing fixed: the DDL is what install_ddl writes alone ---------------
{
  local %FIXED = ();
  my ($ok, $err, $wire) = run('K142::Schema');
  ok $ok, 'deploy_async lives with nothing fixed' or diag $err;
  my @want = DBIO::Deploy::Base::_split_ddl($owner,
    DBIO::PostgreSQL::DDL->install_ddl('K142::Schema'));
  is_deeply [ @$wire[2 .. $#$wire - 1] ], \@want,
    '... and the DDL is the one install_ddl writes on its own';
}

# ---- a declared schema against a fixed one is refused ----------------------
{
  local %FIXED = (pgcrypto => 'crypto_catalog');
  my ($ok, $err, $wire) = run('K142::Clash');
  ok !$ok, 'a declared schema other than the fixed one is refused';
  like "$err", qr/extension pgcrypto is declared in schema other, but its control file fixes schema crypto_catalog/,
    '... naming the extension and both schemas';
  ok !grep({ $_ eq 'BEGIN' } @$wire), '... before the first statement of the DDL';
}

# ---- no extension declared: the server is not asked ------------------------
{
  local %FIXED = (pgcrypto => 'crypto_catalog');
  my ($ok, $err, $wire) = run('K142::None');
  ok $ok, 'deploy_async lives without a declared extension' or diag $err;
  ok !grep({ /pg_available_extension_versions/ } @$wire),
    '... and asks nothing about control files';
}

done_testing;
