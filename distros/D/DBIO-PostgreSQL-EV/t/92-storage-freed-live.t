use strict;
use warnings;
use Test::More;

# LIVE, karr k88 (core ed0f33a0e): a storage that has run deploy_async, listen
# or copy_in is freed when its holder lets go of it -- the same claim core
# makes for its own backends after deploy_async, measured on this transport.
#
# Core found deploy_async chaining its runs through a sub that held itself, so
# every deploy left its backend, its pool and every open connection behind. The
# transport has its own chains (the LISTEN registry and its callbacks, the
# COPY writer, the pooled completions), so the same question is asked here.
# Measured against PostgreSQL 18.6 / EV::Pg 0.07: nothing is left, on any of
# the roads below -- this file holds that.
#
# For each of deploy_async, listen, copy_in, a copy_in the server refuses, and
# a plain query, with the caller either just letting go of the schema or
# calling disconnect first:
#   - the schema, its storage and the embedded async backend are all freed;
#   - no session of the connection is left on the server
#     (pg_stat_activity, told apart by application_name);
#   - no watcher is left on the EV loop: it returns on its own.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use Scalar::Util ();
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use GuardedWait;
LiveServer->require_server;

alarm 120;

package K88Free::Result::Thing {
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_k88_free_thing');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
}

package K88Free::Schema {
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Thing => 'K88Free::Result::Thing');
}

package main;

my ($dsn, $user, $pass) = LiveServer->login;
my $obs   = LiveServer->control_dbh(attrs => { AutoInactiveDestroy => 1 });
my $table = "dbio_k88_free_copy_$$";
$obs->do("CREATE TABLE $table (a int, b text)");

sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.3, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
}

# True when the loop returns by itself; a watcher left behind keeps it running
# until the (non-keepalive) timer ends it.
sub loop_is_dry {
  EV::now_update();
  my $fired = 0;
  my $t = EV::timer(2, 0, sub { $fired = 1 });
  $t->keepalive(0);
  EV::run();
  return !$fired;
}

sub sessions {
  my ($tag) = @_;
  my ($n) = $obs->selectrow_array(
    'SELECT count(*) FROM pg_stat_activity WHERE application_name = ?', undef, $tag);
  return $n;
}

my %ops = (
  'deploy_async'   => sub { my ($a, $s)      = @_; $a->deploy_async($s, { add_drop_table => 1 }) },
  'listen'         => sub { my ($a, $s, $tag) = @_; $a->listen("dbio_k88_$tag" => sub { }) },
  'copy_in'        => sub { my ($a) = @_;
                            $a->copy_in($table, [qw( a b )], sub { $_[0]->([ 1, 'x' ]) }) },
  'refused copy_in' => sub { my ($a) = @_;
                            $a->copy_in("${table}_missing", [qw( a b )], sub { $_[0]->([ 1, 'x' ]) }) },
  'query'          => sub { my ($a, $s) = @_; $s->resultset('Thing')->search({})->all_async },
);

my $n = 0;
for my $op ('deploy_async', 'listen', 'copy_in', 'refused copy_in', 'query') {
  for my $how (qw( let-go disconnect )) {
    my $label = "$op, $how";
    my $tag   = 'dbio_k88_free_' . $$ . '_' . ++$n;

    my $schema = K88Free::Schema->connect("$dsn;application_name=$tag", $user, $pass,
      { async => 'ev', pool_size => 2, AutoCommit => 1, RaiseError => 1 });
    my $async = $schema->storage->async;

    my $f = GuardedWait->until_ready(
      $ops{$op}->($async, $schema, $tag), 15, "$label: still pending after 15s");
    ok $f->is_ready, "$label: the call settled";
    undef $f;

    cmp_ok sessions($tag), '>=', 1, "$label: a session of its own is open (control)";

    $schema->storage->disconnect if $how eq 'disconnect';

    my @weak = ($schema, $schema->storage, $async);
    Scalar::Util::weaken($_) for @weak;
    undef $async;
    undef $schema;
    settle();

    ok !defined $weak[0], "$label: the schema is freed";
    ok !defined $weak[1], "$label: its storage is freed";
    ok !defined $weak[2], "$label: its async backend is freed";
    is sessions($tag), 0, "$label: no session is left on the server";
    ok loop_is_dry(), "$label: no watcher is left on the loop";
  }
}

$obs->do("DROP TABLE $table");
$obs->disconnect;
done_testing;
