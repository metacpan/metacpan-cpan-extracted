package DBIO::SQLite::Test::Conformance;
# ABSTRACT: Answers the shared conformance case table for the SQLite driver

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Test::Conformance';

use DBIO::Exception ();
use DBIO::SQLite::Introspect ();
use DBIO::SQLite::Deploy ();



sub conformance_live_available {
  return eval { require DBD::SQLite; 1 } ? 1 : 0;
}


sub conformance_connect {
  my ($class, $schema_class) = @_;
  $schema_class->load_components('SQLite');
  return $schema_class->connect('dbi:SQLite::memory:', '', '', {
    AutoCommit => 1, RaiseError => 1, PrintError => 0,
    on_connect_call => 'use_foreign_keys',
    sqlite_unicode => 1,
  });
}


sub conformance_install {
  my ($class, $schema, $case) = @_;
  $schema->deploy;
  return;
}


sub conformance_cleanup {
  my ($class, $schema, $case, $namespace) = @_;
  $schema->storage->disconnect;
  return;
}


sub conformance_diff_is_empty {
  my ($class, $schema, $case) = @_;
  my $diff = DBIO::SQLite::Deploy->new(schema => $schema)->diff;
  return $diff->has_changes ? 0 : 1;
}


sub _conformance_target {
  my ($class, $schema, $to_class) = @_;
  my $dbh = $schema->storage->dbh;
  $to_class->load_components('SQLite');
  return $to_class->connect(sub { $dbh }, {
    AutoCommit => 1, RaiseError => 1, PrintError => 0,
    on_connect_call => 'use_foreign_keys',
  });
}

sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->_conformance_target($schema, $to_class);
  DBIO::SQLite::Deploy->new(schema => $to)->upgrade(allow_destructive => 1);
  return $to;
}


sub conformance_deploy {
  my ($class, $schema, $to_class, $case) = @_;
  return DBIO::SQLite::Deploy->new(
    schema => $class->_conformance_target($schema, $to_class),
  );
}


sub conformance_answered_through { { DDL => 2, Diff => 4, Bind => 1 } }


sub conformance_refusals {
  return {
    'diff-column-added-not-null-populated' => {
      kind   => 'server',
      reason => qr/NOT NULL without a default, and table base holds rows/,
    },
    'diff-not-null-over-nulls' => {
      kind   => 'server',
      reason => qr/holds rows where it is NULL/,
    },
    'bind-empty-string' => {
      kind   => 'deviation',
      fact   => qr/the server accepted a row it must reject/,
      reason => 'an INTEGER-affinity column keeps text that is not a '
              . 'well-formed integer as text, so SQLite stores the empty '
              . 'string in it (https://www.sqlite.org/datatype3.html, '
              . 'section 3); only a STRICT table rejects it',
    },
    'bind-numeric-exact' => {
      kind   => 'deviation',
      fact   => qr/read back '-?1\.23456789012346e\+15'/,
      reason => 'NUMERIC affinity turns a text that is no 64-bit integer '
              . 'into a REAL, and of a REAL only the first 15 significant '
              . 'digits are preserved (https://www.sqlite.org/datatype3.html, '
              . 'section 3.1); SQLite has no exact decimal type',
    },
    'ddl-type-size-char' => {
      kind   => 'deviation',
      fact   => qr/Sized: the server accepted a row it must reject/,
      reason => 'SQLite does not enforce the length of a CHARACTER(n) column: '
              . 'the declared size is kept for introspection, the value is '
              . 'stored whole (https://www.sqlite.org/datatype3.html, '
              . 'section 3.1); the driver adds no CHECK for it',
    },
    'ddl-qualified-source-name' => {
      kind   => 'server',
      reason => qr/no schemas to qualify a name with/,
    },
  };
}


