use strict;
use warnings;
use Test::More;

# LIVE test for core karr k407: a pooled call that waits for the pool returns
# the Future of a `$pool->acquire->then(...)` sequence, which Future.pm holds
# only weakly from the acquire Future still waiting. A caller that lets go of
# it while the pool is full lost the chain: "lost a sequence Future", the body
# never ran, the connection it would have borrowed never came back.
#
# A pool of ONE, busy with SELECT SLEEP(0.3). A query and an insert_async are
# started behind it and their Futures dropped. When the connection is free:
# both have run (the row is in the table), nothing is warned, and a third call
# gets the connection. The loop is bounded by a timer, never waited on for good.
#
# The table lives in a database of its own, mysql_ev_k407, created here and
# dropped at the end.

use DBI;
use DBIO::MySQL::EV::TestHarness;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

use EV;

alarm 120;

my $DB = 'mysql_ev_k407';
my ($DSN, $USER, $PASS) = map { $ENV{"DBIO_TEST_MYSQL_$_"} } qw( DSN USER PASS );

(my $own = $DSN) =~ s/(?<=[:;])(?:database|dbname|db)=[^;]*/database=$DB/
  or plan skip_all => 'DBIO_TEST_MYSQL_DSN names no database';

sub connect_sync {
  my ($dsn) = @_;
  return DBI->connect($dsn, $USER, $PASS, { RaiseError => 1, PrintError => 0, PrintWarn => 0 });
}

my $CREATED;
{
  my $dbh = connect_sync($DSN);
  $dbh->do("DROP DATABASE IF EXISTS $DB");
  $dbh->do("CREATE DATABASE $DB");
  $CREATED = 1;
  $dbh->disconnect;
}
END {
  return unless $CREATED;
  my $dbh = eval { connect_sync($DSN) } or return;
  eval { $dbh->do("DROP DATABASE IF EXISTS $DB") };
  $dbh->disconnect;
}
my $check = connect_sync($own);
$check->do('CREATE TABLE retain_thing (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64) NOT NULL)');

{
  package K407::Live::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('retain_thing');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 64 },
  );
  __PACKAGE__->set_primary_key('id');

  package K407::Live::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
  __PACKAGE__->register_class(Thing => 'K407::Live::Thing');
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my $h = DBIO::MySQL::EV::TestHarness->new(
  schema_class  => 'K407::Live::Schema',
  dsn           => $own, user => $USER, pass => $PASS,
  connect_attrs => { pool_size => 1 },
);
$h->warm_pool;
END { eval { $h->disconnect } if $h }

my $async  = $h->async;
my $source = $h->schema->source('Thing');

# Run the loop until $cond is true; the timer is the upper bound, never a hang.
sub wait_for {
  my ($cond, $secs) = @_;
  my $over = 0;
  EV::now_update();
  my $dog = EV::timer($secs // 10, 0, sub { $over = 1 });
  my $tick = EV::timer(0.02, 0.02, sub {});   # RUN_ONCE never blocks for long
  EV::run(EV::RUN_ONCE()) until $cond->() || $over;
  return $cond->() ? 1 : 0;
}

my $busy = $async->_query_async('SELECT SLEEP(0.3)', []);
ok !$busy->is_ready, 'the only connection is busy';

# Two calls queue behind it; their Futures are let go.
$async->_query_async('SELECT 2', []);
$async->insert_async($source, { name => 'dropped' });

ok wait_for(sub { $busy->is_ready }), 'the busy statement ends';

# Kept: it gets the connection only if the dropped ones gave it back.
my $third = $async->_query_async('SELECT 3', []);
ok wait_for(sub { $third->is_ready }), 'the third call gets the connection'
  or diag 'the connection was never released';
is_deeply [ $third->is_done ? $third->get : () ], [[3]], '... and its rows' if $third->is_ready;

is $check->selectrow_array('SELECT COUNT(*) FROM retain_thing WHERE name = ?', undef, 'dropped'), 1,
  'the dropped insert ran';
is_deeply [ grep { /lost a sequence/i } @warnings ], [], 'no "lost a sequence Future"';
is_deeply \@warnings, [], 'nothing is warned';

done_testing;
