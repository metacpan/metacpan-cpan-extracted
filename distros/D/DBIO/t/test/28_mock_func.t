use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Storage::DBI;

# The registration seam for DBD-private statement-handle
# functions on the fake storage.
#
# Core gave DBIO::Test::Storage::FakeSth a func() answering undef:
# right as a form, but a fixed value with no way to register one. A driver
# whose engine answers a question about a PREPARED statement through a
# DBD-private XSUB (DBI's $sth->func) could not test that answer against the
# mock storage without overwriting core internals by glob:
#
#   *DBIO::Test::Storage::FakeSth::func = sub { ... };
#
# Two problems with that, the second worse (both hit in dbio-firebird): the glob
# is the only route, and DBIO::Test loads DBIO::Test::Storage LAZILY from
# init_schema, so a glob installed at file scope is silently compiled away
# again when the class finally loads -- core's undef stub wins, and the
# driver's "no plan" exception surfaces 150 lines later with nothing pointing
# back at the override.
#
# The seam: $storage->mock_func($name, $answer) registers what the fake
# statement handle answers for func($name). _capture_sth -- where every fake
# statement handle is built from the registered mocks -- hands the
# registrations to FakeSth, so func() answers from the registration and
# otherwise stays undef. No glob on core internals, and no dependence on WHEN
# DBIO::Test::Storage was loaded: the answer travels with the statement, not
# with the class.

# --- 1. the default: func answers undef -------------------------------------
#
# The pre-existing contract the seam must not disturb. A handle built through
# the statement seam answers undef for an unregistered function, on both the
# prepare and the execute side of it.

{
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;

  my $prepared = $storage->_prepare_rendered('SELECT 1 FROM "artist"', []);
  is $prepared->func('ib_plan'), undef,
    'an unregistered func answers undef on the prepare path';

  my (undef, $executed) = $storage->_execute_rendered('SELECT 1 FROM "artist"', []);
  is $executed->func('ib_plan'), undef,
    '... and on the execute path too';
}

# --- 2. a plain value registration ------------------------------------------

{
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;

  $storage->mock_func( ib_plan => "PLAN (ARTIST NATURAL)\n" );

  my $prepared = $storage->_prepare_rendered('SELECT 1 FROM "artist"', []);
  is $prepared->func('ib_plan'), "PLAN (ARTIST NATURAL)\n",
    'a registered func answers its value on the prepare path';

  my (undef, $executed) = $storage->_execute_rendered('SELECT 1 FROM "artist"', []);
  is $executed->func('ib_plan'), "PLAN (ARTIST NATURAL)\n",
    '... and on the execute path -- _capture_sth hands both the registrations';

  is $executed->func('some_other_xsub'), undef,
    '... while any unregistered function still answers undef';
}

# --- 3. per-storage isolation ------------------------------------------------
#
# The registration is per-storage, like the row mocks. Two storages in one
# test process, one registered: the other must keep the default.

{
  my $a = DBIO::Test->init_schema(no_deploy => 1)->storage;
  my $b = DBIO::Test->init_schema(no_deploy => 1)->storage;

  $a->mock_func( ib_plan => 'PLAN (ARTIST NATURAL)' );

  is $a->_prepare_rendered('SELECT 1', [])->func('ib_plan'),
    'PLAN (ARTIST NATURAL)',
    'the registered storage answers';
  is $b->_prepare_rendered('SELECT 1', [])->func('ib_plan'), undef,
    'a sibling storage keeps the default undef -- no class-level glob anywhere';
}

# --- 4. the coderef form -----------------------------------------------------
#
# A driver test that counts the calls (dbio-firebird t/58 asserts the handle
# was asked for ib_plan exactly once) needs the answer to be dynamic. The
# coderef is called with the fake handle, the function name and any extra
# arguments, exactly the shape a DBD's private ST method receives on a real
# handle.

{
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;

  my @calls;
  $storage->mock_func( ib_plan => sub {
    my ($sth, $name, @rest) = @_;
    push @calls, [ $name, @rest ];
    return "PLAN (ARTIST NATURAL)\n";
  });

  my $sth = $storage->_prepare_rendered('SELECT 1 FROM "artist"', []);

  is $sth->func('ib_plan'), "PLAN (ARTIST NATURAL)\n",
    'a coderef answer is invoked and its return value becomes the answer';
  is_deeply \@calls, [ [ 'ib_plan' ] ],
    '... receiving the function name as the DBD private method would';

  is $sth->func('ib_plan', 'extra', 42), "PLAN (ARTIST NATURAL)\n",
    'extra arguments are accepted';
  is_deeply \@calls,
    [ [ 'ib_plan' ], [ 'ib_plan', 'extra', 42 ] ],
    '... and passed through to the coderef';
}

# --- 5. registering undef is an answer, not an absence -----------------------
#
# A DBD that failed to produce a value answers undef too -- Firebird's XSUB
# reads isc_info_sql_get_plan into a fixed 2048-byte buffer and answers undef
# when the plan does not fit. A test of THAT failure registers undef, and the
# registration must be reached even though the value equals the default: the
# observable difference is that a registered coderef is still called.

{
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;

  my $called = 0;
  $storage->mock_func( ib_plan => sub { $called++; return undef });

  my $sth = $storage->_prepare_rendered('SELECT 1 FROM "artist"', []);
  is $sth->func('ib_plan'), undef,
    'a registered answer of undef is still undef, as on a real DBD';
  is $called, 1,
    '... but the registration was REACHED -- it is an answer, not a fall-through';
}

