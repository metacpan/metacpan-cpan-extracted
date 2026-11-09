use strict;
use warnings;

use Test::More;

use DBIO::Test;

# The explain() shortcut (folded in from
# DBIx::Class::Helper::ResultSet::Explain, with DBIx::Introspector replaced by
# a storage hook).
#
# explain() used to reach past the storage layer straight to
# $storage->dbh, which made it the one helper the fake storage could not run --
# this file had to hand it a recording handle of its own. It goes down
# _execute_rendered now, the same seam results_exist uses (ADR 0037), so it is
# captured and mocked like every other statement.
#
# ADR 0040: the hook is _explain_query($sql, \@bind) -> \@rows and
# owns the WHOLE operation, not just the spelling -- four engines cannot obtain
# a plan with one statement. Owning the execution is also what makes it
# possible to reintroduce every regression the seam removed, so the contract
# requires each statement to go through _execute_rendered. Section 4 below is
# what pins that rule; section 5 is the control that proves section 4 can fail.
#
# One engine had no statement for that rule to apply to. Firebird
# reads its plan off the PREPARED handle and executes nothing, so the rule
# widened to "the storage's statement path" and core exposes the path one verb
# earlier as _prepare_rendered (ADR 0040 section 6). Sections 6 and 7 are the
# same pair for that shape.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

# --- 1. the base operation ------------------------------------------------

$storage->mock(qr/^EXPLAIN /, [ ['plan row'] ]);
$storage->reset_captured;

my $rs = $schema->resultset('Artist')->search({ name => 'foo', rank => 13 });

my $plan = $rs->explain;

is_deeply($plan, [ ['plan row'] ], 'explain returns the rows the plan statement produced');

my @captured = $storage->captured_queries;

is(scalar @captured, 1, 'the base implementation issued exactly one statement');

like($captured[0]{sql}, qr/^EXPLAIN SELECT /, 'the statement comes from the _explain_query hook');
unlike($captured[0]{sql}, qr/^\s*\(/, 'the surrounding parens of as_query are stripped');

# as_query hands back [ \%bind_attrs, $value ] pairs, and that is also what the
# statement path takes -- so they travel unchanged, all the way into the hook.
# Reaching for a raw $dbh->selectall_arrayref meant unwrapping them by hand,
# and getting that wrong (upstream did) bound the stringified arrayref
# "ARRAY(0x...)" instead of the value, so every explain of a query with a WHERE
# clause was wrong.
is_deeply(
  [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $captured[0]{bind} } ],
  [ 'foo', 13 ],
  'the query bind values reach the plan statement',
);

# --- 2. the statement is traced -------------------------------------------
#
# Going through the storage means going through everything _execute does below
# SQL generation -- including the trace callbacks, and therefore the
# redact_bind_value hook (ADR 0025), which the raw-handle version bypassed.
{
  my @traced;
  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(2);
  $storage->mock(qr/^EXPLAIN /, [ ['plan row'] ]);
  $schema->resultset('Artist')->search({ name => 'foo' })->explain;
  $storage->debug(0);
  $storage->debugcb(undef);

  ok(
    scalar(grep { /^EXPLAIN SELECT/ } @traced),
    'the plan statement goes through the traced statement path',
  );
}

# --- 3. the hook decides the whole operation ------------------------------
#
# Core composes nothing around it -- which is what lets dbio-sqlite say
# EXPLAIN QUERY PLAN.
{
  package My::Explain::Storage;
  use base 'DBIO::Storage::DBI';
  sub _explain_query {
    my ($self, $sql, $bind) = @_;
    my (undef, $sth) = $self->_execute_rendered("EXPLAIN QUERY PLAN $sql", $bind);
    return $sth->fetchall_arrayref;
  }
}
$INC{'My/Explain/Storage.pm'} = __FILE__;

{
  my $hook_schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'My::Explain::Storage',
  );
  $hook_schema->storage->mock(qr/^EXPLAIN QUERY PLAN /, [ ['scan artist'] ]);
  $hook_schema->storage->reset_captured;

  my $hook_plan = $hook_schema->resultset('Artist')->explain;
  is_deeply($hook_plan, [ ['scan artist'] ], 'the driver spelling produced the plan');

  my ($hook_stmt) = $hook_schema->storage->captured_queries;
  like(
    $hook_stmt->{sql},
    qr/^EXPLAIN QUERY PLAN SELECT /,
    'a driver overriding _explain_query decides the whole statement',
  );
}

