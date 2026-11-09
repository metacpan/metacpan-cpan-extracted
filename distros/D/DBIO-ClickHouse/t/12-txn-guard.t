use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

# t/12-txn-guard.t — the ClickHouse scope guard (ADR 0003, addendum).
#
# $storage->txn_scope_guard hands out DBIO::ClickHouse::Storage::TxnScopeGuard:
# core's guard with DESTROY replaced by one that carps instead of rolling back.
# The sibling file t/12-txn.t covers txn_do / txn_begin / txn_commit /
# txn_rollback; this one covers the guard, because a guard is mostly NOT
# something the caller wrote -- core takes one on your behalf in delete_all,
# update_all, multi-create, cascade delete and related-data populate.
#
# Two levels, deliberately:
#
#   1. The guard poked directly, where the nesting depth is known exactly and
#      warning counts can be asserted to the number.
#   2. The same guard reached through a REAL core path (delete_all, update_all,
#      $rs->create with related rows) on a storage whose _execute only records.
#      Only that proves core's own guard sites behave, which is the entire
#      reason this class exists -- (1) alone would pass even if core never
#      routed through our txn_scope_guard at all.
#
# Entirely offline: no DBI, no DSN, no server. Nothing here connects.

use DBIO::ClickHouse::Storage;
use DBIO::ClickHouse::Storage::TxnScopeGuard;

