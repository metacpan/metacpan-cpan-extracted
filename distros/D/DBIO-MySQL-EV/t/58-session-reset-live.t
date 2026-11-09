use strict;
use warnings;
use Test::More;

# LIVE test for karr k100 (core k398, ADR 0079): the session of a borrow is
# reset when the borrow ends, so the next borrow of the SAME connection sees
# none of what the first one left.
#
# A pool of one makes the connection the one every borrow gets; its
# CONNECTION_ID() is the proof it was reused. Inside one borrow the test sets a
# user variable, a session variable, a temporary table, a prepared statement, a
# GET_LOCK lock and an open transaction. The next borrow finds the session as a
# new connection has it -- including what the connect actions put there.
#
# Gated like the other live tests: DBIO_TEST_MYSQL_DSN (dbi:mysql: or
# dbi:MariaDB:), _USER, _PASS, plus EV and EV::MariaDB.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;

use EV;
use EV::MariaDB;

$SIG{ALRM} = sub { BAIL_OUT('t/58-session-reset-live.t: alarm, a wait did not end') };
alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package T58L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
}

my $TABLE = 'dbio_ev_reset_k100';
my $LOCK  = 'dbio_ev_reset_k100_lock';

my $h = DBIO::MySQL::EV::TestHarness->new(
  schema_class  => 'T58L::Schema',
  connect_attrs => {
    pool_size     => 1,
    on_connect_do => [ q{SET @dbio_connect_tag = 'from-connect-action'} ],
  },
);
my $async = $h->async;
my $pool  = $h->pool;

# One borrow: acquire, run the statements in order on the connection, release.
# Returns [ error-or-undef, rows ] per statement.
sub borrow {
  my (@statements) = @_;
  my $conn  = $h->await($pool->acquire);
  my $lease = $pool->_lease($conn);
  my @out;
  for my $sql (@statements) {
    my ($bind) = ref $sql ? @$sql[1] : ();
    my $text   = ref $sql ? $sql->[0] : $sql;
    my $f = $h->query_on($conn, $text, $bind || []);
    my @rows = eval { $h->await($f) };
    push @out, [ $@ ? "$@" : undef, \@rows ];
  }
  $pool->release($conn, $lease);
  return @out;
}

sub scalar_of { my ($r) = @_; return $r->[1][0] && $r->[1][0][0] }

# Cleanup of what the test creates, whatever happened before.
sub cleanup { borrow("DROP TABLE IF EXISTS $TABLE", "DO RELEASE_LOCK('$LOCK')") }
cleanup();
borrow("CREATE TABLE $TABLE (a INT) ENGINE=InnoDB");

my ($default_gcml) = scalar_of((borrow('SELECT @@session.group_concat_max_len'))[0]);
my $changed_gcml = $default_gcml + 77;

my ($first_id) = scalar_of((borrow('SELECT CONNECTION_ID()'))[0]);
ok $first_id, 'the connection has an id';

# --- the borrow that leaves state behind ---------------------------------------

my @set = borrow(
  q{SET @dbio_user_var = 'left behind'},
  "SET SESSION group_concat_max_len = $changed_gcml",
  'CREATE TEMPORARY TABLE dbio_ev_reset_tmp (a INT)',
  q{PREPARE dbio_ev_reset_ps FROM 'SELECT 1'},
  "SELECT GET_LOCK('$LOCK', 0)",
  'SET autocommit = 0',
  "INSERT INTO $TABLE (a) VALUES (1)",
  'SELECT @dbio_user_var, @@session.group_concat_max_len, CONNECTION_ID()',
);
is $_->[0], undef, 'a statement of the first borrow ran' for grep { defined $_->[0] } @set;
is scalar_of($set[4]), 1, 'GET_LOCK was taken';
is_deeply $set[7][1][0], [ 'left behind', $changed_gcml, $first_id ],
  'the first borrow sees its own state, on the same connection';

# --- the next borrow ---------------------------------------------------------------

my @next = borrow(
  'SELECT CONNECTION_ID()',
  'SELECT @dbio_user_var',
  'SELECT @@session.group_concat_max_len',
  'SELECT a FROM dbio_ev_reset_tmp',
  'EXECUTE dbio_ev_reset_ps',
  "SELECT IS_FREE_LOCK('$LOCK')",
  'SELECT @@session.autocommit',
  "SELECT COUNT(*) FROM $TABLE",
  'SELECT @dbio_connect_tag',
);