# --- 4. THE RULE: every statement of an override goes through _execute_rendered
#
# The reason the hook is a method and not a string is that Oracle, DB2, SQL
# Server and Firebird need more than one round trip (ADR 0040). Sybase ASE
# needs more than the seam has: its plan comes back as server messages, not as
# rows, so it is not implementable here at all (ADR 0040 section 7). The
# price is that the driver now owns the execution and can reach past the
# storage -- losing exactly what the seam restored. So the contract says
# every statement goes through _execute_rendered, and this is what holds it:
# on the fake storage _execute_rendered is the ONLY place a statement can be
# seen at all. Nothing else records it, nothing else traces it, nothing else
# redacts it.
#
# Two statements here, deliberately -- the Oracle shape, which is the whole
# reason for the new signature: EXPLAIN PLAN FOR writes into PLAN_TABLE and
# returns no rows, so the plan comes from a second query with binds of its own.
{
  package My::TwoStatement::Storage;
  use base 'DBIO::Storage::DBI';
  sub _explain_query {
    my ($self, $sql, $bind) = @_;

    # writes the plan, answers nothing
    $self->_execute_rendered("EXPLAIN PLAN FOR $sql", $bind);

    # reads it back -- a statement core never saw, with a bind of its own
    my (undef, $sth) = $self->_execute_rendered(
      'SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(?))',
      [ [ { dbic_colname => 'statement_id' }, 'dbio-explain' ] ],
    );

    return $sth->fetchall_arrayref;
  }
}
$INC{'My/TwoStatement/Storage.pm'} = __FILE__;

{
  my $two_schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'My::TwoStatement::Storage',
  );
  my $two_storage = $two_schema->storage;

  $two_storage->mock(qr/DBMS_XPLAN/, [ ['Plan hash value: 42'] ]);

  # ADR 0025: the redactor is the observable that only the traced path can
  # produce. A driver reaching for $dbh directly would print the raw value --
  # or, more likely, print nothing at all, because there would be no trace.
  $two_storage->redact_bind_value(sub {
    my ($colname, $value) = @_;
    return defined $colname && $colname =~ /^(?:name|statement_id)$/
      ? '[redacted]' : $value;
  });

  my @traced;
  $two_storage->debugcb(sub { push @traced, $_[1] });
  $two_storage->debug(2);
  $two_storage->reset_captured;

  my $two_plan = $two_schema->resultset('Artist')
    ->search({ name => 'secret' })->explain;

  $two_storage->debug(0);
  $two_storage->debugcb(undef);

  is_deeply(
    $two_plan, [ ['Plan hash value: 42'] ],
    'a two-statement override answers with the rows of its second statement',
  );

  my @two_captured = $two_storage->captured_queries;
  is(scalar @two_captured, 2,
    'BOTH statements of the override were seen by the storage layer '
  . '(a statement issued past _execute_rendered is captured nowhere)');

  like($two_captured[0]{sql}, qr/^EXPLAIN PLAN FOR SELECT /,
    'first statement: the driver spelling, with the query core rendered');
  is_deeply(
    [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $two_captured[0]{bind} } ],
    [ 'secret' ],
    '... carrying the original query binds the hook was handed');
  like($two_captured[1]{sql}, qr/DBMS_XPLAN/,
    'second statement: the driver\'s own, which core never rendered');

  # The trace is the second, independent witness, and the one that carries the
  # ADR 0025 hook. Both statements appear, and both had their binds redacted --
  # neither is possible without _execute_rendered.
  ok(scalar(grep { /^EXPLAIN PLAN FOR SELECT/ } @traced),
    'the first statement reached the traced path');
  ok(scalar(grep { /DBMS_XPLAN/ } @traced),
    'the driver\'s second statement reached the traced path too');
  ok(scalar(grep { /DBMS_XPLAN.*\[redacted\]/s } @traced),
    'redact_bind_value (ADR 0025) applied to a bind the DRIVER supplied');
  ok(!scalar(grep { /secret/ } @traced),
    'and to the query bind -- the raw value never reached the trace sink');
}

