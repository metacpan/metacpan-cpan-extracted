use strict;
use warnings;
use Test::More;

# LIVE, karr k88 (core k325, k282): the ORM layer on this transport. Core binds
# a ResultSet, a Row or a ResultSetColumn to the context txn_do_async hands its
# coderef (with_context), and a bound object's *_async run on the transaction's
# pinned connection. Core k282 made an insert of a row that carries an inflated
# value (an object for a column with an inflator) the ONE INSERT it is instead
# of refusing it, deflated as the synchronous insert deflates it; core k325
# made what a bound row or resultset hands out keep the binding.
#
# Core tests these against a fake backend. Claimed here, against a server:
#
#   - a row carrying an inflated value, bound with with_context, is written by
#     insert_async inside the transaction, on the pinned connection: the value
#     is stored deflated, the row that comes back holds the inflated object,
#     and what a bound resultset reads back is inflated;
#   - nothing of it is visible to another session before COMMIT, and it is
#     gone after a ROLLBACK, with a pool that could have served the statement
#     from another connection (pool_size 2);
#   - a bound update_async with an inflated value is deflated on the wire;
#   - a statement that fails rolls the transaction back and nothing warns;
#   - a bound object held past the transaction is refused;
#   - the connection is back in the pool, idle, with no transaction open.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use EV::Pg;
use FindBin;
use lib "$FindBin::Bin/lib";
use PoolReset;
use LiveServer;
use GuardedWait;
LiveServer->require_server;

alarm 120;

my $table = "dbio_k88_ctx_$$";