# --- 6. clear_mocks clears the registrations along with the row mocks --------

{
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;

  $storage->mock_func( ib_plan => 'PLAN (ARTIST NATURAL)' );
  is $storage->_prepare_rendered('SELECT 1', [])->func('ib_plan'),
    'PLAN (ARTIST NATURAL)',
    'registered before the clear';

  $storage->clear_mocks;
  is $storage->_prepare_rendered('SELECT 1', [])->func('ib_plan'), undef,
    'clear_mocks removes the func registration along with the row mocks';
}

# --- 6b. clear_mocks empties in-place: handles built before the clear --------
#
# Section 6 only tested a handle grabbed AFTER the clear. The registrations
# are passed by REFERENCE from _capture_sth into the fake statement handle
# (FakeSth's `funcs` slot), so a handle built BEFORE the clear holds the
# same hashref the storage is about to wipe. Replacing it with a fresh {}
# (the pre-fix behaviour) leaves the held handle holding the OLD hashref,
# so its func() keeps returning the registered answer after the clear --
# contradicting the live-registration semantics documented on mock_func.
# The fix is to empty the hashref in place (%{...} = ()) so the handle
# the storage built sees the cleared state too.

{
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;

  $storage->mock_func( ib_plan => 'PLAN (ARTIST NATURAL)' );

  # grab the handle BEFORE clear_mocks, while the registration is live
  my $held = $storage->_prepare_rendered('SELECT 1', []);
  is $held->func('ib_plan'), 'PLAN (ARTIST NATURAL)',
    'handle grabbed before the clear sees the registered answer';

  $storage->clear_mocks;

  is $held->func('ib_plan'), undef,
    '... and the SAME handle sees the cleared answer afterwards -- in-place clear';
}

# --- 7. the seam is _capture_sth ---------------------------------------------
#
# A fake statement handle built outside it -- bare FakeSth->new, or the fake
# storage's _prepare_sth stub -- has no registrations and answers undef even
# when the storage carries some. That is deliberate: the seam a driver is
# supposed to use is the statement path (_prepare_rendered / _execute_rendered),
# and a handle reached past it gets no engine either.

{
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;

  $storage->mock_func( ib_plan => 'PLAN (ARTIST NATURAL)' );

  is $storage->_prepare_sth->func('ib_plan'), undef,
    'a handle from _prepare_sth does not carry the registrations';
  is DBIO::Test::Storage::FakeSth->new->func('ib_plan'), undef,
    '... and neither does a bare FakeSth -- the answer travels with the '
  . 'statement the storage built';
}

# --- 8. the Firebird shape, whole --------------------------------------------
#
# The ticket's first customer, end to end: a driver whose _explain_query
# prepares the query and reads the plan off the handle with func('ib_plan')
# (ADR 0040 section 6), now testable against the mock storage by registering
# the plan -- no glob, no load-order dependence.

{
  package T::MockFunc::FirebirdStorage;
  use base 'DBIO::Storage::DBI';
  sub _explain_query {
    my ($self, $sql, $bind) = @_;

    my $sth = $self->_prepare_rendered($sql, $bind);

    my $plan = $sth->func('ib_plan');

    # undef here is the DBD's fixed 2048-byte plan buffer overflowing, not
    # "this query has no plan" -- every prepared statement has one.
    $self->throw_exception(
      'Firebird prepared the statement but the driver returned no plan for it. '
    . 'Every prepared statement has a plan, so this is the DBD rather than the '
    . 'engine: DBD::Firebird and DBD::InterBase read isc_info_sql_get_plan into '
    . 'a fixed 2048-byte buffer (PLAN_BUFFER_LEN) and answer undef when the '
    . 'plan does not fit.'
    ) unless defined $plan;

    return [ [ $plan ] ];
  }
}
$INC{'T/MockFunc/FirebirdStorage.pm'} = __FILE__;

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'T::MockFunc::FirebirdStorage',
  );
  my $storage = $schema->storage;

  $storage->mock_func( ib_plan => "PLAN (ARTIST NATURAL)\n" );
  $storage->reset_captured;

  my $plan = $schema->resultset('Artist')->search({ name => 'secret' })->explain;

  is_deeply $plan, [ [ "PLAN (ARTIST NATURAL)\n" ] ],
    'a driver-shaped _explain_query answers the registered plan';

  my @captured = $storage->captured_queries;
  is scalar @captured, 1,
    'the operation was seen by the storage layer, all one statement of it';
  is $captured[0]{op}, 'prepare',
    'and it was PREPARED, never executed -- the shape ADR 0040 section 6 '
  . 'built _prepare_rendered for';
}

# --- 9. the control: without a registration the driver throws ---------------
#
# Section 8 is worth nothing if its assertions cannot fail. Same driver, no
# mock_func: func() answers the default undef, and the driver's own
# "no plan" exception is what surfaces -- the same shape dbio-firebird t/58
# asserts, but reached through the seam rather than through a glob.

{
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'T::MockFunc::FirebirdStorage',
  );
  my $storage = $schema->storage;

  my $threw = 0;
  eval {
    $schema->resultset('Artist')->search({ name => 'secret' })->explain;
    1;
  } or $threw = 1;

  ok $threw, 'without a registration the driver throws instead of answering';
  like $@, qr/PLAN_BUFFER_LEN/,
    '... with the driver\'s own message, naming the DBD\'s plan buffer';
  is scalar($storage->captured_queries), 1,
    '... after the statement was prepared, so the failure is about the plan '
  . 'and not about the query';
}

done_testing;
