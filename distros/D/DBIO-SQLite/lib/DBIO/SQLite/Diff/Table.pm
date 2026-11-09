package DBIO::SQLite::Diff::Table;
# ABSTRACT: Diff operations for SQLite tables

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use Carp ();
use DBIO::SQLite::Util qw(default_value_sql quote_identifier type_with_size);
use namespace::clean;


__PACKAGE__->mk_diff_accessors(qw/
  table_name table_info columns foreign_keys unique_constraints reason
/);




sub diff {
  my ($class, $source, $target, $target_columns, $target_fks, $target_indexes) = @_;
  $target_columns //= {};
  $target_fks     //= {};
  $target_indexes //= {};

  # The generic create/drop walk lives in DBIO::Diff::Op->diff_toplevel; we
  # only supply the SQLite-shaped ops (create captures the target table entry,
  # whose sql as_sql emits, plus columns + FKs for a model that has none).
  return $class->diff_toplevel($source, $target,
    create => sub {
      my ($name) = @_;
      $class->new(
        action       => 'create',
        table_name   => $name,
        table_info   => $target->{$name},
        columns      => $target_columns->{$name} // [],
        foreign_keys => $target_fks->{$name}     // [],
        unique_constraints => _unique_column_lists($target_indexes->{$name}),
      );
    },
    drop => sub {
      my ($name) = @_;
      $class->new(
        action     => 'drop',
        table_name => $name,
        table_info => $source->{$name},
      );
    },
  );
}