# --- 5. the control: what a bypassing driver looks like -------------------
#
# Section 4 is only worth anything if its assertions can fail. This is the same
# hook, implemented the way explain() used to be implemented -- reaching
# for the handle instead of the seam. It answers, so the ORM cannot tell; what
# it does not do is appear anywhere. That is precisely the assertion above,
# inverted, which is what makes that assertion a test rather than a decoration.
#
# Core cannot detect this from inside: a driver's _explain_query is opaque, and
# nothing in DBIO::Storage::DBI can tell whether a method it called touched
# $dbh. What core CAN do is make the bypass loud in the place every driver
# already tests -- against DBIO::Test::Storage, where a bypassing
# implementation captures nothing, traces nothing and redacts nothing. The
# per-driver assertion is the driver's own to write; this file states the shape
# it has to take.
{
  package My::Bypassing::Storage;
  use base 'DBIO::Storage::DBI';
  sub _explain_query {
    my ($self, $sql, $bind) = @_;
    # THE ANTI-PATTERN -- do not copy this into a driver.
    my $sth = $self->_dbh->prepare("EXPLAIN $sql");
    $sth->execute;
    return $sth->fetchall_arrayref;
  }
}
$INC{'My/Bypassing/Storage.pm'} = __FILE__;

{
  my $bypass_schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'My::Bypassing::Storage',
  );
  my $bypass_storage = $bypass_schema->storage;

  $bypass_storage->mock(qr/^EXPLAIN /, [ ['plan row'] ]);

  my @traced;
  $bypass_storage->debugcb(sub { push @traced, $_[1] });
  $bypass_storage->debug(2);
  $bypass_storage->reset_captured;

  $bypass_schema->resultset('Artist')->search({ name => 'secret' })->explain;

  $bypass_storage->debug(0);
  $bypass_storage->debugcb(undef);

  is(scalar($bypass_storage->captured_queries), 0,
    'a bypassing override issues a statement the storage layer never sees '
  . '(so the count assertion in section 4 discriminates)');
  is(scalar @traced, 0,
    '... and it is not traced, so redact_bind_value never runs on it (ADR 0025)');
}

# --- 6. the engine with no statement to route -----------------------------
#
# ADR 0040 section 6. Firebird's plan is a property of the PREPARED
# statement (isc_info_sql_get_plan, read through DBD::Firebird's private
# $sth->func('ib_plan')) and
# nothing is executed at all -- so section 4's rule, as first written, had
# nothing to apply to on the one engine that could not obey it. A driver that
# MUST break a rule is a finding about the rule, so the statement path is
# exposed one step earlier instead of the rule growing an engine-named hole:
# _prepare_rendered($sql, \@bind) -> $sth, everything _execute_rendered does
# except the execute.
#
# Same shape as section 4: the storage layer is the only place the statement
# can be seen, and section 7 is the control that proves these assertions can
# fail. The seam's own mechanics -- prepared, NOT executed, retried, reshaped --
# live in t/test/25_prepare_rendered.t against counting stub handles.
{
  package My::Firebird::Storage;
  use base 'DBIO::Storage::DBI';
  our $LAST_STH;
  sub _explain_query {
    my ($self, $sql, $bind) = @_;

    # The whole operation: prepare the query being explained -- through the
    # storage, so the trace and the redactor still see it -- and read the plan
    # off the handle without running anything.
    my $sth = $LAST_STH = $self->_prepare_rendered($sql, $bind);

    # DBD::Firebird answers this off a statement that was never executed, and
    # answers it through func() -- ib_plan is a private XSUB of the statement
    # handle in both Firebird DBDs, not a fetchable attribute, so $sth->{ib_plan}
    # would be a silent undef. There is no engine behind the fake
    # storage to produce a plan; what this section tests is the seam the driver
    # reached it through, and the shape it has to wrap a single opaque string in.
    my $plan = $sth->func('ib_plan') || 'PLAN (ARTIST NATURAL)';

    return [ [ $plan ] ];
  }
}
$INC{'My/Firebird/Storage.pm'} = __FILE__;

