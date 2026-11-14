package DBIO::Test::Storage;
# ABSTRACT: Fake storage for testing SQL generation without a database

use strict;
use warnings;

our $VERSION = '0.900005';

use base qw(DBIO::Storage::DBI);
use mro 'c3';

use DBIO::Storage::Statistics;


__PACKAGE__->datetime_parser_type('DBIO::Test::DateTimeParser');

# ADR 0037: the fake storage renders the base CASE form of _exists_value_sql,
# which is the standard spelling -- so it declares the capability, the way a
# driver whose engine takes the base rendering does. Without the declaration
# every core test touching results_exist would be testing the refusal.
__PACKAGE__->_use_supports_exists_query(1);

__PACKAGE__->mk_group_accessors(simple => qw(
  _captured_queries
  _fake_connected
  _mock_results
  _last_insert_ids
  _auto_increment
  _mock_affected_rows
  _mock_funcs
));

sub new {
  my $self = shift->next::method(@_);
  $self->_captured_queries([]);
  $self->_fake_connected(1);
  $self->{_fake_dbh} = DBIO::Test::Storage::FakeDbh->new;
  $self->_mock_results([]);
  $self->_last_insert_ids({});
  $self->_auto_increment({});
  $self->_mock_funcs({});
  $self->{_sql_maker_opts} ||= {};
  $self->{_driver_determined} = 1;
  # ADR 0030: the mock storage defaults to the 'immediate' async mode so mock
  # tests exercise *_async with no event loop (degrade to an immediately
  # resolved DBIO::Future::Immediate), instead of croaking as a sync instance would.
  $self->_async_mode('immediate');
  $self;
}


sub connected { $_[0]->_fake_connected }


sub ensure_connected { 1 }

sub _populate_dbh { }


sub disconnect {
  my $self = shift;
  $self->_fake_connected(0);
  $self->next::method;
  1;
}

# We have no real dbh, but we do hand out a stand-in for the one thing that
# reads _dbh without ever talking to a database: L<DBIO::Storage::TxnScopeGuard>
# weakens a ref to it on construction and *declines to roll back* when that ref
# is empty. With no handle at all every implicit rollback on the fake storage
# was a silent no-op, so a test asserting "nothing was written" passed for the
# wrong reason -- the fake storage was never going to write. The handle makes
# the guard engage, and the ROLLBACK shows up in L</captured_queries> like any
# other statement.
#
# Deliberately not a setter: DBIO::Storage::DBI clears _dbh in disconnect() /
# DESTROY() / CLONE(), and the fake storage stays usable across all of those.
# _get_dbh remains undef -- code that wants a *working* handle must still not
# get one here.
sub _dbh { $_[0]->{_fake_dbh} }
sub _get_dbh { undef }
sub _server_info { { dbms_version => 0, normalized_dbms_version => 0 } }

sub _determine_driver {
  $_[0]->{_driver_determined} = 1;
  return '';
}
sub _init {}
sub _seems_connected { $_[0]->_fake_connected }
sub _dbh_autocommit { 1 }

# Override txn_begin/commit/rollback to skip real dbh checks
sub txn_begin {
  my $self = shift;
  $self->next::method(@_);
}

sub txn_commit {
  my $self = shift;
  $self->throw_exception("Unable to txn_commit() on a disconnected storage")
    unless $self->_fake_connected;
  $self->next::method(@_);
}

sub txn_rollback {
  my $self = shift;
  $self->throw_exception("Unable to txn_rollback() on a disconnected storage")
    unless $self->_fake_connected;
  $self->next::method(@_);
}


sub _execute {
  my ($self, $op, $ident, @args) = @_;

  my ($sql, $bind) = $self->_prep_for_execute($op, $ident, \@args);

  # Track inserts for last_insert_id
  if ($op eq 'insert') {
    my $source_name = ref $ident ? $ident->name : ($ident || '');
    my $id = $self->_next_auto_id($source_name);
    $self->_last_insert_ids->{$source_name} = $id;
  }

  return $self->_capture_statement($op, $sql, $bind);
}


