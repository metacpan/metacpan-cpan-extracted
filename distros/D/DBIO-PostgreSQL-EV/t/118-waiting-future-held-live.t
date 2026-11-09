use strict;
use warnings;
use Test::More;

# LIVE, core k407: a Future that waits for the pool and goes to a caller who
# drops it still runs, and its connection comes back.
#
# WHY: Future.pm holds a then-sequence only weakly from the Future it waits on.
# While the pool is full, the statement of _query_async is a then on the
# waiting acquire; a caller that does not keep the Future it got takes the
# chain with it -- "lost a sequence Future", the body never runs, and the
# borrowed connection is never given back. The seams that begin work on the
# pool (_query_async, _notify_send, copy_in, and the control-schema leg of
# deploy_async) hold their own sequence until it is ready.
#
# For each seam: a pool of one, its connection busy with a running statement,
# the seam called and its Future dropped, then
#   - STDERR (every warning) stays silent once the connection is free;
#   - the dropped call has run: the statement ran, the NOTIFY went out, the
#     rows are in the table;
#   - the next statement gets the connection, bounded by a timer, so a chain
#     that was taken away fails here and does not hang the file.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use GuardedWait;
LiveServer->require_server;

alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package K407::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_k407_thing');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');

  package K407::Schema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('plpgsql');
  __PACKAGE__->register_class(Thing => 'K407::Result::Thing');
}

my $table = "dbio_k407_copy_$$";
my $obs   = LiveServer->control_dbh;
$obs->do("DROP TABLE IF EXISTS $table");
$obs->do("CREATE TABLE $table (a int)");
END { eval { $obs->do("DROP TABLE IF EXISTS $table") } if $obs }

# The pool's one connection busy with a statement, then $seam->() called with
# the connection taken; its Future is not kept.
sub dropped {
  my ($name, $seam) = @_;
  @warnings = ();
  my $h = DBIO::PostgreSQL::EV::TestHarness->new(
    schema_class  => q{K407::Schema},
    connect_attrs => { pool_size => 1 },
  );
  my $a = $h->async;
  my $busy = $a->_query_async('SELECT pg_sleep(0.5)', []);
  is $a->pool->available, 0, "$name: the pool's one connection is busy";
  $seam->($a, $h);                     # return value dropped on the floor
  GuardedWait->until_ready($busy, 10, "$name: busy statement never ended");

  # The dropped call runs first when its chain is held; then ask again.
  my $next = $a->_query_async(q{SELECT 42}, []);
  eval { GuardedWait->until_ready($next, 5, "x"); 1 };
  ok $next->is_done, "$name: the next statement gets the connection";
  is_deeply [ grep { /lost a sequence|Future/i } @warnings ], [],
    "$name: no warning about a lost sequence" or diag explain \@warnings;
  is scalar(@warnings), 0, "$name: STDERR is silent" or diag explain \@warnings;
  eval { $h->disconnect };
}

dropped(_query_async => sub { my ($a, $h) = @_; $a->_query_async("SELECT 1 /* k407 */", []); return });

dropped(_notify_send => sub { my ($a, $h) = @_; $a->_notify_send("k407_$$", 'x'); return });

dropped(copy_in => sub {
  my ($a, $h) = @_;
  $a->copy_in($table, ['a'], sub { $_[0]->([ 7 ]) });
  return;
});
{
  my ($n) = $obs->selectrow_array("SELECT count(*) FROM $table");
  is $n, 1, 'copy_in: the dropped call ran, its row is in the table';
}

dropped(deploy_async => sub { my ($a, $h) = @_; $a->deploy_async($h->schema); return });

done_testing;
