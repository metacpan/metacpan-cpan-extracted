package DBIO::DuckDB::Test::Conformance;
# ABSTRACT: Answers the shared conformance case table for the DuckDB driver

use strict;
use warnings;

our $VERSION = '0.900004';

my $Name_schema_serial = 0;

use base 'DBIO::Test::Conformance';

use DBIO::Exception ();
use DBIO::DuckDB::Introspect ();
use DBIO::DuckDB::Deploy ();



sub conformance_live_available {
  return eval { require DBD::DuckDB; 1 } ? 1 : 0;
}


sub conformance_connect {
  my ($class, $schema_class) = @_;
  $schema_class->load_components('DuckDB');
  return $schema_class->connect('dbi:DuckDB:dbname=:memory:', '', '', {
    AutoCommit => 1, RaiseError => 1, PrintError => 0,
  });
}


sub conformance_install {
  my ($class, $schema, $case) = @_;
  $schema->deploy;
  return;
}


sub conformance_cleanup {
  my ($class, $schema, $case, $namespace) = @_;
  # the schema an upgrade returns shares the handle of the one it started
  # from, which the runner closes last; DBD::DuckDB 0.16 ends the process on
  # a second disconnect of one handle
  return if $schema->storage->{_conformance_shared_handle};
  $schema->storage->disconnect;
  return;
}


sub conformance_diff_is_empty {
  my ($class, $schema, $case) = @_;
  my $diff = DBIO::DuckDB::Deploy->new(schema => $schema)->diff;
  return $diff->has_changes ? 0 : 1;
}


sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  my $to = $class->_connect_target($schema, $to_class);
  DBIO::DuckDB::Deploy->new(schema => $to)->upgrade(allow_destructive => 1);
  return $to;
}


sub conformance_deploy {
  my ($class, $schema, $to_class, $case) = @_;
  return DBIO::DuckDB::Deploy->new(schema => $class->_connect_target($schema, $to_class));
}

sub _connect_target {
  my ($class, $schema, $to_class) = @_;
  my $dbh = $schema->storage->dbh;
  $to_class->load_components('DuckDB');
  my $to = $to_class->connect(sub { $dbh }, {
    AutoCommit => 1, RaiseError => 1, PrintError => 0,
  });
  $to->storage->{_conformance_shared_handle} = 1;
  return $to;
}


sub conformance_name_kinds { { extension => 1, library => 1 } }


sub conformance_apply_name {
  my ($class, $kind, $name) = @_;

  my $schema_class = 'DBIO::DuckDB::Test::Conformance::NameSchema'
    . (++$Name_schema_serial);
  {
    no strict 'refs';
    @{"${schema_class}::ISA"} = ('DBIO::Schema');
  }
  my $schema = $class->conformance_connect($schema_class);
  my @sql = eval {
    my $storage = $schema->storage;
    my $activation;
    if ($kind eq 'extension') {
      $schema_class->duckdb_extensions($name);
      $activation = $storage->_extension_activation(undef);
    }
    else {
      $activation = { load => [ $name ], search_path => [] };
    }
    $storage->_extension_activation_sql($activation);
  };
  my $err = $@;
  eval { $schema->storage->disconnect };
  die $err if $err;

  my ($shown) = map { /\ALOAD (\S+)\z/ ? $1 : () } @sql;
  DBIO::Exception->throw("conformance: no LOAD statement for the $kind name")
    unless defined $shown;
  return $shown;
}


sub conformance_answered_through { { DDL => 2, Diff => 4, Bind => 1 } }


sub conformance_refusals {
  return {
    'ddl-type-size-char' => {
      kind   => 'deviation',
      fact   => qr/Sized: the server accepted a row it must reject/,
      reason => 'DuckDB parses the length of VARCHAR(n) and ignores it: the '
              . 'value is stored whole, never truncated, and the column reads '
              . 'back as VARCHAR without a length '
              . '(https://duckdb.org/docs/stable/sql/data_types/text); the '
              . 'driver adds no CHECK for it',
    },
    'diff-column-added-not-null-populated' => {
      kind   => 'server',
      reason => qr/NOT NULL without a default, and table base holds rows/,
    },
    'diff-not-null-over-nulls' => {
      kind   => 'server',
      reason => qr/holds rows where it is NULL/,
    },
    'diff-column-type-change' => {
      kind   => 'deviation',
      fact   => qr/column_size of Num\.n: expected '20', the server shows NULL/,
      reason => 'DuckDB parses the length of VARCHAR(n) and ignores it, so '
              . 'the column reads back as VARCHAR without a length '
              . '(https://duckdb.org/docs/stable/sql/data_types/text); the '
              . 'type change itself and the rows are right',
    },
    'ddl-fk-actions' => {
      kind   => 'server',
      reason => qr/ON DELETE CASCADE is not available/,
    },
    'diff-table-added-complete' => {
      kind   => 'server',
      reason => qr/ON DELETE CASCADE is not available/,
    },
    'diff-fk-action-changed' => {
      kind   => 'server',
      reason => qr/ON DELETE CASCADE is not available/,
    },
    'ddl-type-size-bit' => {
      kind   => 'deviation',
      fact   => qr/column_size of Sized\.b: expected '8', the server shows NULL/,
      reason => 'BIT is a variable-length bitstring in DuckDB; a declared '
              . 'width is parsed and not kept, so the column reads back '
              . 'without a size '
              . '(https://duckdb.org/docs/stable/sql/data_types/bitstring)',
    },
  };
}