{
  my $fb_schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'My::Firebird::Storage',
  );
  my $fb_storage = $fb_schema->storage;

  $fb_storage->redact_bind_value(sub {
    my ($colname, $value) = @_;
    return defined $colname && $colname eq 'name' ? '[redacted]' : $value;
  });

  my @traced;
  $fb_storage->debugcb(sub { push @traced, $_[1] });
  $fb_storage->debug(2);
  $fb_storage->reset_captured;

  my $fb_plan = $fb_schema->resultset('Artist')->search({ name => 'secret' })->explain;

  $fb_storage->debug(0);
  $fb_storage->debugcb(undef);

  ok($My::Firebird::Storage::LAST_STH,
    'the seam handed the driver a live statement handle');

  # A plan that is one string, not a table. The driver wraps it as a one-row,
  # one-column result and core passes it through untouched -- the return type
  # is rows, and ADR 0040 section 2 already says their contents were never
  # portable.
  is_deeply($fb_plan, [ [ 'PLAN (ARTIST NATURAL)' ] ],
    'a single-string plan travels as [[ $plan ]], composed by nobody but the driver');

  my @fb_captured = $fb_storage->captured_queries;
  is(scalar @fb_captured, 1,
    'the operation was seen by the storage layer, all one statement of it');
  is($fb_captured[0]{op}, 'prepare',
    'and it was PREPARED, never executed -- the shape section 4\'s rule had '
  . 'nothing to route');
  like($fb_captured[0]{sql}, qr/^SELECT /,
    'the statement is the query itself: the plan comes off its own handle, '
  . 'so there is no EXPLAIN spelling to get wrong');

  is_deeply(
    [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $fb_captured[0]{bind} } ],
    [ 'secret' ],
    'the query binds reach the prepare -- a plan is asked of the real statement',
  );

  # The guarantee the seam exists to keep. Everything in section 4 that made
  # _execute_rendered worth requiring holds one verb earlier too.
  ok(scalar(grep { /^SELECT / } @traced),
    'the prepared statement reached the traced path');
  ok(scalar(grep { /\[redacted\]/ } @traced),
    'redact_bind_value (ADR 0025) applied to its binds');
  ok(!scalar(grep { /secret/ } @traced),
    '... so the raw WHERE-clause value never reached the trace sink');
}

# --- 7. the control for section 6 -----------------------------------------
#
# What Firebird would have had to write if core had taken the other option and
# put a named exception into the rule instead of exposing the path: reach for
# the handle, prepare, read the plan. It answers -- and that is the whole
# problem. Nothing is captured, nothing is traced, and the bind values of the
# user's own query go past the redactor.
{
  package My::Firebird::Bypassing::Storage;
  use base 'DBIO::Storage::DBI';
  sub _explain_query {
    my ($self, $sql, $bind) = @_;
    # THE ANTI-PATTERN -- do not copy this into a driver.
    my $sth = $self->_dbh->prepare($sql);
    return [ [ $sth->func('ib_plan') || 'PLAN (ARTIST NATURAL)' ] ];
  }
}
$INC{'My/Firebird/Bypassing/Storage.pm'} = __FILE__;

{
  my $fbb_schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'My::Firebird::Bypassing::Storage',
  );
  my $fbb_storage = $fbb_schema->storage;

  my @traced;
  $fbb_storage->debugcb(sub { push @traced, $_[1] });
  $fbb_storage->debug(2);
  $fbb_storage->reset_captured;

  my $fbb_plan = $fbb_schema->resultset('Artist')->search({ name => 'secret' })->explain;

  $fbb_storage->debug(0);
  $fbb_storage->debugcb(undef);

  is_deeply($fbb_plan, [ [ 'PLAN (ARTIST NATURAL)' ] ],
    'the bypassing version answers just as well, so the ORM cannot tell');
  is(scalar($fbb_storage->captured_queries), 0,
    'but the statement layer never saw the prepare '
  . '(so section 6 discriminates)');
  is(scalar @traced, 0,
    '... and it is not traced, so redact_bind_value never runs on it (ADR 0025)');
}