{
  package Test::K88::Tag;
  sub new   { bless { value => $_[1] }, $_[0] }
  sub value { $_[0]{value} }
}
{
  package Test::K88::Schema::Result::Note;
  use base 'DBIO::Core';
  __PACKAGE__->table($table);
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    body => { data_type => 'text' },
    tag  => { data_type => 'text', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->inflate_column(tag => {
    inflate => sub { Test::K88::Tag->new($_[0] =~ s/^tag://r) },
    deflate => sub { 'tag:' . $_[0]->value },
  });

  package Test::K88::Schema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->register_class(Note => 'Test::K88::Schema::Result::Note');
}

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $h = DBIO::PostgreSQL::EV::TestHarness->new(
  schema_class  => 'Test::K88::Schema',
  connect_attrs => { pool_size => 2 },
);
my $schema = $h->schema;
my $async  = $h->async;
my $obs    = LiveServer->control_dbh(attrs => { AutoInactiveDestroy => 1 });

END { eval { $obs->do("DROP TABLE IF EXISTS $table") } if $obs }

$obs->do("CREATE TABLE $table (id serial PRIMARY KEY, body text NOT NULL, tag text)");

sub guarded { GuardedWait->until_ready($_[0], 8, $_[1]) }
sub stored  { $obs->selectall_arrayref("SELECT body, tag FROM $table ORDER BY id") }

my $notes = $schema->resultset('Note');

# --- commit: bound row and bound resultset, inflated value ----------------------

my (%seen, $ctx_held, $bound_rs_held, $pg);

my $txn = $async->txn_do_async(sub {
  my ($ctx) = @_;
  $ctx_held = $ctx;
  $pg       = $ctx->txn_conn;
  my $rs    = $notes->with_context($ctx);
  $bound_rs_held = $rs;

  my $row = $rs->new_result({ body => 'one', tag => Test::K88::Tag->new('red') });
  isa_ok $row->_async_context, ref($ctx), 'a row built from the bound resultset carries the context';

  return $row->insert_async->then(sub {
    my ($r) = @_;
    $seen{inserted} = $r;
    $seen{outside_before_commit} = stored();
    # a row bound by hand
    my $by_hand = $notes->new_result({ body => 'two', tag => Test::K88::Tag->new('blue') })
      ->with_context($ctx);
    return $by_hand->insert_async;
  })->then(sub {
    $seen{by_hand} = $_[0];
    return $rs->search({ body => 'one' })->all_async;
  })->then(sub {
    $seen{read_back} = [ @_ ];
    my ($r) = @{ $seen{read_back} };
    $seen{read_back_value} = $r->tag->value;
    $r->tag(Test::K88::Tag->new('green'));
    return $r->update_async;
  })->then(sub {
    $seen{updated_outside} = stored();
    return $rs->search({ body => 'one' })->all_async;
  })->then(sub {
    $seen{after_update} = [ @_ ];
    return $async->future_class->done('ok');
  });
});

my $f = guarded($txn, 'the committing transaction is still pending after 8s');
ok $f->is_done, 'the transaction commits' or diag +($f->failure)[0];

isa_ok $seen{inserted}, 'Test::K88::Schema::Result::Note', 'insert_async resolves with the row';
ok $seen{inserted}->id, 'the row holds the key the server gave it';
isa_ok $seen{inserted}->tag, 'Test::K88::Tag', 'the inserted row holds the inflated object';
is $seen{inserted}->tag->value, 'red', 'with its value';
is_deeply $seen{outside_before_commit}, [], 'another session sees nothing before COMMIT (the pinned connection)';
isa_ok $seen{by_hand}->tag, 'Test::K88::Tag', 'a row bound by hand with an inflated value inserts too';
is scalar @{ $seen{read_back} }, 1, 'a bound resultset reads the row back inside the transaction';
isa_ok $seen{read_back}[0]->tag, 'Test::K88::Tag', 'the value read back is inflated';
is $seen{read_back_value}, 'red', 'and is the one written';
is_deeply $seen{updated_outside}, [], 'the bound update is invisible outside the transaction too';
is $seen{after_update}[0]->tag->value, 'green', 'the bound update_async wrote the new inflated value';
is_deeply stored(), [ [ one => 'tag:green' ], [ two => 'tag:blue' ] ],
  'after COMMIT the table holds the deflated values';
PoolReset->until_reset($h->async);   # idle once the reset of the borrow is answered (karr k99)
is $h->pool->available, $h->pool->size, 'every pool connection is idle again';
is $pg->transaction_status, EV::Pg::PQTRANS_IDLE(), 'the pinned connection has no transaction open';

# --- held past the transaction --------------------------------------------------

my $late = eval { $bound_rs_held->search({})->all_async; 1 };
ok !$late, 'a bound resultset held past the transaction is refused' or diag 'it ran';
like $@, qr/no longer active|not active/i, 'with the reason' or diag $@;
my $late_row = $notes->new_result({ body => 'late', tag => Test::K88::Tag->new('l') })
  ->with_context($ctx_held);
ok !eval { $late_row->insert_async; 1 }, 'a row bound to the finished context is refused at insert_async';
like $@, qr/no longer active|not active/i, 'with the reason' or diag $@;
is_deeply stored(), [ [ one => 'tag:green' ], [ two => 'tag:blue' ] ], 'and wrote nothing';

# --- rollback: the bound insert goes with the transaction -----------------------

$obs->do("DELETE FROM $table");
my $rb_pg;
my $dying = $async->txn_do_async(sub {
  my ($ctx) = @_;
  $rb_pg = $ctx->txn_conn;
  my $row = $notes->with_context($ctx)
    ->new_result({ body => 'gone', tag => Test::K88::Tag->new('x') });
  return $row->insert_async->then(sub {
    die "gave up\n";
  });
});
my $rf = guarded($dying, 'the rolling back transaction is still pending after 8s');
ok $rf->is_failed, 'a transaction whose coderef dies fails';
is +($rf->failure)[0], "gave up\n", 'with the coderef\'s error';
is_deeply stored(), [], 'the bound insert of an inflated value is rolled back';
PoolReset->until_reset($h->async);
is $h->pool->available, $h->pool->size, 'every pool connection is idle again after the rollback';
is $rb_pg->transaction_status, EV::Pg::PQTRANS_IDLE(), 'no transaction left open';

# --- a failing bound statement rolls the transaction back -----------------------

my $fail = $async->txn_do_async(sub {
  my ($ctx) = @_;
  my $rs = $notes->with_context($ctx);
  return $rs->new_result({ body => 'fine', tag => Test::K88::Tag->new('y') })->insert_async
    ->then(sub {
      # body is NOT NULL
      return $rs->new_result({ body => undef, tag => Test::K88::Tag->new('z') })->insert_async;
    });
});
my $ff = guarded($fail, 'the failing transaction is still pending after 8s');
ok $ff->is_failed, 'a bound insert the server refuses fails the transaction';
like +($ff->failure)[0], qr/null value|not-null|violates/i, 'with the server\'s error';
is_deeply stored(), [], 'the first, good bound insert is rolled back with it';

# the pool serves the next call
my @rows = guarded($notes->search({})->all_async, 'the call after the failure is still pending after 8s')->get;
is scalar @rows, 0, 'the pool serves the next call';
PoolReset->until_reset($h->async);
is $h->pool->available, $h->pool->size, 'every pool connection is idle again after the failure';
is_deeply \@warnings, [], 'nothing warned';

$h->disconnect;
$obs->disconnect;
done_testing;