# --- a storage that renders but never executes ------------------------------
{
  package MyTest::CH::GuardRecorder;
  use strict;
  use warnings;
  use base 'DBIO::ClickHouse::Storage';
  use mro 'c3';

  our @LOG;
  our $FAIL_ON;     # statement number that should blow up
  our $FAIL_WITH;   # 'exception' (default) or 'string'
  our $N = 0;

  sub new {
    my $self = shift->next::method(@_);
    # Nothing to detect (the concrete driver was instantiated directly), so
    # short-circuit core's determine-driver wrapper and hand the sql_maker the
    # quoting it would otherwise pick up from the connection.
    $self->{_driver_determined} = 1;
    $self->{_sql_maker_opts} = { quote_char => '`', name_sep => '.' };
    # The guard weakrefs $storage->_dbh and returns early without one, so the
    # DESTROY under test would never run. Two-line stand-in: core only FETCHes
    # attributes on this path, and both are true for a ClickHouse connection.
    $self->_dbh(bless {}, 'MyTest::CH::GuardDBH');
    $self->_dbh_autocommit(1);
    return $self;
  }

  sub _execute {
    my ($self, $op, $ident, @args) = @_;
    my ($sql) = $self->_prep_for_execute($op, $ident, \@args);
    $N++;
    push @LOG, $sql;
    if (defined $FAIL_ON and $N == $FAIL_ON) {
      die "plain string boom\n" if ($FAIL_WITH // '') eq 'string';
      $self->throw_exception("engine refused statement $N");
    }
    return 1;
  }

  # Every SELECT is empty. Cascade delete searches related rows before it can
  # do anything, and without this the cursor would try to reach a real sth.
  sub select        { return MyTest::CH::GuardCursor->new }
  sub select_single { return () }

  sub _populate_dbh    { }
  sub connected        { 1 }
  sub _seems_connected { 1 }
}
{
  package MyTest::CH::GuardDBH;
  sub FETCH { 1 }
}
{
  package MyTest::CH::GuardCursor;
  sub new   { bless {}, shift }
  sub reset { }
  sub next  { return () }
  sub all   { return () }
}

# --- schema: a cascading has_many, so the real paths nest guards ------------
{
  package My::CH::Guard::Result::Artist;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uuid', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 100, is_nullable => 0 }
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(cds => 'My::CH::Guard::Result::CD', 'artistid');
}
{
  package My::CH::Guard::Result::CD;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->table('cd');
  __PACKAGE__->add_columns(
    id       => { data_type => 'uuid', is_auto_increment => 1, is_nullable => 0 },
    artistid => { data_type => 'uuid', is_nullable => 0 },
    title    => { data_type => 'varchar', size => 100, is_nullable => 0 }
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(artist => 'My::CH::Guard::Result::Artist', 'artistid');
}
{
  package My::CH::Guard::Schema;
  use strict;
  use warnings;
  use base 'DBIO::Schema';

  __PACKAGE__->load_components('ClickHouse');
  __PACKAGE__->register_class(Artist => 'My::CH::Guard::Result::Artist');
  __PACKAGE__->register_class(CD     => 'My::CH::Guard::Result::CD');
}

sub fresh_schema {
  my $schema = My::CH::Guard::Schema->connect(sub { });
  $schema->storage(MyTest::CH::GuardRecorder->new($schema));
  @MyTest::CH::GuardRecorder::LOG    = ();
  $MyTest::CH::GuardRecorder::N         = 0;
  $MyTest::CH::GuardRecorder::FAIL_ON   = undef;
  $MyTest::CH::GuardRecorder::FAIL_WITH = undef;
  return $schema;
}

# A resultset whose ->all is a fixed set of in-storage rows. delete_all and
# update_all walk exactly that list, which is what puts their guard in play
# without needing a server to read rows back from.
sub cached_rs {
  my ($schema, @names) = @_;
  my $rs = $schema->resultset('Artist');
  $rs->set_cache([ map {
    my $row = $schema->resultset('Artist')->new_result({ id => "u-$_", name => $_ });
    $row->in_storage(1);
    $row;
  } @names ]);
  return $rs;
}

# The txn_begin no-op warns once per interpreter (carp_once) and is emitted by
# whichever guard happens to run first, so warnings are always partitioned by
# what they say rather than merely counted.
sub unwind_warnings {
  return grep { /NOTHING WAS ROLLED BACK/ } @_;
}

# A real DBIO::Exception, made the way the storage makes them.
sub an_exception {
  my ($storage, $msg) = @_;
  local $@;
  eval { $storage->throw_exception($msg) };
  return $@;
}

#############################################################################
# 1. The guard itself
#############################################################################

# What core gets when it asks for a guard. If this ever regresses to the base
# class, every assertion below still passes on the happy path and silently
# stops testing anything on the failure path.
{
  my $schema = fresh_schema();
  local $SIG{__WARN__} = sub { };

  my $guard = $schema->storage->txn_scope_guard;
  isa_ok $guard, 'DBIO::ClickHouse::Storage::TxnScopeGuard',
    'the storage hands out the ClickHouse guard';
  isa_ok $guard, 'DBIO::Storage::TxnScopeGuard',
    '... which is still a core guard (only DESTROY differs)';
  $guard->commit;

  isa_ok $schema->txn_scope_guard, 'DBIO::ClickHouse::Storage::TxnScopeGuard',
    'the schema-level shortcut routes to the same class';
}

# The happy path has to stay silent, or every delete_all in the application
# would warn about a guard that did exactly what it was told.
{
  my $schema = fresh_schema();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  {
    my $guard = $schema->storage->txn_scope_guard;
    is $schema->storage->transaction_depth, 1,
      'taking a guard bumps transaction_depth (core bookkeeping is intact)';
    $guard->commit;
  }

  is $schema->storage->transaction_depth, 0,
    'committing the guard unwinds the depth again';
  is scalar(unwind_warnings(@warnings)), 0,
    'a guard that reaches ->commit says nothing';
}

# The whole point of the class: leaving scope uncommitted must not throw.
{
  my $schema = fresh_schema();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my $lived = eval { { my $guard = $schema->storage->txn_scope_guard; } 1 };

  ok $lived, 'a guard leaving scope without commit does not die';
  is $schema->storage->transaction_depth, 0,
    '... and unwinds the depth, so the storage is not stuck in a transaction';

  my @unwind = unwind_warnings(@warnings);
  is scalar(@unwind), 1, '... carping exactly once';
  like $unwind[0], qr/NOTHING WAS ROLLED BACK/,
    '... that nothing was rolled back';
  like $unwind[0], qr/permanent/,
    '... and that the completed statements are permanent';
}

# Not carp_once: each unwind is a separate scope with its own partial write,
# the same reason a failing txn_do warns every time.
{
  my $schema = fresh_schema();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  { my $guard = $schema->storage->txn_scope_guard; }
  { my $guard = $schema->storage->txn_scope_guard; }

  is scalar(unwind_warnings(@warnings)), 2,
    'the unwind warning repeats -- every guard is its own incident';
}

# The regression this class exists for. Core's DESTROY mutates a DBIO::Exception
# IN PLACE, so refaddr alone would not notice: the message is the assertion.
{
  my $schema    = fresh_schema();
  my $storage   = $schema->storage;
  my $exception = an_exception($storage, 'engine said no');
  my $original  = "$exception";
  local $SIG{__WARN__} = sub { };

  isa_ok $exception, 'DBIO::Exception', 'the exception under test';

  eval {
    my $guard = $storage->txn_scope_guard;
    die $exception;
  };
  my $err = $@;

  is refaddr($err), refaddr($exception),
    'the very same exception object unwinds past the guard';
  is "$err", $original,
    '... with its message byte-identical -- the guard did not rewrite it';
  unlike "$err", qr/Transaction aborted/,
    '... no "Transaction aborted:" prefix';
  unlike "$err", qr/Rollback failed/,
    '... and no failed-rollback report bolted on';
  is $storage->transaction_depth, 0, '... and the depth is unwound';
}

# Nesting is where the old behaviour hurt most: core prepended once per guard
# on the stack, so three nested guards meant three prefixes in front of the
# real cause.
{
  my $schema    = fresh_schema();
  my $storage   = $schema->storage;
  my $exception = an_exception($storage, 'engine said no');
  my $original  = "$exception";
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  eval {
    my $outer  = $storage->txn_scope_guard;
    my $middle = $storage->txn_scope_guard;
    my $inner  = $storage->txn_scope_guard;
    die $exception;
  };

  is "$@", $original,
    'three nested guards still leave the exception exactly as thrown';
  is scalar(unwind_warnings(@warnings)), 3,
    '... each of them saying, once, that nothing was rolled back';
  is $storage->transaction_depth, 0,
    '... and the depth is back to 0, not stuck at 2';
}

# A plain string was already safe (perl's die propagation overwrote core's $@
# rewrite); pin it so the new DESTROY cannot regress it.
{
  my $schema = fresh_schema();
  local $SIG{__WARN__} = sub { };

  eval {
    my $guard = $schema->storage->txn_scope_guard;
    die "plain string boom\n";
  };

  is $@, "plain string boom\n",
    'a plain string exception unwinds byte-identical too';
}

# The one guard method that must NOT be a no-op: an explicit rollback is the
# caller stating that work was undone, exactly like $schema->txn_rollback.
{
  my $schema = fresh_schema();
  local $SIG{__WARN__} = sub { };

  my $guard = $schema->storage->txn_scope_guard;
  eval { $guard->rollback };
  my $err = $@;

  ok $err, '$guard->rollback throws rather than quietly accepting the rollback';
  isa_ok $err, 'DBIO::Exception';
  like $err, qr/txn_rollback\(\) cannot undo anything/,
    '... routing to the storage txn_rollback, which names the reason';
  is $schema->storage->transaction_depth, 0,
    '... and the depth is unwound, so the storage stays usable';
}

#############################################################################
# 2. The guard as core actually takes it
#############################################################################

# delete_all is the canonical internal guard user: one guard, then a mutation
# per row. Nothing about it may change on the happy path.
{
  my $schema = fresh_schema();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  cached_rs($schema, 'a', 'b')->delete_all({ all => 1 });

  is scalar(@MyTest::CH::GuardRecorder::LOG), 2,
    'delete_all issues one mutation per row';
  like $MyTest::CH::GuardRecorder::LOG[0], qr/^ALTER TABLE `artist` DELETE/,
    '... as an ALTER TABLE ... DELETE';
  is scalar(unwind_warnings(@warnings)), 0,
    '... and its guard commits, so nothing warns';
  is $schema->storage->transaction_depth, 0, '... depth back to 0';
}

# The path the ticket is about: a real core guard unwinding on a real failure.
# Before this class the caller got the engine error behind two "Transaction
# aborted:" prefixes plus a paragraph about a rollback that never had a chance.
{
  my $schema = fresh_schema();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $MyTest::CH::GuardRecorder::FAIL_ON = 2;

  eval { cached_rs($schema, 'a', 'b')->delete_all({ all => 1 }) };
  my $err = $@;

  isa_ok $err, 'DBIO::Exception', 'delete_all rethrows the engine failure';
  like $err, qr/engine refused statement 2/,
    '... naming the statement that actually failed';
  unlike $err, qr/Transaction aborted/,
    '... with no "Transaction aborted:" prefix from a guard';
  unlike $err, qr/Rollback failed/,
    '... and no failed-rollback report';

  ok scalar(unwind_warnings(@warnings)) >= 1,
    'the unwinding guard still says out loud that nothing was rolled back';
  is $schema->storage->transaction_depth, 0,
    'the storage is left usable, not stuck inside a phantom transaction';

  # ... and the first row really is gone. That is the price of (b), stated as
  # a test rather than only in the ADR.
  is scalar(@MyTest::CH::GuardRecorder::LOG), 2,
    'the mutation that succeeded before the failure was issued and stands';
}

# The second ResultSet-level guard site, same contract.
{
  my $schema = fresh_schema();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $MyTest::CH::GuardRecorder::FAIL_ON = 2;

  eval { cached_rs($schema, 'a', 'b')->update_all({ name => 'x' }, { all => 1 }) };

  like $@, qr/engine refused statement 2/,
    'update_all rethrows the engine failure unchanged';
  unlike $@, qr/Transaction aborted|Rollback failed/,
    '... undecorated by its guard';
  is $schema->storage->transaction_depth, 0, '... and the depth is unwound';
}

# The Row-level guard site (Row::insert, multi-create) is a different piece of
# core, so it gets its own case.
{
  my $schema = fresh_schema();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  $schema->resultset('Artist')
         ->create({ name => 'a', cds => [ { title => 't1' }, { title => 't2' } ] });

  is scalar(@MyTest::CH::GuardRecorder::LOG), 3,
    'multi-create inserts the parent and both children';
  is scalar(unwind_warnings(@warnings)), 0,
    '... under a guard that commits, so nothing warns';
  is $schema->storage->transaction_depth, 0, '... depth back to 0';
}

{
  my $schema = fresh_schema();
  local $SIG{__WARN__} = sub { };
  $MyTest::CH::GuardRecorder::FAIL_ON = 2;

  eval {
    $schema->resultset('Artist')
           ->create({ name => 'a', cds => [ { title => 't1' }, { title => 't2' } ] });
  };

  like $@, qr/engine refused statement 2/,
    'a failing multi-create rethrows the engine failure';
  unlike $@, qr/Transaction aborted|Rollback failed/,
    '... undecorated by Row::insert\'s guard';
  is $schema->storage->transaction_depth, 0, '... and the depth is unwound';
  is scalar(@MyTest::CH::GuardRecorder::LOG), 2,
    'the parent row it already inserted stays inserted -- nothing undid it';
}

# The boundary: a void populate of plain column data collapses to one
# multi-row INSERT and takes no guard at all (see Storage/_insert_bulk).
# t/13-insert.t pins the missing transaction warning; this pins that no guard
# unwinds either, which is the assertion this file owns.
{
  my $schema = fresh_schema();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $MyTest::CH::GuardRecorder::FAIL_ON = 1;

  eval { $schema->resultset('Artist')->populate([ { name => 'a' }, { name => 'b' } ]) };

  like $@, qr/engine refused statement 1/,
    'a failing bulk insert reports the engine failure';
  is scalar(unwind_warnings(@warnings)), 0,
    '... and no guard unwinds, because the bulk path never took one';
  is $schema->storage->transaction_depth, 0, 'depth was never raised';
}

done_testing;