sub _execute_rendered {
  my ($self, $sql, $bind) = @_;

  # Same reshaping a real storage applies on this path -- a hybrid fake
  # storage over DBIO::Storage::DBI::NoBindVars must capture the statement
  # with its bind values interpolated, because that is what its engine would
  # have received.
  ($sql, $bind) = $self->_prep_rendered_for_execute($sql, $bind);

  return $self->_capture_statement('select', $sql, $bind);
}


sub _prepare_rendered {
  my ($self, $sql, $bind) = @_;

  # Same reshaping the real seam applies (NoBindVars interpolation), for the
  # same reason it applies it in _execute_rendered.
  ($sql, $bind) = $self->_prep_rendered_for_execute($sql, $bind);

  return $self->_capture_sth('prepare', $sql, $bind);
}

# Shared tail of _execute / _execute_rendered: log the statement, run the
# tracing hooks (so redact_bind_value is exercised on the fake storage too),
# and answer from the registered mocks.
sub _capture_statement {
  my ($self, $op, $sql, $bind) = @_;

  my $fake_sth = $self->_capture_sth($op, $sql, $bind);

  # The server-message seam. The real _dbh_execute routes the
  # execute through _execute_sth so a driver can collect the messages a
  # statement produced on the connection; the fake storage does the same, so a
  # driver-shaped override is exercised here exactly as it would be against a
  # real handle. The base _execute_sth answers (undef) -- no collection.
  my (undef, $messages) = $self->_execute_sth($self->_dbh, $fake_sth);
  $self->_server_messages($messages);

  # For DML operations (insert/update/delete), return 1 (row affected)
  # For select, return '0E0' (zero but true)
  my $rv = ($op =~ /^(?:insert|update|delete)$/)
    ? ( defined $self->_mock_affected_rows ? $self->_mock_affected_rows : 1 )
    : '0E0';

  return (wantarray ? ($rv, $fake_sth, @{$bind||[]}) : $rv);
}

# The part _capture_statement and _prepare_rendered share: record the statement
# in the query log, run the tracing hooks (so redact_bind_value is exercised on
# the fake storage too) and build the handle from the registered mocks. It is
# the ONLY point at which a statement is seen at all on this storage, which is
# what makes a driver bypassing the seam loud here (ADR 0040 section 3).
sub _capture_sth {
  my ($self, $op, $sql, $bind) = @_;

  push @{ $self->_captured_queries }, {
    op   => $op,
    sql  => $sql,
    bind => $bind,
  };

  $self->_query_start($sql, $bind);
  $self->_query_end($sql, $bind);

  my $mock = $self->_find_mock($sql);

  return DBIO::Test::Storage::FakeSth->new(
    $mock ? $mock->{rows} : undef,
    $self->_mock_funcs,
    $sql,
  );
}


sub mock_affected_rows { shift->_mock_affected_rows(@_) }


sub captured_queries {
  @{ $_[0]->_captured_queries || [] }
}


sub captured_sql_bind {
  map { [ $_->{sql}, @{$_->{bind}||[]} ] } @{ $_[0]->_captured_queries || [] }
}


sub reset_captured {
  $_[0]->_captured_queries([]);
}


sub select {
  my $self = shift;
  my ($ident, $select, $condition, $attrs) = @_;
  return DBIO::Test::Storage::FakeCursor->new($self, \@_, $attrs);
}

sub select_single {
  my $self = shift;
  my ($rv, $sth, @bind) = $self->_execute('select', @_);
  my @row = $sth->fetchrow_array;
  $sth->finish;
  return @row;
}

# Transaction tracking
sub _exec_txn_begin {
  push @{ $_[0]->_captured_queries }, { op => 'txn_begin', sql => 'BEGIN', bind => [] };
}

sub _exec_txn_commit {
  push @{ $_[0]->_captured_queries }, { op => 'txn_commit', sql => 'COMMIT', bind => [] };
}

sub _exec_txn_rollback {
  push @{ $_[0]->_captured_queries }, { op => 'txn_rollback', sql => 'ROLLBACK', bind => [] };
}

sub _exec_svp_begin {
  my ($self, $name) = @_;
  push @{ $self->_captured_queries }, { op => 'svp_begin', sql => "SAVEPOINT $name", bind => [] };
}

sub _exec_svp_release {
  my ($self, $name) = @_;
  push @{ $self->_captured_queries }, { op => 'svp_release', sql => "RELEASE SAVEPOINT $name", bind => [] };
}

