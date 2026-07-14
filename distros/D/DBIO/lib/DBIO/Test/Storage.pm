package DBIO::Test::Storage;
# ABSTRACT: Fake storage for testing SQL generation without a database

use strict;
use warnings;

use base qw(DBIO::Storage::DBI);
use mro 'c3';

use DBIO::Storage::Statistics;


__PACKAGE__->datetime_parser_type('DBIO::Test::DateTimeParser');

__PACKAGE__->mk_group_accessors(simple => qw(
  _captured_queries
  _fake_connected
  _mock_results
  _last_insert_ids
  _auto_increment
));

sub new {
  my $self = shift->next::method(@_);
  $self->_captured_queries([]);
  $self->_fake_connected(1);
  $self->_mock_results([]);
  $self->_last_insert_ids({});
  $self->_auto_increment({});
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

# We don't have a real dbh, so never call anything that needs one
sub _dbh { undef }
sub _get_dbh { undef }
sub _server_info { { dbms_version => 0, normalized_dbms_version => 0 } }

sub _determine_driver {
  $_[0]->{_driver_determined} = 1;
  return '';
}
sub _init {}
sub _rebless {}
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

  push @{ $self->_captured_queries }, {
    op   => $op,
    sql  => $sql,
    bind => $bind,
  };

  $self->_query_start($sql, $bind);
  $self->_query_end($sql, $bind);

  # Track inserts for last_insert_id
  if ($op eq 'insert') {
    my $source_name = ref $ident ? $ident->name : ($ident || '');
    my $id = $self->_next_auto_id($source_name);
    $self->_last_insert_ids->{$source_name} = $id;
  }

  # Check for mock results
  my $mock = $self->_find_mock($sql);
  my $fake_sth = DBIO::Test::Storage::FakeSth->new($mock ? $mock->{rows} : undef);

  # For DML operations (insert/update/delete), return 1 (row affected)
  # For select, return '0E0' (zero but true)
  my $rv = ($op =~ /^(?:insert|update|delete)$/) ? 1 : '0E0';

  return (wantarray ? ($rv, $fake_sth, @{$bind||[]}) : $rv);
}


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

  # Generate SQL for capture but don't actually execute
  my $sql = sprintf('INSERT INTO %s (%s) VALUES (%s)',
    $source->name,
    join(', ', @$cols),
    join(', ', ('?') x @$cols),
  );
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

# ---- Fake statement handle ----

{
  package DBIO::Test::Storage::FakeSth;

  sub new {
    my ($class, $rows) = @_;
    bless {
      rows => $rows || [],
      pos  => 0,
    }, ref $class || $class;
  }

  sub fetchrow_array {
    my $self = shift;
    return () if $self->{pos} >= scalar @{$self->{rows}};
    my $row = $self->{rows}[$self->{pos}++];
    return ref $row eq 'ARRAY' ? @$row : @$row;
  }

  sub fetchrow_hashref { undef }
  sub finish { 1 }
  sub execute { '0E0' }
  sub bind_param { 1 }
  sub rows { scalar @{$_[0]->{rows}} }
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
    return () if $self->{pos} >= scalar @{$self->{rows}};
    my $row = $self->{rows}[$self->{pos}++];
    return ref $row eq 'ARRAY' ? @$row : @$row;
  }

  sub all {
    my $self = shift;
    my @all;
    while (my @row = $self->next) {
      push @all, \@row;
    }
    $self->{pos} = 0;
    return @all;
  }

  sub reset {
    $_[0]->{pos} = 0;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Storage - Fake storage for testing SQL generation without a database

=head1 VERSION

version 0.900002

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

Returns an empty result set.

=head2 captured_queries

Returns all captured queries as a list of hashrefs, each containing
C<op>, C<sql>, and C<bind> keys.

  my @queries = $storage->captured_queries;
  # ( { op => 'select', sql => 'SELECT ...', bind => [...] }, ... )

=head2 captured_sql_bind

Returns captured queries as arrayrefs of C<[$sql, @bind]> pairs,
compatible with L<SQL::Abstract::Test/is_same_sql_bind>.

=head2 reset_captured

Clears the captured query log.

=head2 select

Returns a cursor that yields no rows.

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

Removes all registered mocks.

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
