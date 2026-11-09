use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Test::Storage;
use DBIO::Storage::DBI;
use DBIO::Storage::Statistics;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::QueryExecutor;

# OFFLINE test for core karr k402 / k404 (core ADR 0025): the statement trace
# of this transport is the core's -- DBIO::Storage::Async::_debug_query,
# called by the Storage once per statement, with the bind attributes the
# statement was built with. The transport traces nothing of its own: the
# QueryExecutor is no storage, and no warn goes to STDERR.
#
# The one substitution is the QueryExecutor (T61::Executor), which answers from
# the SQL text; the Storage, the SQLMaker and the owner's trace are real.

{
  package T61::Schema::Result::User;
  use base 'DBIO::Core';
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    name     => { data_type => 'varchar', size => 64, is_nullable => 1 },
    password => { data_type => 'varchar', size => 255, is_nullable => 1, encode_column => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T61::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(User => 'T61::Schema::Result::User');
}

{
  package T61::Stats;
  our @ISA = ('DBIO::Storage::Statistics');
  our (@started, @ended);
  sub query_start { my $s = shift; push @started, [@_]; $s->SUPER::query_start(@_) }
  sub query_end   { my $s = shift; push @ended,   [@_]; $s->SUPER::query_end(@_) }
}

{
  package T61::Executor;
  our @calls;
  our $PENDING;   # the Future handed out for the statement named FLIGHT
  sub new { bless {}, $_[0] }
  sub execute {
    my ($self, $mdb, $sql, $bind) = @_;
    push @calls, { sql => $sql, bind => [ @{ $bind || [] } ] };
    return Future->fail('boom') if $sql =~ /FAIL/;
    return $PENDING = Future->new if $sql =~ /FLIGHT/;
    return Future->done([ 7 ]) if $sql =~ /LAST_INSERT_ID/;
    return Future->done(1);
  }
  # the queueing entries run the statement through execute, as the real ones do
  sub execute_when_idle { my ($self, $mdb, $sql, $bind) = @_; $self->execute($mdb, $sql, $bind) }
}

T61::Schema->storage_type('+DBIO::Test::Storage');
my $schema = T61::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
my $owner = $schema->storage;

my $out = '';
open my $fh, '>', \$out or die;
my $stats = T61::Stats->new;
$stats->debugfh($fh);
$owner->debugobj($stats);

my $storage = DBIO::MySQL::EV::Storage->new(undef);
$storage->{executor} = T61::Executor->new;
$storage->_owner_storage($owner);
$owner->_async_context_owner_token($storage->_context_owner_token);

my $CONN   = bless {}, 'FakeConn';
my $source = $schema->source('User');

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

sub reset_trace {
  $out = '';
  @T61::Stats::started = @T61::Stats::ended = ();
  @T61::Executor::calls = ();
}

# --- the executor has no trace of its own ------------------------------------

ok !DBIO::MySQL::EV::QueryExecutor->can('_debug_query'),
  'the QueryExecutor has no _debug_query: it is no storage';
ok !exists DBIO::MySQL::EV::QueryExecutor->new(debug => 2)->{debug},
  'the QueryExecutor keeps no debug level';

# --- level 2: encode_column shows ***, wire binds stay bare ------------------

{
  reset_trace();
  $storage->{debug} = 2;
  my $f = $storage->_run_crud_pinned(
    'insert', $CONN, $source, { name => 'alice', password => 'hunter2-secret' });
  ok $f->is_ready, 'the insert settled';

  like $out, qr/INSERT INTO/, 'level 2: the statement is traced';
  like $out, qr/'alice'/, 'level 2: a plain column value is traced';
  like $out, qr/'\*\*\*'/, 'level 2: the bind of an encode_column column shows ***';
  unlike $out, qr/hunter2/, 'level 2: the encoded value is not traced';
  is_deeply $T61::Executor::calls[0]{bind}, [ 'alice', 'hunter2-secret' ],
    'the wire binds are bare values';

  is scalar(@T61::Stats::started), 2, 'INSERT and LAST_INSERT_ID() are traced, once each';
  is $T61::Stats::started[1][0], 'SELECT LAST_INSERT_ID()', 'the LAST_INSERT_ID() read is traced';
  is scalar(@T61::Stats::ended), 2, 'query_end ran for both';
  is_deeply [ map { $_->[0] } @T61::Stats::ended ],
    [ map { $_->[0] } @T61::Stats::started ], 'query_end names the statement of its query_start';
}

# --- a hook of the owner sees the column name --------------------------------

{
  my $old = DBIO::Storage::DBI->redact_bind_value;
  my @asked;
  DBIO::Storage::DBI->redact_bind_value(sub { push @asked, [@_]; $_[1] });
  reset_trace();
  $storage->_run_crud_pinned('delete', $CONN, $source, { name => 'bob' });
  DBIO::Storage::DBI->redact_bind_value($old);
  is scalar(@asked), 1, 'the hook is asked once per bind';
  is $asked[0][0], 'name', 'the hook sees the column name';
  is $asked[0][1], 'bob', 'the hook sees the value';
  is $asked[0][2]{dbic_colname}, 'name', 'the hook sees the attribute hash';
}

# --- level 1: no binds --------------------------------------------------------

{
  reset_trace();
  $storage->{debug} = 1;
  $storage->_run_crud_pinned('delete', $CONN, $source, { name => 'secretname' });
  like $out, qr/DELETE FROM/, 'level 1: the statement is traced';
  unlike $out, qr/secretname/, 'level 1: no bind value';
  is scalar(@T61::Stats::ended), 1, 'level 1: query_end ran';
}

# --- level 0: nothing ---------------------------------------------------------

{
  reset_trace();
  $storage->{debug} = 0;
  $storage->_run_crud_pinned('delete', $CONN, $source, { name => 'x' });
  is $out, '', 'level 0: nothing traced';
  is scalar(@T61::Stats::ended), 0, 'level 0: no query_end';
}

# --- raw statements: BEGIN / COMMIT / ROLLBACK, undef name and attributes ----

{
  my $old = DBIO::Storage::DBI->redact_bind_value;
  my @asked;
  DBIO::Storage::DBI->redact_bind_value(sub { push @asked, [@_]; $_[1] });
  reset_trace();
  $storage->{debug} = 2;
  $storage->_query_async_pinned($CONN, 'BEGIN', []);
  $storage->_query_async_pinned($CONN, 'SELECT ?', ['raw-value']);
  $storage->_query_async_pinned($CONN, 'COMMIT', []);
  $storage->_query_async_pinned($CONN, 'ROLLBACK', []);
  DBIO::Storage::DBI->redact_bind_value($old);

  is_deeply [ map { $_->[0] } @T61::Stats::started ],
    [ 'BEGIN', 'SELECT ?', 'COMMIT', 'ROLLBACK' ],
    'BEGIN, a raw SELECT, COMMIT and ROLLBACK are each traced once';
  is_deeply \@asked, [[ undef, 'raw-value', undef ]],
    'a raw statement: the hook gets undef for name and attributes';
  is scalar(@T61::Stats::ended), 4, 'query_end for each of them';
}

# --- query_end on failure, and only when the statement is over ---------------

{
  reset_trace();
  $storage->{debug} = 1;
  my $f = $storage->_query_async_pinned($CONN, 'SELECT FAIL', []);
  ok $f->is_failed, 'the statement failed';
  is_deeply \@T61::Stats::ended, [[ 'SELECT FAIL' ]], 'query_end ran for the failed statement';

  reset_trace();
  my $g = $storage->_query_async_pinned($CONN, 'SELECT FLIGHT', []);
  is scalar(@T61::Stats::started), 1, 'query_start at dispatch';
  is scalar(@T61::Stats::ended), 0, 'no query_end while the statement is in flight';
  $T61::Executor::PENDING->done(1);
  is scalar(@T61::Stats::ended), 1, 'query_end when its Future is ready';
}

# --- a select with the bind attribute (core k404) ----------------------------

{
  reset_trace();
  $storage->{debug} = 2;
  my $ra = $schema->resultset('User')->search(
    { 'me.id' => 5, -and => [ \'me.name = ?' ] },
    { bind => [ 'zed' ] },
  )->_resolved_attrs;
  my $f = $storage->_run_crud('select', $storage->_pinned_runner($CONN),
    $ra->{from}, $ra->{select}, $ra->{where}, $ra);
  ok $f->is_ready, 'the select settled';
  is_deeply $T61::Executor::calls[0]{bind}, [ 'zed', 5 ],
    'the bind attribute values stand in front of the select binds, bare';
  like $out, qr/'zed'.*'5'/s, 'level 2: both are traced';
}

is_deeply \@warnings, [], 'nothing was warned: no trace on STDERR';

done_testing;