sub conformance_fact {
  my ($class, $schema, $name, $args) = @_;
  my $intro = DBIO::SQLite::Introspect->new(dbh => $schema->storage->dbh);
  my $model = $intro->model;
  my $table = $args->{table};
  my $has   = exists $model->{tables}{$table} ? 1 : 0;
  my @cols  = @{ $args->{columns} || [] };
  my $same  = sub {
    my ($got) = @_;
    return 0 unless @$got == @cols;
    return (join("\0", @$got) eq join("\0", @cols)) ? 1 : 0;
  };

  if ($name eq 'object_kind') {
    return $has ? $model->{tables}{$table}{kind} : undef;
  }
  if ($name eq 'table_name') {
    return $has ? $table : undef;
  }
  if ($name eq 'table_in_namespace') {
    return 0 unless ($args->{namespace} // '') eq 'main';
    return exists $model->{tables}{ $args->{unqualified} } ? 1 : 0;
  }
  if ($name eq 'column_names') {
    return $intro->table_columns($table);
  }
  if ($name eq 'column_size') {
    return $intro->table_columns_info($table)->{ $args->{column} }{size};
  }
  if ($name eq 'column_auto_increment') {
    return $intro->table_columns_info($table)->{ $args->{column} }{is_auto_increment} ? 1 : 0;
  }
  if ($name eq 'primary_key_columns') {
    return $intro->table_pk_info($table);
  }
  if ($name eq 'unique_exists') {
    return (grep { $same->($_->[1]) } @{ $intro->table_uniq_info($table) }) ? 1 : 0;
  }
  if ($name eq 'foreign_key_count') {
    return scalar @{ $intro->table_fk_info($table) };
  }
  if ($name eq 'index_count') {
    my $indexes = $model->{indexes}{$table} || {};
    return scalar grep {
      ($_->{origin} || '') ne 'pk' and $same->($_->{columns})
    } values %$indexes;
  }

  DBIO::Exception->throw("unknown conformance fact '$name'");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Test::Conformance - Answers the shared conformance case table for the SQLite driver

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::SQLite::Test::Conformance;
  DBIO::SQLite::Test::Conformance->run('DDL');
  done_testing;

=head1 DESCRIPTION

The driver's half of the shared case table of L<DBIO::Test::Conformance>
(core ADR 0060). Core owns the cases and the runner; this class says how to
reach an in-memory SQLite database, how to install a declaration into it
through L<DBIO::SQLite::Deploy>, and how to read a fact back through
L<DBIO::SQLite::Introspect>.

SQLite needs no server and no gate: an in-memory database is a server, so
every case runs in a plain C<prove>. It has no namespaces either, and each
case gets a connection -- and with it a database -- of its own, so the
default L<DBIO::Test::Conformance/conformance_namespace> is enough.

The class is the one an extension dist reuses against its own composed
storage; it names no storage class and never decides the driver, the DSN
does (see L</conformance_connect>).

=head1 METHODS

=head2 conformance_live_available

True when L<DBD::SQLite> loads. There is nothing else to gate on.

=head2 conformance_connect

Loads the C<SQLite> schema component into the case's schema class and connects
to a private in-memory database. C<storage_type> is not set: the DSN selects
the driver and core composes the storage over it.

The connection asks for foreign key enforcement,
C<< on_connect_call => 'use_foreign_keys' >>
(L<DBIO::SQLite::Storage/connect_call_use_foreign_keys>). SQLite enforces
nothing until a connection says so, and the driver keeps that default; the
cases that need a key to hold -- C<ddl-foreign-key>, C<ddl-fk-actions> -- are
answered for a connection that opted in, which is how a SQLite application
that wants foreign keys connects.

It asks for C<< sqlite_unicode => 1 >> as well
(L<DBD::SQLite/sqlite_unicode>). Without it L<DBD::SQLite> returns text as the
bytes it stores, and the cases that bind characters (C<bind-non-ascii>) read
bytes back. The driver keeps that default, since an application may hold bytes
in a text column on purpose; one that wants characters connects like this.

=head2 conformance_install

Installs the declaration with C<< $schema->deploy >>, the public entry point,
which hands over to L<DBIO::SQLite::Deploy/install>.

=head2 conformance_cleanup

Disconnects. The database was in memory and goes with the connection.

=head2 conformance_diff_is_empty

True when L<DBIO::SQLite::Deploy/diff> of the installed database against the
same declaration has no changes.

=head2 conformance_upgrade

Connects the target schema class to the handle of the installed one, since a
C<:memory:> database is its connection, and runs
L<DBIO::Deploy::Base/upgrade> -- the public entry point -- through it with
C<< allow_destructive => 1 >>: the upgrade cases drop on purpose, and the
guard that holds a destructive diff back is the subject of
C<diff-deploy-destructive-guard>, not of these. The connection opts into
foreign keys like L</conformance_connect>. A refusal of the diff
(L<DBIO::SQLite::Diff::Column/Changes that are refused>) is thrown from here as
it came.

=head2 conformance_deploy

Connects like L</conformance_upgrade> and returns
C<< DBIO::SQLite::Deploy->new(schema => $to) >>, so the runner reaches
C<apply> and C<upgrade> of the deploy class itself: the cases
C<diff-deploy-inherited>, C<diff-deploy-dry-run> and
C<diff-deploy-destructive-guard> run for this driver.

=head2 conformance_answered_through

The table versions the answers were written against, per area:
C<< { DDL => 2, Diff => 4, Bind => 1 } >>, every list as it stands. Version 2
of the DDL list splits the type-size case into C<ddl-type-size-char> and
C<ddl-type-size-bit>, version 2 of the Diff list splits U13 into
C<diff-constraint-changed> and C<diff-fk-action-changed>, and every case of all three lists is answered: correctly,
or by a refusal or deviation of L</conformance_refusals>.

Version 3 of the Diff list replaces C<diff-column-dropped-with-index> by
C<diff-indexed-column-dropped>; it runs.

Version 4 of the Diff list adds the three deploy cases
(C<diff-deploy-inherited>, C<diff-deploy-dry-run>,
C<diff-deploy-destructive-guard>); they run through
L</conformance_deploy>.

=head2 conformance_refusals

Three declared refusals and three deviations.

C<ddl-qualified-source-name>: SQLite has no schemas to
qualify a table name with, so C<< table('other.t') >> as a string is refused
by L<DBIO::SQLite::Util/refuse_qualified_name> from the DDL, naming the table
and the scalar-ref form C<< \'other.t' >>, which stays literal SQL.

C<diff-column-added-not-null-populated> and C<diff-not-null-over-nulls>: SQLite
cannot give the rows a table holds a value for a new C<NOT NULL> column, nor
accept a C<NOT NULL> over a C<NULL>. L<DBIO::SQLite::Deploy/_refuse_unfillable>
refuses both before the first statement, naming table and column.

C<bind-empty-string> and C<bind-numeric-exact> run through and differ: SQLite
types the value, not the column. Text that is no integer is kept as text in an
C<INTEGER> column, and a C<NUMERIC> column keeps 15 significant digits of what
does not fit an integer. Both are the engine's documented rules (type affinity),
declared as deviations with the reason; only a C<STRICT> table, which the cases
do not declare, rejects the first.

C<ddl-type-size-char> runs through and differs: the size of C<CHARACTER(10)>
is written and read back, but SQLite never rejects eleven characters in it. It
does not enforce a declared length, and the driver adds no C<CHECK> to make it
(maintainer decision 2026-10-12), so this is declared a deviation.
The C<fact> is the runner's own failure text, so a different wrong answer is not
hidden behind it.

C<diff-constraint-changed> and C<diff-fk-action-changed> are not refused: this
driver applies both, by rebuilding the table (ADR 0003).

=head2 conformance_fact

Reads one fact through L<DBIO::SQLite::Introspect>; the vocabulary is the one
of L<DBIO::Test::Conformance/Facts>. SQLite has no namespaces, so
C<table_in_namespace> is true only for C<main> and a table that is there.

=head1 SEE ALSO

=over 4

=item * L<DBIO::Test::Conformance> - the runner and the contract of the seams

=item * L<DBIO::Test::Conformance::Cases::DDL> - the DDL case list

=item * L<DBIO::SQLite::Deploy> - install and diff, as the cases reach them

=item * L<DBIO::SQLite::Introspect> - what the facts are read through

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
