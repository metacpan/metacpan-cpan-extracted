use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k121 (P13): the install leaves the search_path of the
# caller's session as it was, and a restrictive policy arrives as one.
#
# WHY it exists: the install script ended with SET search_path TO
# <pg_search_path> ("public" where nothing is declared). The statement runs in
# the session that runs the script -- the connection of the application, for
# Deploy->install -- and stays there: an application that connected with its
# own search_path (a tenant's, options=-csearch_path=..., on_connect_do) had
# another one after the install, and no statement of the script needed it:
# every object is created ahead of that statement. The script no longer ends
# with it.
#
# Asked the way it matters: a session with a search_path of its own runs the
# install, and afterwards SHOW search_path says what it said before. The same
# for a connection that names its namespace, whose script carries its own path
# for the temporary database of a diff (t/129). And the policy: AS RESTRICTIVE
# is in the catalog as polpermissive = false, and the diff of what was just
# installed finds nothing to do.

my %ATTR = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);
my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });

my $n = 0;
sub table_class {
  my ($name, %more) = @_;
  my $class = 'T168::Result::T' . ++$n;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('$name');
    1;
  } or die $@;
  $class->add_columns(id => { data_type => 'integer', is_nullable => 0 });
  $class->set_primary_key('id');
  $class->pg_rls($more{rls}) if $more{rls};
  return $class;
}
sub schema_class {
  my (%results) = @_;
  my $class = 'T168::Schema' . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->register_class($_ => $results{$_}) for sort keys %results;
  return $class;
}
sub path { ($_[0]->selectrow_array(q{SELECT pg_catalog.current_setting('search_path')}))[0] }

# ---------------------------------------------------------------------------
# 1. A session with its own search_path
# ---------------------------------------------------------------------------
{
  my $class = schema_class(Item => table_class('item_168'));
  $class->pg_search_path(qw( somewhere_else public ));    # declared, and not the session's
  my @db = PrivatePgDatabase->create('t168path');
  my $own = 'session_own, public';
  my $schema = $class->connect(@db, { %{ $CONNECT[0] }, on_connect_do => [ "SET search_path TO $own" ] });
  my $dbh = $schema->storage->dbh;
  is(path($dbh), $own, 'precondition: the session has a search_path of its own');
  ok(eval { $schema->pg_deploy->install; 1 }, 'install runs through') or diag $@;
  is(path($schema->storage->dbh), $own, 'afterwards the session has the search_path it had');
  is(scalar $dbh->selectrow_array(q{SELECT pg_catalog.to_regclass('public.item_168') IS NOT NULL}), 1,
    'and the table is in public, where the path of the session finds the first existing schema');
  $schema->storage->disconnect;

  my $again = $class->connect(@db, @CONNECT);
  my $diff = eval { $again->pg_deploy->diff };
  ok($diff && !$diff->has_changes, 'the diff of what was installed finds nothing to do')
    or diag($diff ? $diff->as_sql : $@);
  $again->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 2. A connection that names its namespace
# ---------------------------------------------------------------------------
{
  my $class = schema_class(Item => table_class('item_168'));
  my @db = PrivatePgDatabase->create('t168ns');
  my $schema = $class->connect(@db, { %{ $CONNECT[0] }, schema => 'tenant_168' });
  my $before = path($schema->storage->dbh);
  like($before, qr/\Atenant_168\b/, 'precondition: the connection has its namespace first');
  ok(eval { $schema->pg_deploy->install; 1 }, 'install runs through') or diag $@;
  is(path($schema->storage->dbh), $before, 'afterwards the session has the search_path it had');
  is(scalar $schema->storage->dbh->selectrow_array(
      q{SELECT pg_catalog.to_regclass('tenant_168.item_168') IS NOT NULL}), 1,
    'and the table is in the namespace');
  $schema->storage->disconnect;

  my $again = $class->connect(@db, { %{ $CONNECT[0] }, schema => 'tenant_168' });
  my $diff = eval { $again->pg_deploy->diff };
  ok($diff && !$diff->has_changes, 'the diff of what was installed finds nothing to do')
    or diag($diff ? $diff->as_sql : $@);
  $again->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 3. A restrictive policy
# ---------------------------------------------------------------------------
{
  my $class = schema_class(Item => table_class('item_168', rls => {
    enable   => 1,
    policies => {
      p_open  => { using => 'true' },
      p_tight => { restrictive => 1, using => 'id > 0' },
    },
  }));
  my @db = PrivatePgDatabase->create('t168rls');
  my $schema = $class->connect(@db, @CONNECT);
  ok(eval { $schema->pg_deploy->install; 1 }, 'install runs through') or diag $@;
  my %permissive = map { @$_ } @{ $schema->storage->dbh->selectall_arrayref(
    q{SELECT polname, polpermissive FROM pg_catalog.pg_policy}) };
  ok($permissive{p_open},   'a policy without the key is permissive in the catalog');
  ok(defined $permissive{p_tight} && !$permissive{p_tight}, 'restrictive => 1 is RESTRICTIVE in the catalog')
    or diag explain \%permissive;
  $schema->storage->disconnect;

  my $again = $class->connect(@db, @CONNECT);
  my $diff = eval { $again->pg_deploy->diff };
  ok($diff && !$diff->has_changes, 'the diff of what was installed finds nothing to do')
    or diag($diff ? $diff->as_sql : $@);
  $again->storage->disconnect;
}

done_testing;
