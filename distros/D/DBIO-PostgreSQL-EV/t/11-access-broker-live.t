use strict;
use warnings;
use Test::More;

# LIVE: an AccessBroker hands out the login, and the connections of the ev
# transport are opened from it -- asked of a real PostgreSQL, through
#
#   MyApp::Schema->connect($broker, { async => 'ev' })
#
# and statements issued on the async API (karr k59). Until k59 this file handed
# the broker's answer to EV::Pg->new itself: no storage, no pool, so it showed
# that the server was up and nothing about this distribution.
#
# WHY: a broker exists so that the login is its to decide -- which role, with
# which password, and from when on another one. What the server sees is the
# only proof that the decision arrived: a role that connects, and the role it
# is. So the logins here are roles this file creates and nobody else names --
# not the test user, not the environment, not the DSN. A pool connection the
# server reports as one of them was opened from what the broker answered.
#
# What it claims:
#
#   a) the answer shape no other live file sends through the storage: a libpq
#      conninfo string in an arrayref, in both spellings libpq reads --
#      keyword=value pairs and a postgresql:// URI (only a real libpq can say
#      that the URI is taken; no mock parses one). The broker answers the
#      transport the string, naming a role of this run, and select_async runs
#      on a pool connection logged in as that role, to the test database,
#      carrying the application_name that only the string has. The listen
#      connection is a second backend of the same role with the same
#      application_name: opened from the string too;
#   b) the broker rotates to another role while the pool holds a connection:
#      the next connection the pool opens logs in as the new role, and the one
#      opened before the rotation goes on answering as the old one -- two
#      roles side by side in one pool. A pool that kept the answer of the
#      attach, or of its first connection, would show one role twice.
#
# What it does not claim, and where that is held:
#   - a hash of parameters (Static) and the DBI form (Vault) as the transport's
#     answer, a wrong password refused by the server, a rotation from a
#     refused login to a working one, a notify heard on the listen connection:
#     t/49-access-broker-conninfo-live.t;
#   - the connect options beside a broker and the size of the pool:
#     t/59-access-broker-connect-options-live.t;
#   - every answer shape and every refusal, the exact parameters EV::Pg is
#     constructed with: t/48-access-broker-conninfo-mock.t, offline;
#   - that the storage keeps the broker it was given, in mode 'write':
#     t/02-access-broker.t, offline -- a server adds nothing to that;
#   - anything about the owner's DBI connection. The broker here answers it
#     the DBI form as the test user, so that the schema has a sync half that
#     can connect; this file never opens it.
#
# The test user has to be allowed to create roles, and the server has to let
# such a role log in the way the test user does; the file is skipped, saying
# which, where either is not so. A server that cannot be reached is a failure,
# not a skip: DBIO_TEST_PG_DSN says there is one. The roles are dropped when
# the file ends, however it ends -- except when the alarm kills it; they are
# named dbio_k59_<pid>_a and _b.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use DBIO::AccessBroker;
use DBIO::PostgreSQL::EV::Storage;
use PoolReset;
use DBIO::PostgreSQL::EV::ConnectInfo ();

alarm 120;

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_$_" } qw( DSN USER PASS ) };

my $TAG = "dbio_k59_$$";
my %ROLE = map {
  ($_ => { name => "${TAG}_$_", password => join '', map { ('a' .. 'z', 0 .. 9)[rand 36] } 1 .. 24 })
} qw( a b );

# The test user's connection: it makes the roles and drops them.
my ($admin, @made);
END {
  if ($admin) {
    local ($@, $?);
    for my $name (@made) {
      eval { $admin->do(qq{DROP ROLE IF EXISTS "$name"}); 1 }
        or warn "t/11: role $name is left on the server: $@";
    }
    $admin->disconnect;
  }
}

# A server that is not there fails the file here, with a plan.
$admin = LiveServer->control_dbh;

my ($ADMIN_LOGIN, $DATABASE) = $admin->selectrow_array('SELECT current_user::text, current_database()::text');