sub _exec_svp_rollback {
  my ($self, $name) = @_;
  push @{ $self->_captured_queries }, { op => 'svp_rollback', sql => "ROLLBACK TO SAVEPOINT $name", bind => [] };
}

# Deploy is a no-op
sub deploy { }

sub sqlt_type { 'NULL' }

# Override _insert_bulk to avoid needing a real dbh
sub _insert_bulk {
  my ($self, $source, $cols, $data, @rest) = @_;

  # Same column check as DBIO::Storage::DBI::_insert_bulk (unknown columns
  # throw, naming the column), and the INSERT is rendered by the SQLMaker,
  # so quoting is the live quoting (cursor invariant, karr k55 / k394).
  $self->throw_exception('Calling _insert_bulk without a dataset to process makes no sense')
    unless @{$data||[]};
  $source->columns_info($cols);

  my %proto;
  for my $idx (0 .. $#$cols) {
    my $v = $data->[0][$idx];
    $proto{ $cols->[$idx] } =
        ref $v eq 'SCALAR'                              ? $v
      : (ref $v eq 'REF' and ref $$v eq 'ARRAY')        ? \[ @$$v ]
      :                                                   \'?';
  }
  my ($sql) = $self->sql_maker->insert($source->from, \%proto);
  push @{ $self->_captured_queries }, {
    op   => 'insert',
    sql  => $sql,
    bind => [],
  };

  # Track auto-increment
  my $source_name = $source->name;
  for (1 .. scalar @$data) {
    my $id = $self->_next_auto_id($source_name);
    $self->_last_insert_ids->{$source_name} = $id;
  }

  return;
}

# _prepare_sth without a real dbh
sub _prepare_sth {
  return DBIO::Test::Storage::FakeSth->new;
}

# --- Mock result system ---


sub mock {
  my ($self, $pattern, $rows, $cols) = @_;
  $pattern = qr/\Q$pattern\E/ unless ref $pattern eq 'Regexp';
  push @{ $self->_mock_results }, {
    pattern    => $pattern,
    rows       => $rows || [],
    columns    => $cols,
    persistent => 0,
  };
}


sub mock_persistent {
  my ($self, $pattern, $rows, $cols) = @_;
  $pattern = qr/\Q$pattern\E/ unless ref $pattern eq 'Regexp';
  push @{ $self->_mock_results }, {
    pattern    => $pattern,
    rows       => $rows || [],
    columns    => $cols,
    persistent => 1,
  };
}


sub clear_mocks {
  $_[0]->_mock_results([]);
  %{$_[0]->_mock_funcs} = ();
}


sub mock_func {
  my ($self, $name, $answer) = @_;
  $self->_mock_funcs->{$name} = $answer;
  return $self;
}

sub _find_mock {
  my ($self, $sql) = @_;
  my $mocks = $self->_mock_results;

  # LIFO search -- last registered mock wins
  for my $i (reverse 0 .. $#$mocks) {
    if ($sql =~ $mocks->[$i]{pattern}) {
      my $mock = $mocks->[$i];
      splice @$mocks, $i, 1 unless $mock->{persistent};
      return $mock;
    }
  }
  return undef;
}

# Track auto-increment per source for last_insert_id
sub _next_auto_id {
  my ($self, $source_name) = @_;
  $self->_auto_increment->{$source_name} ||= 0;
  return ++$self->_auto_increment->{$source_name};
}


sub set_auto_increment {
  my ($self, $source_name, $val) = @_;
  $self->_auto_increment->{$source_name} = $val - 1;
}

sub last_insert_id {
  my ($self, $source, @cols) = @_;
  my $source_name = ref $source ? $source->name : ($source || '');
  return $self->_last_insert_ids->{$source_name};
}
sub _dbh_last_insert_id { $_[0]->last_insert_id }

# No DBI bind attrs needed
sub _dbi_attrs_for_bind { [] }

# columns_info_for comes from the Result class definitions, no DB introspection
sub columns_info_for { {} }

# dbh_do without a real dbh - just run the coderef with undef dbh
sub dbh_do {
  my $self = shift;
  my $run_target = shift;

  if (not ref $run_target) {
    $self->$run_target(undef, @_);
  }
  else {
    $run_target->($self, undef, @_);
  }
}