sub conformance_fact {
  my ($class, $schema, $name, $args) = @_;
  my $dbh   = $schema->storage->dbh;
  my $intro = DBIO::DuckDB::Introspect->new(dbh => $dbh);
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
    my ($n) = $dbh->selectrow_array(
      'SELECT count(*) FROM information_schema.tables '
      . 'WHERE table_schema = ? AND table_name = ?',
      undef, $args->{namespace}, $args->{unqualified},
    );
    return $n ? 1 : 0;
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

DBIO::DuckDB::Test::Conformance - Answers the shared conformance case table for the DuckDB driver

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::DuckDB::Test::Conformance;
  DBIO::DuckDB::Test::Conformance->run('DDL');
  done_testing;

=head1 DESCRIPTION

The driver's half of the shared case table of L<DBIO::Test::Conformance>
(core ADR 0060). Core owns the cases and the runner; this class says how to
reach an in-memory DuckDB database, how to install a declaration into it
through L<DBIO::DuckDB::Deploy>, and how to read a fact back through
L<DBIO::DuckDB::Introspect>.

DuckDB runs in the process and needs no server and no gate: every case runs in
a plain C<prove>. Each case gets a connection -- and with it a database -- of
its own, so the default L<DBIO::Test::Conformance/conformance_namespace> is
enough.

The class names no storage class and never decides the driver: the schema
component and the DSN do (see L</conformance_connect>).

=head1 METHODS

=head2 conformance_live_available

True when L<DBD::DuckDB> loads. There is nothing else to gate on.

=head2 conformance_connect

Loads the C<DuckDB> schema component into the case's schema class and connects
to a private in-memory database.

=head2 conformance_install

Installs the declaration with C<< $schema->deploy >>, the public entry point,
which hands over to L<DBIO::DuckDB::Deploy/install>.

=head2 conformance_cleanup

Disconnects. The database was in memory and goes with the connection. The
schema L</conformance_upgrade> returns is left to the runner, which closes
the schema it shares the handle with: DBD::DuckDB 0.16 segfaults on a second
C<disconnect> of one handle.

=head2 conformance_diff_is_empty

True when L<DBIO::DuckDB::Deploy/diff> of the installed database against the
same declaration has no changes.

=head2 conformance_upgrade

Connects the target schema class to the handle of the installed one, since a
C<:memory:> database is its connection, and runs
L<DBIO::DuckDB::Deploy/upgrade> -- the public entry point -- through it, with
C<< allow_destructive => 1 >>: the cases of the table are about what the diff
does (a dropped column, a dropped view, a changed type), the guard that holds a
destructive diff back has its own cases (C<diff-deploy-destructive-guard>, run
through L</conformance_deploy>). A refusal of the diff is thrown from here as it
came.

=head2 conformance_deploy

The deploy object over the target schema, for the deploy cases of the Diff list
(table version 4): the target class is connected to the handle of the installed
schema exactly as L</conformance_upgrade> connects it. Returns
C<< DBIO::DuckDB::Deploy->new(schema => $to) >>; the runner calls C<apply> and
C<upgrade> on it, and both are those of L<DBIO::Deploy::Base>.

=head2 conformance_name_kinds

C<< { extension => 1, library => 1 } >>: the names the driver writes into a
statement are the names of the extensions it C<INSTALL>s and C<LOAD>s
(L<DBIO::DuckDB::Storage/_activate_extensions>). DuckDB's extension and the
library it loads are one name, so both kinds run through the same statements.
There is no C<schema>: the connect key C<schema> has no meaning for this
driver and is refused by core (L<DBIO::DuckDB::Storage> does not implement
C<_set_connection_schema>), so the driver writes no namespace name from it.

=head2 conformance_apply_name

    my $shown = $class->conformance_apply_name($kind, $name);

Hands the name to the storage the way a declaration does -- C<extension>
through L<DBIO::DuckDB/duckdb_extensions> and the activation of the declared
list, C<library> through an activation that loads it -- and takes the
statements L<DBIO::DuckDB::Storage/_extension_activation_sql> writes for it.
A name the driver refuses throws its L<DBIO::Exception> from here. For a name
it accepts, the answer is the name as the C<LOAD> statement carries it. The
server is not asked: DuckDB has no extension of a made-up name, so an
C<INSTALL> of it would end in a server error, not in an answer about the
name; what the case checks is what the driver puts into the statement.

=head2 conformance_answered_through

The table versions the answers were written against, per area:
C<< { DDL => 2, Diff => 4, Bind => 1 } >> (version 2 of the Diff list splits U13
into C<diff-constraint-changed>, which runs, and C<diff-fk-action-changed>).
The Bind list needs no declaration: every one of its eleven cases is answered.

Version 3 of the Diff list replaces C<diff-column-dropped-with-index> by
C<diff-indexed-column-dropped>; it runs.

Version 4 of the Diff list adds the deploy cases (C<diff-deploy-*>):
they run through L</conformance_deploy>, which hands the runner the
L<DBIO::DuckDB::Deploy> object, so C<apply> and C<upgrade> are the base class's.

=head2 conformance_refusals

Five refusals and four deviations. Nothing is pending.

C<diff-indexed-column-dropped>, C<diff-fk-dropped> and
C<diff-fk-added-to-new-unique> run: DuckDB cannot drop a column while an index
or a C<UNIQUE> constraint stands on a later column ("an index depends on a
column after it"), cannot drop a constraint and has no C<ALTER TABLE ... ADD /
DROP FOREIGN KEY>
(L<https://duckdb.org/docs/stable/sql/statements/alter_table>), so the diff
rebuilds the table (L<DBIO::DuckDB::Diff::Rebuild>): a new table,
the rows copied, the old one dropped, the new one renamed, the indexes made
again. In C<diff-fk-added-to-new-unique> the parent is rebuilt as well, since
DuckDB takes a foreign key to a C<UNIQUE> constraint and not to a unique index.

C<ddl-fk-actions>, C<diff-table-added-complete> and C<diff-fk-action-changed>
declare C<ON DELETE CASCADE>. DuckDB enforces foreign keys but takes
C<RESTRICT> and C<NO ACTION> only: its parser refuses C<CASCADE>, C<SET NULL>
and C<SET DEFAULT> ("FOREIGN KEY constraints cannot use CASCADE, SET NULL or SET
DEFAULT"; L<https://duckdb.org/docs/stable/sql/constraints#foreign-keys>).
L<DBIO::DuckDB::DDL> refuses them first, naming table and column, before any
statement (maintainer decision 2026-10-25).

The deviations are of one kind: DuckDB parses a length it then drops.

C<diff-column-added-not-null-populated> and C<diff-not-null-over-nulls>:
DuckDB cannot give the rows a table holds a value for a new C<NOT NULL> column
(C<ADD COLUMN ... NOT NULL> is not supported at all,
L<https://duckdb.org/docs/stable/sql/statements/alter_table>), nor accept
C<SET NOT NULL> over a C<NULL>. L<DBIO::DuckDB::Deploy/_check_before_apply> refuses both
before the first statement, naming table and column (maintainer
decision 2026-10-25).

C<diff-column-type-change>: the type change and the rows are right; the
C<VARCHAR(20)> it ends in reads back without its length, as in
C<ddl-type-size-char>.

C<ddl-type-size-char>: C<VARCHAR(10)> is accepted, but the length has no
effect -- DuckDB stores the value whole, never truncates it, and shows the
column back as plain C<VARCHAR> with no length
(L<https://duckdb.org/docs/stable/sql/data_types/text>). The driver adds no
C<CHECK> to enforce it, so the case is declared a deviation. The C<fact> is the
runner's own failure text for the accepted row, so a different wrong answer is
not hidden behind it.

C<ddl-type-size-bit>: C<BIT> is DuckDB's variable-length bitstring
(L<https://duckdb.org/docs/stable/sql/data_types/bitstring>); a declared width
is parsed and not kept, so introspection shows no size.

=head2 conformance_fact

Reads one fact through L<DBIO::DuckDB::Introspect>; the vocabulary is the one
of L<DBIO::Test::Conformance/Facts>. DuckDB has namespaces (schemas), and the
cases declare a table in one only through a qualified name; C<table_in_namespace>
asks the catalog.

=head1 SEE ALSO

=over 4

=item * L<DBIO::Test::Conformance> - the runner and the contract of the seams

=item * L<DBIO::Test::Conformance::Cases::DDL> - the DDL case list

=item * L<DBIO::DuckDB::Deploy> - install and diff, as the cases reach them

=item * L<DBIO::DuckDB::Introspect> - what the facts are read through

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