# --- 8. the engine that answers on the connection, not the statement --------
#
# ADR 0040 section 7: Sybase ASE's showplan arrives as SERVER
# MESSAGES -- the channel DBD::Sybase exposes only through syb_err_handler --
# so nothing reaches $sth->fetchall_arrayref however correctly the five
# statements are issued. The seam: _execute_sth wraps the execute so a driver
# can collect the messages a statement produced, and _server_messages makes
# them readable back. The driver installs its handler on the handle the
# statement runs on -- never on $self->dbh -- so tracing, redact_bind_value,
# dbh_do retry and the read handler all survive. The seam's own mechanics live
# in t/test/29_server_messages.t; this section is the driver-shaped shape.
{
  package My::ASE::Storage;
  use base 'DBIO::Storage::DBI';
  sub _execute_sth {
    my ($self, $dbh, $sth) = @_;
    my $messages = [];
    # Simulate the syb_err_handler firing: the engine answers on the
    # connection, not the statement. The query statement produces the plan.
    if ($sth->{sql} && $sth->{sql} =~ /^SELECT/) {
      push @$messages, 'PLAN: scan artist';
    }
    return ($sth->execute, $messages);
  }
  sub _explain_query {
    my ($self, $sql, $bind) = @_;
    # Five statements, per SAP "Using set showplan with noexec": the plain
    # form prints the plan AND runs the query, so noexec has to bracket it.
    $self->_execute_rendered('set showplan on', []);
    $self->_execute_rendered('set noexec on', []);
    $self->_execute_rendered($sql, $bind);
    my $messages = $self->_server_messages;
    $self->_execute_rendered('set noexec off', []);
    $self->_execute_rendered('set showplan off', []);
    return [ map { [ $_ ] } @$messages ];
  }
}
$INC{'My/ASE/Storage.pm'} = __FILE__;

{
  my $ase_schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'My::ASE::Storage',
  );
  my $ase_storage = $ase_schema->storage;

  $ase_storage->redact_bind_value(sub {
    my ($colname, $value) = @_;
    return defined $colname && $colname eq 'name' ? '[redacted]' : $value;
  });

  my @traced;
  $ase_storage->debugcb(sub { push @traced, $_[1] });
  $ase_storage->debug(2);
  $ase_storage->reset_captured;

  my $ase_plan = $ase_schema->resultset('Artist')->search({ name => 'secret' })->explain;

  $ase_storage->debug(0);
  $ase_storage->debugcb(undef);

  is_deeply($ase_plan, [ [ 'PLAN: scan artist' ] ],
    'the plan travels as the collected server messages, wrapped as rows');

  my @ase_captured = $ase_storage->captured_queries;
  is(scalar @ase_captured, 5,
    'the operation was seen by the storage layer, all five statements of it');
  is($ase_captured[0]{sql}, 'set showplan on',
    'first: showplan on');
  is($ase_captured[1]{sql}, 'set noexec on',
    'second: noexec on -- the query must not run while only planning');
  like($ase_captured[2]{sql}, qr/^SELECT /,
    'third: the query itself -- the plan comes back as messages, not rows');
  is($ase_captured[3]{sql}, 'set noexec off',
    'fourth: noexec off');
  is($ase_captured[4]{sql}, 'set showplan off',
    'fifth: showplan off -- the setting must not outlive the operation');

  is_deeply(
    [ map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $ase_captured[2]{bind} } ],
    [ 'secret' ],
    'the query binds reach the plan statement',
  );

  # The guarantee the seam exists to keep: every statement went through the
  # traced path, and the query's own bind value was redacted.
  ok(scalar(grep { /^set showplan on/ } @traced),
    'the set statements reached the traced path');
  ok(scalar(grep { /^SELECT / } @traced),
    'the query statement reached the traced path too');
  ok(scalar(grep { /\[redacted\]/ } @traced),
    'redact_bind_value (ADR 0025) applied to the query bind');
  ok(!scalar(grep { /secret/ } @traced),
    '... so the raw WHERE-clause value never reached the trace sink');
}

done_testing;