# ---- Fake database handle ----
#
# Only what the storage layer touches on a handle it never executes anything
# against: attribute access (both hash-style and FETCH/STORE), the connectivity
# probes, and the transaction verbs. The transaction verbs are dead ends here --
# DBIO::Test::Storage overrides _exec_txn_* to capture BEGIN/COMMIT/ROLLBACK
# instead of routing them to the handle -- they exist so an unexpected route to
# the handle is a no-op rather than a crash.
#
# Note the absence of column_info: DBIO::Storage::DBI::_dbh_columns_info_for
# branches on $dbh->can('column_info'), and the fake storage must keep taking
# the "no introspection" branch.

{
  package DBIO::Test::Storage::FakeDbh;

  sub new {
    my $class = shift;
    bless {
      Active     => 1,
      AutoCommit => 1,
      RaiseError => 0,
      PrintError => 0,
      CachedKids => {},
      Driver     => { Name => 'Test' },
    }, ref $class || $class;
  }

  sub FETCH { $_[0]->{ $_[1] } }
  sub STORE { $_[0]->{ $_[1] } = $_[2] }

  sub ping       { 1 }
  sub disconnect { $_[0]->{disconnected}++; 1 }

  sub begin_work { 1 }
  sub commit     { 1 }
  sub rollback   { 1 }

  sub prepare        { DBIO::Test::Storage::FakeSth->new }
  sub prepare_cached { DBIO::Test::Storage::FakeSth->new }
}

# ---- Fake statement handle ----

{
  package DBIO::Test::Storage::FakeSth;

  sub new {
    my ($class, $rows, $funcs, $sql) = @_;
    bless {
      rows  => $rows || [],
      pos   => 0,
      funcs => $funcs || {},
      sql   => $sql,
    }, ref $class || $class;
  }

  sub fetchrow_array {
    my $self = shift;
    return () if $self->{pos} >= scalar @{$self->{rows}};
    my $row = $self->{rows}[$self->{pos}++];
    return ref $row eq 'ARRAY' ? @$row : @$row;
  }

  sub fetchrow_hashref { undef }

  sub fetchall_arrayref {
    my $self = shift;
    my @rows;
    while (my @row = $self->fetchrow_array) {
      push @rows, [@row];
    }
    return \@rows;
  }

  sub finish { 1 }
  sub execute { '0E0' }
  sub bind_param { 1 }
  sub rows { scalar @{$_[0]->{rows}} }

  # DBI's dispatcher for a DBD's private statement-handle functions. Several
  # engines answer a question about a PREPARED statement here rather than
  # through an attribute -- Firebird's query plan is func('ib_plan') -- so a
  # driver-shaped override written against _prepare_rendered can be exercised
  # in its real form against this handle. There is no engine behind the fake
  # storage, so the default answer is undef; what a driver test registers for
  # a name through the storage's mock_func() seam (DBIO::Test::Storage
  # /mock_func) is what this handle answers, because _capture_sth builds the
  # handle with the storage's registrations. A handle built without them
  # (FakeDbh->prepare, _prepare_sth) always answers undef.
  sub func {
    my ($self, $name, @args) = @_;
    my $funcs = $self->{funcs} || {};
    return undef unless exists $funcs->{$name};
    my $answer = $funcs->{$name};
    return ref $answer eq 'CODE'
      ? $answer->($self, $name, @args)
      : $answer;
  }
}

# ---- Fake cursor ----