for my $role (map { $ROLE{$_} } sort keys %ROLE) {
  unless (eval { $admin->do(qq{CREATE ROLE "$role->{name}" LOGIN PASSWORD '$role->{password}'}); 1 }) {
    die $@ unless ($admin->state // '') eq '42501';   # insufficient_privilege
    plan skip_all => "the test user $ADMIN_LOGIN may not create roles: the logins of this file are roles of its own";
  }
  push @made, $role->{name};
}

# The view role a has of its own backends: every role may read its own rows of
# pg_stat_activity in full, whatever the test user may read. It is also the
# probe: where the server's access rules keep DBD::Pg from logging in as the
# role (peer authentication, a pg_hba.conf that names its users), the transport
# is not asked to. Any other failure of it is one.
my $view = eval {
  DBI->connect($dsn, $ROLE{a}{name}, $ROLE{a}{password}, { RaiseError => 1, PrintError => 0, AutoCommit => 1 })
};
unless ($view) {
  my $refused = (DBI->errstr // $@) =~ s/\s+\z//r;
  die "$refused\n" unless $refused =~ /authentication failed|pg_hba\.conf/;
  plan skip_all => "the server does not let a role created for this test log in: $refused";
}

# What the test DSN says about where to connect, read as DBD::Pg reads it
# (t/53-dbi-to-conninfo.t) -- without a login, which is the roles' here.
my %WHERE = %{ DBIO::PostgreSQL::EV::ConnectInfo::dbi_to_conninfo([ $dsn ])->[0] };
delete @WHERE{qw( user password )};

sub login_parameters {
  my ($role, $marker) = @_;
  return (%WHERE, user => $ROLE{$role}{name}, password => $ROLE{$role}{password}, application_name => $marker);
}

# The two spellings of a libpq conninfo string, written by this file and not by
# the distribution: they are the broker's answer, the thing under test.
sub keyword_value_string {
  my %p = login_parameters(@_);
  return join ' ', map { "$_='" . ($p{$_} =~ s/([\\'])/\\$1/gr) . "'" } sort keys %p;
}

sub uri_string {
  my %p = login_parameters(@_);
  return 'postgresql://?' . join '&',
    map { "$_=" . ($p{$_} =~ s/([^A-Za-z0-9._~-])/sprintf '%%%02X', ord $1/ger) } sort keys %p;
}

# A broker that answers by the storage that asks, each in its own shape: the
# ev transport gets a libpq conninfo string in an arrayref -- whatever is in
# {string} at that moment --, every other storage the DBI form in {dbi}. A
# libpq string is an answer for this transport only: DBI is handed it as a
# DSN, cannot tell the driver from it, and says so quoting the whole string.
{
  package TwoShapeBroker;
  use base 'DBIO::AccessBroker';

  sub new { my ($class, %arg) = @_; bless { %arg }, $class }

  sub connect_info_for_storage {
    my ($self, $storage) = @_;
    return [ $self->{string} ] if $storage->isa('DBIO::PostgreSQL::EV::Storage');
    return [ @{ $self->{dbi} } ];
  }
}

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

sub connect_with {
  my ($string) = @_;
  my $broker = TwoShapeBroker->new(dbi => [ $dsn, $user, $pass ], string => $string);
  return ($broker, BrokerSchema->connect($broker, { async => 'ev' }));
}

# get, bounded: a Future that does not settle fails instead of hanging. Dies
# with the Future's failure.
sub settle {
  my ($f, $what) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(15, 0, sub { $f->fail("watchdog: $what still pending after 15s\n") unless $f->is_ready });
  $dog->keepalive(0);
  return $f->get;
}

# $n statements issued at once on the async API of the schema's storage. Each
# is answered by the pool connection that ran it, about itself: the role it is
# logged in as, its database, its application_name. A failure is shown and
# leaves no rows.
sub logins {
  my ($storage, $n) = @_;
  my @rows = eval {
    settle($storage->async->future_class->needs_all(
      map {
        $storage->select_async(
          'pg_catalog.pg_stat_activity', [ 'usename', 'datname', 'application_name' ],
          { pid => \'= pg_backend_pid()' },
        )
      } 1 .. $n
    ), "$n statement(s)")
  };
  diag $@ if $@;
  return @rows;
}

sub hang_up {
  my ($schema) = @_;
  eval { $schema->storage->async->disconnect };
  eval { $schema->storage->disconnect };
  return;
}

for my $spelling (
  [ kv  => 'keyword=value pairs',  \&keyword_value_string ],
  [ uri => 'a postgresql:// URI', \&uri_string           ],
) {
  my ($short, $name, $string_for) = @$spelling;

  subtest "a) a libpq conninfo string in an arrayref: $name" => sub {
    my $marker = "${TAG}_$short";
    my (undef, $schema) = connect_with($string_for->(a => $marker));
    my $storage = $schema->storage;

    is_deeply [ logins($storage, 1) ], [ [ $ROLE{a}{name}, $DATABASE, $marker ] ],
      'select_async ran on a pool connection logged in as the role the string names, '
    . 'to its database, with its application_name';

    eval { settle($storage->async->listen("${marker}_channel" => sub { }), 'listen'); 1 } or diag $@;
    my $backends = $view->selectall_arrayref(
      'SELECT query, datname FROM pg_catalog.pg_stat_activity
        WHERE usename = current_user AND application_name = ? ORDER BY backend_start, pid',
      undef, $marker,
    );
    is_deeply [ map { [ ($_->[0] =~ /^LISTEN\b/i ? 'listen' : 'pool'), $_->[1] ] } @$backends ],
      [ [ pool => $DATABASE ], [ listen => $DATABASE ] ],
      'the listen connection is a second backend of that role with that application_name: '
    . 'opened from the string too';

    hang_up($schema);
  };
}

subtest 'b) the broker rotates to another role while the pool holds a connection' => sub {
  my $marker = "${TAG}_rotation";
  my ($broker, $schema) = connect_with(keyword_value_string(a => $marker));
  my $storage = $schema->storage;

  is_deeply [ map { $_->[0] } logins($storage, 1) ], [ $ROLE{a}{name} ],
    'before the rotation the pool connection is logged in as the first role';

  # The pool connection is idle again once the reset of that call is answered
  # (karr k99); the claim below is about an idle one in the pool.
  PoolReset->until_reset($storage->async);
  $broker->{string} = keyword_value_string(b => $marker);

  # Two at once: the connection the pool has takes one, and for the other the
  # pool opens a second -- asking the broker.
  is_deeply [ sort map { $_->[0] } logins($storage, 2) ], [ $ROLE{a}{name}, $ROLE{b}{name} ],
    'after it, of two statements at once one is answered by a connection logged in as the new role '
  . '-- the broker was asked again for it -- and one by the connection of the old role, still in the pool';

  hang_up($schema);
};

$view->disconnect;

done_testing;