# The column lists of the UNIQUE constraints in one table's index hash: the
# indexes of origin 'u', as a set (two constraints on the same columns are one),
# sorted so the text is the same every time.
sub _unique_column_lists {
  my ($indexes) = @_;
  my %seen;
  for my $idx (values %{ $indexes // {} }) {
    next unless ($idx->{origin} // '') eq 'u';
    my @cols = @{ $idx->{columns} // [] };
    next unless @cols;
    $seen{ join "\0", @cols } = \@cols;
  }
  return [ map { $seen{$_} } sort keys %seen ];
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'drop') {
    return sprintf 'DROP TABLE %s;', quote_identifier($self->table_name);
  }

  Carp::croak(sprintf 'Cannot change table %s: %s',
    $self->table_name, $self->reason)
    if $self->action eq 'refuse';

  # The statement the target was created with, when the model has it. Nothing
  # below can reproduce it from the columns (karr k56).
  my $sql = ($self->table_info // {})->{sql};
  if (defined $sql && length $sql) {
    $sql .= ';' unless $sql =~ /;\s*$/;
    return $sql;
  }

  # The key columns in the order of the key, which pk_position holds and which
  # need not be the order of the columns (karr k68). A model that gives no
  # position keeps the column order.
  my @columns = @{ $self->columns };
  my @pk_cols = map { $columns[$_]{column_name} }
    sort {
      ($columns[$a]{pk_position} // 0) <=> ($columns[$b]{pk_position} // 0)
        || $a <=> $b
    }
    grep { $columns[$_]{is_pk} } 0 .. $#columns;
  my @col_defs;

  for my $col (@{ $self->columns }) {
    my $type = type_with_size($col->{data_type} // 'TEXT', $col->{size});
    my $def = sprintf '  %s %s', quote_identifier($col->{column_name}), $type;

    # A single-column key goes on the column, which for the type INTEGER is
    # what makes it the rowid alias. PRAGMA table_xinfo reports that type as
    # plain INTEGER, so the key is not "already in the type" -- leaving it out
    # here left the table without one.
    $def .= ' PRIMARY KEY' if @pk_cols == 1 && $col->{is_pk};

    $def .= ' NOT NULL' if $col->{not_null};
    if (defined $col->{default_value}) {
      $def .= ' DEFAULT ' . default_value_sql($col->{default_value});
    }
    push @col_defs, $def;
  }

  # A multi-column key can only be a table-level constraint.
  if (@pk_cols > 1) {
    push @col_defs, sprintf '  PRIMARY KEY (%s)',
      join(', ', map { quote_identifier($_) } @pk_cols);
  }

  for my $cols (@{ $self->unique_constraints // [] }) {
    push @col_defs, sprintf '  UNIQUE (%s)',
      join(', ', map { quote_identifier($_) } @$cols);
  }

  for my $fk (@{ $self->foreign_keys }) {
    push @col_defs, sprintf '  FOREIGN KEY (%s) REFERENCES %s(%s)',
      join(', ', map { quote_identifier($_) } @{ $fk->{from_columns} }),
      quote_identifier($fk->{to_table}),
      join(', ', map { quote_identifier($_) } @{ $fk->{to_columns} });
  }

  return sprintf "CREATE TABLE %s (\n%s\n);",
    quote_identifier($self->table_name), join(",\n", @col_defs);
}


sub summary {
  my ($self) = @_;
  return sprintf '! table: %s (refused: %s)', $self->table_name, $self->reason
    if $self->action eq 'refuse';
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '%s table: %s', $prefix, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Diff::Table - Diff operations for SQLite tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a table-level diff operation in SQLite: C<CREATE TABLE> or
C<DROP TABLE>. Unlike PostgreSQL, where the table shell can be created
empty and columns added one at a time, SQLite wants the full table
definition at once -- most of what makes a table (a rowid alias, C<UNIQUE>,
C<CHECK>, C<WITHOUT ROWID>, C<STRICT>, generated columns) cannot be added to
it afterwards at all.

So a C<create> emits the statement the target table was created with: the
C<sql> of C<sqlite_master>, which L<DBIO::SQLite::Introspect::Tables> puts
into the model and L<DBIO::SQLite::Diff::Rebuild> has always reused for the
same reason (ADR 0003). An introspected model cannot be turned back into that
statement. C<PRAGMA table_xinfo> reports C<id INTEGER PRIMARY KEY> as the type
C<INTEGER>, a C<UNIQUE> constraint shows up only as an automatic index, and a
C<CHECK> or a column's C<COLLATE> not at all -- a table rebuilt from the
columns loses them without a word.

Only a model that has no statement is rebuilt from its columns: the one
L<DBIO::SQLite::Diff/target_from_compiled> produces, which has no database
behind it. See L</as_sql> for what that rebuild carries.

A B<virtual table> (C<CREATE VIRTUAL TABLE>) is created and dropped by the
same two ops: its C<create> is its stored statement, and C<DROP TABLE> is how
SQLite removes one. A view is not a table and never comes here
(L<DBIO::SQLite::Diff::View>).

=head2 Changes that are refused

A third action, C<refuse>, stands for a change of a table that no statement
of this driver carries out. L<DBIO::SQLite::Diff> emits it for a virtual table
that both models have and that is not the same in them: its definition
differs, or it is a virtual table in one model and a plain one in the other.
SQLite cannot alter a virtual table (C<virtual tables may not be altered>),
and the rebuild that brings a plain table to a new shape would copy what
C<SELECT> shows of it and lose whatever else its module stores.

L</as_sql> of such an op throws, in one line that names the table and the
L</reason>; L</summary> still lists it. That is the way of
L<DBIO::SQLite::Diff::Column/Changes that are refused>, and it has the same
consequence: the diff reports the change, C<as_sql> of the whole diff throws,
and L<DBIO::SQLite::Deploy/apply> throws before it has run a statement.

=head1 ATTRIBUTES

=head2 unique_constraints

For a C<create> op: the column lists of the target table's C<UNIQUE>
constraints, an arrayref of arrayrefs, each in the order of the constraint's
columns, sorted and without duplicates. C<as_sql> writes them for a model that
has no C<sql>.

=head2 reason

For a C<refuse> op: what differs and why it cannot be carried out, as the
exception and the summary say it.

=head1 METHODS

=head2 diff

    my @ops = DBIO::SQLite::Diff::Table->diff(
        $source_tables, $target_tables,
        $target_columns, $target_fks, $target_indexes,
    );

Compares two table hashrefs (keyed by table name) and returns C<create>
ops for tables present only in target and C<drop> ops for tables only in
source. C<create> ops capture the target table entry (with its C<sql>, if the
model has one) and the target columns, FKs and C<UNIQUE> column lists (from
the indexes of origin C<u>), which C<as_sql> falls back to without it.

=head2 as_sql

Returns the SQL for this operation. For C<drop>, emits C<DROP TABLE>. Every
name the op writes itself is quoted (L<DBIO::SQLite::Util/quote_identifier>):
C<DROP TABLE "item";>.

For C<refuse> it throws (L</Changes that are refused>):

    Cannot change table docs: its definition as a virtual table differs
    from the target's, and SQLite cannot alter a virtual table -- ...

For C<create> there are two cases:

=over 4

=item * B<The target table entry has C<sql>> (every introspected model, so
every L<DBIO::SQLite::Deploy> upgrade): that statement is returned as it is,
with a terminating semicolon. Whatever C<sqlite_master> holds for the name
comes out, so a virtual table new in the target is emitted as its C<CREATE
VIRTUAL TABLE>.

=item * B<It has none> (L<DBIO::SQLite::Diff/target_from_compiled>, or a model
built by hand): a C<CREATE TABLE> is rebuilt from the columns. It carries each
column's type, C<NOT NULL> and C<DEFAULT> (an expression default in
parentheses, see L<DBIO::SQLite::Util/default_value_sql>), the primary key --
on the column for a single-column key, which makes an C<INTEGER> one the rowid
alias, as a table constraint for several columns, in the order of the key
(C<pk_position>; columns that have none keep their column order) -- and the
model's C<UNIQUE> constraints as C<UNIQUE (...)> table constraints,
read from the table's indexes of origin C<u>, one per set of columns, and its
foreign keys as C<FOREIGN KEY (...) REFERENCES ...>.

It does B<not> carry C<ON DELETE> / C<ON UPDATE>, C<CHECK>, C<COLLATE>,
C<AUTOINCREMENT>, C<WITHOUT ROWID>, C<STRICT> or generated columns. A compiled
model has neither indexes nor foreign keys (the core's model compiler yields
none), so a table created from one has no C<UNIQUE> and no foreign key: it is
usable, but it is not the table L<DBIO::SQLite::DDL> creates for the same
result class.

=back

=head2 summary

C<+ table: name> or C<- table: name>; for a C<refuse> op C<! table: name
(refused: reason)>. It never throws.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