{
  package DBIO::Test::Storage::FakeCursor;

  use base 'DBIO::Cursor';

  sub new {
    my ($class, $storage, $args, $attrs) = @_;

    # Generate the SQL to check for mocks. Run the raw select arguments through
    # _select_args first (exactly like the real DBIO::Storage::DBI::Cursor does
    # via storage->_select), so join pruning / complex-prefetch rewriting is
    # applied before the SQL is rendered and captured.
    my ($op, $ident, @select_args) = $storage->_select_args(@$args);
    my ($sql, $bind) = $storage->_prep_for_execute($op, $ident, \@select_args);

    push @{ $storage->_captured_queries }, {
      op   => 'select',
      sql  => $sql,
      bind => $bind,
    };

    $storage->_query_start($sql, $bind);
    $storage->_query_end($sql, $bind);

    my $mock = $storage->_find_mock($sql);

    my $self = bless {
      storage => $storage,
      args    => $args,
      attrs   => $attrs,
      rows    => $mock ? [ @{$mock->{rows}} ] : [],
      pos     => 0,
    }, ref $class || $class;

    return $self;
  }

  sub next {
    my $self = shift;
    return () if $self->{_done};
    if ($self->{pos} >= scalar @{$self->{rows}}) {
      # mirror the real cursor: exhaustion latches _done so a further
      # ->next stays empty until an explicit ->reset
      $self->{_done} = 1;
      return ();
    }
    my $row = $self->{rows}[$self->{pos}++];
    return ref $row eq 'ARRAY' ? @$row : @$row;
  }

  sub all {
    my $self = shift;
    # mirror the real cursor: a bare ->all re-reads from the top,
    # independent of any prior iteration or exhaustion state
    $self->reset;
    my @all;
    while (my @row = $self->next) {
      push @all, \@row;
    }
    $self->reset;
    return @all;
  }

  sub reset {
    my $self = shift;
    $self->{pos} = 0;
    delete $self->{_done};
  }

  # Public cursor accessors matching DBIO::Storage::DBI::Cursor.
  # The mock must track position/exhaustion exactly like the real cursor so
  # the ResultSet collapse fast-path behaves identically under mock storage.
  sub is_exhausted { $_[0]->{_done} ? 1 : 0 }

  sub position { $_[0]->{pos} || 0 }

  sub mark_exhausted { $_[0]->{_done} = 1 }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Storage - Fake storage for testing SQL generation without a database

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

  my $schema = DBIO::Test::Schema->connect('DBIO::Test::Storage', '');
  my $rs = $schema->resultset('Artist')->search({ name => 'foo' });

  # .as_query works without a database
  my ($sql, @bind) = @{ ${$rs->as_query} };

  # or execute and inspect the captured query log
  my $storage = $schema->storage;
  $storage->reset_captured;
  $rs->all;  # generates SQL, returns empty results
  my @queries = $storage->captured_queries;

See F<t/test/04_query_capture.t> for a runnable example.

=head1 DESCRIPTION

A storage backend that generates SQL via L<DBIO::SQLMaker> but never executes
it against a real database. Every query is captured and can be inspected
through L</captured_queries>.

This is useful for:

=over 4

=item *

Testing SQL generation (SELECT, INSERT, UPDATE, DELETE)

=item *

Verifying ResultSet chaining produces expected queries

=item *

Schema metadata tests (columns, relationships, constraints)

=item *

Any test that only cares about I<what> SQL would be generated

=back

Transactions are part of that log: C<BEGIN>, C<COMMIT>, C<ROLLBACK> and the
savepoint verbs are captured like any statement, and that includes the implicit
rollback a L<DBIO::Storage::TxnScopeGuard> performs when it leaves scope without
a commit. The guard weakens a reference to C<< $storage->_dbh >> and declines to
act when that reference is empty, so the fake storage carries a stand-in handle
for it -- otherwise an assertion that a failing code path rolled back would pass
without a rollback ever having been attempted.

=head1 METHODS

=head2 connected

Always returns true. There is no real connection to check.

=head2 ensure_connected

No-op. We are always "connected".

=head2 disconnect

Sets connected state to false.

=head2 _execute

Overrides L<DBIO::Storage::DBI/_execute> to capture the generated
SQL and bind values instead of executing them.

The statement handle it returns yields the rows of a matching mock (see
L</mock>), or no rows when none matches.

=head2 _execute_rendered

Overrides L<DBIO::Storage::DBI/_execute_rendered> the same way L</_execute>
overrides the generated path: the already-rendered statement is captured
verbatim instead of executed, and answered from the mock results. The SQL that
lands in L</captured_queries> is byte-for-byte the SQL a real storage would
have handed to C<< $dbh->prepare >>.

=head2 _prepare_rendered

Overrides L<DBIO::Storage::DBI/_prepare_rendered>, the prepare-without-execute
seam a driver whose answer is an attribute of the B<prepared> statement uses
(ADR 0040 section 6; Firebird's query plan is the case). The statement is
captured and traced exactly as L</_execute_rendered> captures and traces one --
which is what lets a driver assert against the mock that its C<_explain_query>
went through the storage instead of reaching for the handle -- and a fake
statement handle is returned.

It is distinguishable in L</captured_queries>: the entry's C<op> is
C<'prepare'>, not C<'select'>. That is the one observable separating this seam
from L</_execute_rendered> on a storage that never executes anything anyway.

=head2 mock_affected_rows

  $storage->mock_affected_rows('0E0');   # what DBI returns for "no rows"
  $storage->mock_affected_rows(2);       # MySQL's "row was updated"
  $storage->mock_affected_rows(undef);   # back to the default of 1

What L</_execute> hands back as the statement return value for
C<insert>/C<update>/C<delete>. The default is C<1>; C<select> is unaffected.
Real DBI reports the string C<'0E0'> -- zero but true -- for a DML statement
that affected no rows, which is a shape no fake storage produces on its own and
which callers of C<< $rs->upsert(..., { result => 'count' }) >> or
C<< $rs->update >> can legitimately see.

=head2 captured_queries

Returns all captured queries as a list of hashrefs, each containing
C<op>, C<sql>, and C<bind> keys.

  my @queries = $storage->captured_queries;
  # ( { op => 'select', sql => 'SELECT ...', bind => [...] }, ... )

C<op> is the statement's operation -- C<select>, C<insert>, C<update>,
C<delete>, or C<prepare> for a statement that went through
L</_prepare_rendered> and was never executed. Transaction and savepoint
statements are logged with C<op> C<txn_begin>, C<txn_commit>, C<txn_rollback>,
C<svp_begin>, C<svp_release> or C<svp_rollback>.

=head2 captured_sql_bind

Returns captured queries as arrayrefs of C<[$sql, @bind]> pairs,
compatible with L<SQL::Abstract::Test/is_same_sql_bind>.

=head2 reset_captured

Clears the captured query log.

=head2 select

Returns a fake cursor that yields the rows of a matching mock (see L</mock>),
or no rows when none matches. The SQL is captured either way.

=head2 mock

  $storage->mock($sql_pattern, \@rows);
  $storage->mock($sql_pattern, \@rows, \@columns);
  $storage->mock(qr/SELECT.*FROM artist/i, [
    [1, 'Caterwauler McCrae'],
    [2, 'Random Boy Band'],
  ]);

Registers a mock result. When a query matches C<$sql_pattern> (string
or regexp), the given rows are returned. Mocks are checked in LIFO
order -- later mocks override earlier ones. Each mock is consumed once
unless registered with L</mock_persistent>.

=head2 mock_persistent

Like L</mock> but the mock is not consumed after matching -- it keeps
returning the same rows for every matching query.

=head2 clear_mocks

Removes all registered mocks, including the L</mock_func> answers.

=head2 mock_func

  $storage->mock_func( ib_plan => "PLAN (ARTIST NATURAL)\n" );
  $storage->mock_func( ib_plan => sub {
    my ($sth, $name, @args) = @_;
    $calls++;
    return $plan;
  });

Registers what the fake statement handle answers for a DBD-private
statement-handle function, i.e. DBI's C<< $sth->func($name, ...) >>.
Engines answer a question about a PREPARED statement through that
dispatcher rather than through an attribute -- Firebird's query plan is
C<< $sth->func('ib_plan') >>, read off a handle that was never executed --
which is why the answer is registered on the STORAGE (through
L</_prepare_rendered> / L</_execute_rendered> every fake statement handle
is built here) and not on some handle the driver never sees.

C<$answer> is returned for any C<< $sth->func($name, ...) >> call. It can be
a plain value, or a coderef, which is called with the fake handle, the
function name and any extra arguments, and whose return value is the
answer -- the coderef form is what a driver test uses to count calls.
Registering C<undef> explicitly is different from not registering the
function: the call then ANSWERS undef (the way a DBD that failed to
produce a value does) instead of falling through to the default.

Unregistered functions still answer undef. Registrations are per-storage
and survive across calls; L</clear_mocks> removes them along with the row
mocks. There is no glob on core internals involved, and no dependence on
when C<DBIO::Test::Storage> was loaded -- the answer travels with the
statement, not with the class.

=head2 set_auto_increment

  $storage->set_auto_increment('Artist', 10);

Sets the auto-increment counter for a source so the next insert
returns the given ID.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