is scalar_of($next[0]), $first_id, 'the next borrow got the same connection';
ok !defined scalar_of($next[1]), 'the user variable is gone';
is scalar_of($next[2]), $default_gcml, 'the session variable is back at its default';
ok defined $next[3][0], 'the temporary table is gone';
ok defined $next[4][0], 'the prepared statement is gone';
is scalar_of($next[5]), 1, 'the GET_LOCK lock is released';
is scalar_of($next[6]), 1, 'autocommit is back on';
is scalar_of($next[7]), 0, 'the open transaction was rolled back';
is scalar_of($next[8]), 'from-connect-action', 'the connect actions are in effect again';

# --- what a new connection has, the reset connection has ---------------------------

my @charset = borrow('SELECT @@character_set_client, @@character_set_connection, @@character_set_results, @@sql_mode');
my @fresh;
{
  my $other = DBIO::MySQL::EV::TestHarness->new(schema_class => 'T58L::Schema', connect_attrs => { pool_size => 1 });
  my $p = $other->pool;
  my $c = $other->await($p->acquire);
  @fresh = $other->await($other->query_on($c, 'SELECT @@character_set_client, @@character_set_connection, @@character_set_results, @@sql_mode'));
  $p->release($c);
  eval { $other->disconnect };
}
is_deeply $charset[0][1][0], $fresh[0], 'character set and sql_mode are those of a new connection';

# --- character set and collation: every borrow has the session of the new connection --
#
# The transport reads character_set_client and collation_connection once per
# connection, after the connect actions, and sets both again after every reset.
# Two connections: one as the handshake leaves it, one whose connect action
# chose a collation that is not the server's default for its character set
# (utf8mb4_unicode_ci exists on MySQL and on MariaDB). The first borrow moves
# the session to latin1; the next borrow of the same connection (CONNECTION_ID
# equal) has what the first borrow found.
for my $variant (
  [ 'handshake' => [] ],
  [ 'connect action' => [ q{SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci} ] ],
) {
  my ($label, $do) = @$variant;
  my $names = DBIO::MySQL::EV::TestHarness->new(
    schema_class  => 'T58L::Schema',
    connect_attrs => { pool_size => 1, @$do ? (on_connect_do => $do) : () },
  );
  my $np = $names->pool;
  my $probe = 'SELECT @@character_set_client, @@collation_connection, CONNECTION_ID()';
  my $nborrow = sub {
    my (@sql) = @_;
    my $conn  = $names->await($np->acquire);
    my $lease = $np->_lease($conn);
    my @rows  = map { [ $names->await($names->query_on($conn, $_, [])) ] } @sql;
    $np->release($conn, $lease);
    return @rows;
  };

  my ($first, undef, $inside) = $nborrow->(
    $probe,
    'SET NAMES latin1 COLLATE latin1_german1_ci',
    $probe,
  );
  my ($second) = $nborrow->($probe);
  my ($third)  = $nborrow->($probe);

  is $inside->[0][1], q{latin1_german1_ci}, "$label: the first borrow moved the session to latin1";
  is $second->[0][2], $first->[0][2], "$label: the second borrow got the same connection";
  is_deeply [ @{ $second->[0] }[0, 1] ], [ @{ $first->[0] }[0, 1] ],
    "$label: the second borrow has the character set and collation of the first";
  is_deeply $third->[0], $second->[0], "$label: and so does the third";
  is_deeply [ @{ $first->[0] }[0, 1] ], [ 'utf8mb4', 'utf8mb4_unicode_ci' ],
    "$label: the connect action's collation is the one kept"
    if @$do;

  eval { $names->disconnect };
}

# found_rows (CLIENT_FOUND_ROWS) is a property of the handle, not of the session
{
  my @r = borrow("UPDATE $TABLE SET a = a WHERE 1 = 0", "INSERT INTO $TABLE (a) VALUES (5)", "UPDATE $TABLE SET a = 5 WHERE a = 5");
  is_deeply $r[2][1], [1], 'affected rows still count matched rows (CLIENT_FOUND_ROWS)';
}

is_deeply \@warnings, [], 'nothing warned';

cleanup();
eval { $h->disconnect };

done_testing;
