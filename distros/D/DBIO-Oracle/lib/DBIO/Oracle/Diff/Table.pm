package DBIO::Oracle::Diff::Table;
# ABSTRACT: Diff operations for Oracle tables

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception ();
use DBIO::Oracle::Identifier ();
use DBIO::Oracle::Type ();

__PACKAGE__->mk_diff_accessors(qw(table_name table_info columns unique_constraints sequences));



sub diff {
  my ($class, $source, $target, $target_columns, $target_unique, $source_columns) = @_;
  $target_columns //= {};
  $target_unique  //= {};
  $source_columns //= {};

  # A name both models have must be the same kind of object in both.
  for my $name (sort keys %{ $target // {} }) {
    next unless $source && exists $source->{$name};
    my ($was, $is) = map { _kind($_->{$name}) } $source, $target;
    next if $was eq $is;
    DBIO::Exception->throw(
      "DBIO::Oracle::Diff: $name is a $was in the source model and a $is in "
      . "the target model; the diff does not turn one into the other");
  }

  # Views are DBIO::Oracle::Diff::View's: created and dropped there.
  $source = { map { $_ => $source->{$_} } grep { _kind($source->{$_}) ne 'view' } keys %{ $source // {} } };
  $target = { map { $_ => $target->{$_} } grep { _kind($target->{$_}) ne 'view' } keys %{ $target // {} } };

  return $class->diff_toplevel(
    $source, $target,
    create => sub {
      my ($name) = @_;
      my $columns = $target_columns->{$name} // [];
      DBIO::Exception->throw(
        "DBIO::Oracle::Diff: cannot create table '$name': the target model "
        . 'holds no columns for it')
        unless @$columns;
      my $op = $class->new(
        action             => 'create',
        table_name         => $name,
        table_info         => $target->{$name},
        columns            => $columns,
        unique_constraints => $target_unique->{$name} // [],
      );
      $op->_auto_increment;   # refuses what cannot be written, before any SQL
      $op;
    },
    drop => sub {
      my ($name) = @_;
      $class->new(
        action     => 'drop',
        table_name => $name,
        table_info => $source->{$name},
        sequences  => [ $class->_owned_sequences(
          $name, $source->{$name}, $source_columns, $target_columns,
        ) ],
      );
    },
  );
}

# The sequences the install made for a table, from the columns of the source
# model: those of its own schema (the install makes no other), unless a column
# of another table of the target model is fed from the same one.
sub _owned_sequences {
  my ($class, $name, $info, $source_columns, $target_columns) = @_;
  my $schema = ref $info eq 'HASH' ? $info->{schema} : undef;

  my %used_elsewhere;
  for my $other (keys %$target_columns) {
    next if $other eq $name;
    $used_elsewhere{ $_->{sequence} } = 1
      for grep { defined $_->{sequence} } @{ $target_columns->{$other} };
  }

  my @seqs;
  for my $col (@{ $source_columns->{$name} // [] }) {
    next unless $col->{is_auto_increment}
      && defined $col->{sequence} && length $col->{sequence};
    next if $used_elsewhere{ $col->{sequence} };
    my ($seq_schema, $seq) = _split_sequence($col->{sequence}, $schema);
    next if defined $seq_schema && defined $schema && $seq_schema ne $schema;
    push @seqs, $seq;
  }
  return @seqs;
}

# ( schema, name ) of the model's "schema.sequence". The schema of the table is
# taken off when the name starts with it (a name may hold a dot), else the
# text before the first dot is the schema.
sub _split_sequence {
  my ($full, $table_schema) = @_;
  return ($table_schema, substr $full, length($table_schema) + 1)
    if defined $table_schema && index($full, "$table_schema.") == 0;
  return $full =~ /\A([^.]*)\.(.+)\z/s ? ($1, $2) : (undef, $full);
}


sub as_sql {
  my ($self) = @_;
  my $q = \&DBIO::Oracle::Identifier::quote;

  if ($self->action eq 'drop') {
    return join "\n",
      sprintf('DROP TABLE %s CASCADE CONSTRAINTS;', DBIO::Oracle::Identifier::quote_table($self->table_name)),
      map { sprintf 'DROP SEQUENCE %s;', DBIO::Oracle::Identifier::quote_in($self->table_name, $_) } @{ $self->sequences // [] };
  }

  my $table = $self->table_name;
  my @col_defs;
  my @pk_cols;

  for my $col (@{ $self->columns }) {
    push @pk_cols, $col if $col->{is_pk};

    my $def = sprintf '  %s %s', $q->($col->{column_name}), _oracle_type($col);

    # Handle default value. It goes before NOT NULL: Oracle's column
    # definition is "datatype [DEFAULT expr] [inline_constraint ...]" and it
    # refuses the other order.
    if (defined $col->{default_value}
        && (ref $col->{default_value} || $col->{default_value} ne 'null')) {
      $def .= ' DEFAULT '
        . DBIO::Oracle::Type::render_default_value($col->{default_value});
    }

    $def .= ' NOT NULL' if $col->{not_null};

    push @col_defs, $def;
  }

  if (@pk_cols) {
    # In the order of the constraint (pk_position, set by the introspection),
    # not of the table; columns without a position keep the table's order.
    my $i = 0;
    my @ordered = map { $_->[2] }
      sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] }
      map { [ $_->{pk_position} // 1e9, $i++, $_->{column_name} ] } @pk_cols;
    push @col_defs, sprintf '  PRIMARY KEY (%s)',
      join(', ', map { $q->($_) } @ordered);
  }

  for my $uc (@{ $self->unique_constraints }) {
    my ($name, $cols) = @$uc;
    push @col_defs, sprintf '  CONSTRAINT %s UNIQUE (%s)',
      $q->($name), join(', ', map { $q->($_) } @$cols);
  }

  my @stmts = sprintf "CREATE TABLE %s (\n%s\n);", DBIO::Oracle::Identifier::quote_table($table),
    join(",\n", @col_defs);

  # A sequence and the trigger that fills the column from it, as the install
  # writes them (DBIO::Oracle::DDL), after the table.
  for my $auto ($self->_auto_increment) {
    my ($col, $seq, $trg) = @$auto;
    push @stmts, sprintf 'CREATE SEQUENCE %s;', DBIO::Oracle::Identifier::quote_in($table, $seq);
    push @stmts, sprintf
      "CREATE OR REPLACE TRIGGER %s\n"
    . "BEFORE INSERT ON %s FOR EACH ROW WHEN (new.%s IS NULL)\n"
    . "BEGIN\n"
    . "  SELECT %s.NEXTVAL INTO :new.%s FROM DUAL;\n"
    . "END;",
      DBIO::Oracle::Identifier::quote_in($table, $trg), DBIO::Oracle::Identifier::quote_table($table),
      $q->($col), DBIO::Oracle::Identifier::quote_in($table, $seq), $q->($col);
  }

  return join "\n", @stmts;
}

# [ column, sequence, trigger ] for each column a sequence feeds. The model
# names the sequence with its schema, as the server spells them ("U.parent_id_seq"); the
# sequence is made in the schema of the table, so one of another is refused.
sub _auto_increment {
  my ($self) = @_;
  my $table  = $self->table_name;
  my $schema = ref $self->table_info eq 'HASH' ? $self->table_info->{schema} : undef;
  my @auto;

  for my $col (@{ $self->columns }) {
    next unless $col->{is_auto_increment};
    my $name = $col->{column_name};

    DBIO::Exception->throw(
      "DBIO::Oracle::Diff: cannot create table '$table': column '$name' is "
      . 'auto-increment without a sequence (a GENERATED ... AS IDENTITY '
      . 'column), and the model does not say whether the identity is ALWAYS '
      . 'or BY DEFAULT')
      unless defined $col->{sequence} && length $col->{sequence};

    my ($seq_schema, $seq) = _split_sequence($col->{sequence}, $schema);
    DBIO::Exception->throw(
      "DBIO::Oracle::Diff: cannot create table '$table': the sequence "
      . "'$col->{sequence}' of column '$name' is not one of the schema "
      . "'$schema' the table is in")
      if defined $seq_schema && defined $schema && $seq_schema ne $schema;

    push @auto, [
      $name, $seq,
      DBIO::Oracle::Identifier::shorten((DBIO::Oracle::Identifier::split_table($table))[1] . "_${name}_trg"),
    ];
  }
  return @auto;
}


sub summary {
  my ($self) = @_;
  return sprintf '%s %s: %s', $self->summary_prefix,
    _kind($self->table_info), $self->table_name;
}

# 'table' or 'view', as Introspect::Tables records it; a model without a kind
# holds tables.
sub _kind {
  my ($info) = @_;
  return ( ref $info eq 'HASH' && ( $info->{kind} // '' ) eq 'view' ) ? 'view' : 'table';
}

sub _oracle_type {
  my ($col) = @_;
  return DBIO::Oracle::Type::map_dbio_type_to_oracle(
    $col->{data_type} || 'VARCHAR2', size => $col->{size},
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Diff::Table - Diff operations for Oracle tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a table-level diff operation in Oracle: C<CREATE TABLE> or
C<DROP TABLE>. A C<create> op carries the whole table the way
L<DBIO::Oracle::DDL> writes it for the install: the columns with
their defaults and C<NOT NULL>, the primary key (from C<is_pk> and
C<pk_position> of the columns), the unique constraints by name, and, for a
column that a sequence feeds (C<is_auto_increment> and C<sequence>), the
C<CREATE SEQUENCE> and the C<BEFORE INSERT> trigger after the table. Every
name is written double-quoted, as the model spells it. The indexes of the new
table are L<DBIO::Oracle::Diff::Index>'s and its foreign keys
L<DBIO::Oracle::Diff::ForeignKey>'s, both after every C<CREATE TABLE>.

What the model does not carry is not invented. It holds the sequence a column
is filled from -- found by reading the C<BEFORE INSERT> trigger -- but neither
the name nor the text of that trigger; the diff writes the one the install
writes (C<table_column_trg>, shortened to 30 characters, C<WHEN (new.col IS
NULL)>, C<SELECT seq.NEXTVAL INTO :new.col FROM DUAL>), because the sequence is
in the model only for the trigger's sake. A hand-written trigger of another
shape therefore comes back in the install's form. A column that is
auto-increment without a sequence (C<GENERATED ... AS IDENTITY>) is refused
with a DBIO exception: the model does not say whether the identity is C<ALWAYS>
or C<BY DEFAULT>. So is a sequence of another schema than the table's, and a
table the model gives no columns (there is no C<CREATE TABLE X ( )>). The
model records the sequence as the server spells it (a quoted name in its own
case, a bare one in upper case) and it is written as that, quoted.

A C<drop> op also drops the sequences the install made for the table: C<DROP
TABLE> takes the trigger along, not the sequence. They are those of the
columns the source model has with C<is_auto_increment> and a C<sequence> of
the table's own schema. A C<GENERATED ... AS IDENTITY> column has no sequence
in the model (Oracle owns that one and drops it with the table), a sequence of
another schema is not the table's to drop, and one that a column of another
table of the target model is still fed from stays.

A name the model records as a view (C<kind> is C<view>) is not this class's:
views are L<DBIO::Oracle::Diff::View>'s. A name that is a table in
one model and a view in the other is refused with a DBIO exception naming the
object.

=head1 ATTRIBUTES

=head2 table_name

The table's key in the model: the bare name, or C<schema.table> for a table of
another schema, written C<"schema"."table">.

=head2 table_info

Hashref of table metadata from introspection (C<kind>, C<schema>, etc.).

=head2 columns

ArrayRef of column hashrefs for new tables (populated when C<action> is
C<create>), in the order of the table.

=head2 unique_constraints

ArrayRef of C<[ $name, \@columns ]> pairs, the unique constraints of a new
table (the C<unique_constraints> section of the model), written inline in the
C<CREATE TABLE>.

=head2 sequences

ArrayRef of sequence names (without schema) that a C<drop> op drops after the
table.

=head1 METHODS

=head2 diff

    my @ops = DBIO::Oracle::Diff::Table->diff(
        $source_tables, $target_tables,
        $target_columns, $target_unique_constraints, $source_columns,
    );

The last three are the C<columns> and C<unique_constraints> sections of the
target model and the C<columns> section of the source model, keyed by table
name. A table that only the target has needs columns there; one without is
refused. The source columns tell which sequences a dropped table leaves.

=head2 as_sql

=head2 summary

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
