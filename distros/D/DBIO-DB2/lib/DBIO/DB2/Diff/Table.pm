package DBIO::DB2::Diff::Table;
# ABSTRACT: Diff operations for DB2 tables

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::DB2::Type qw(_db2_column_type);
use DBIO::DB2::DDL qw(
  _fk_constraint_clause _db2_quote_ident _db2_quote_table _db2_identity_clause
  _unique_constraint_clause _refuse_nullable_unique
);


__PACKAGE__->mk_diff_accessors(qw/table_name table_info columns foreign_keys unique_constraints/);


sub diff {
  my ($class, $source, $target, $target_columns, $target_fks, $target_ucs) = @_;
  $target_columns //= {};
  $target_fks     //= {};
  $target_ucs     //= {};

  # A view is no table: DBIO::DB2::Diff::View has the operations for it (karr
  # k45, ADR 0011). A name that is a table on one side and a view on the other
  # is a table to drop, or to create, here.
  $source = _without_views($source);
  $target = _without_views($target);

  my @ops;

  for my $name (_fk_order($target, $target_fks, $source)) {
    push @ops, $class->new(
      action       => 'create',
      table_name   => $name,
      table_info   => $target->{$name},
      columns      => $target_columns->{$name} // [],
      foreign_keys => $target_fks->{$name}     // [],
      unique_constraints => $target_ucs->{$name} // [],
    );
  }

  for my $name (sort keys %$source) {
    next if exists $target->{$name};
    push @ops, $class->new(
      action     => 'drop',
      table_name => $name,
      table_info => $source->{$name},
    );
  }

  return @ops;
}

# The tables of $target that $source lacks, in the order they can be created:
# the FKs of a new table are inline in its CREATE TABLE, so the table a key
# references has to be there first (SQL0204N otherwise, karr k57). Depth first
# in name order, so tables that depend on nothing keep the name order. A
# self-reference and a reference to a table that exists already or is not new
# count for nothing; a cycle, which no order can create, is cut where it is met.
sub _fk_order {
  my ($target, $fks, $source) = @_;
  my %new = map { $_ => 1 } grep { !exists $source->{$_} } keys %$target;
  my (@order, %seen);
  _fk_visit($_, \%new, $fks, \%seen, \@order) for sort keys %new;
  return @order;
}

sub _fk_visit {
  my ($name, $new, $fks, $seen, $order) = @_;
  return if $seen->{$name}++;
  _fk_visit($_, $new, $fks, $seen, $order) for sort grep { defined && $new->{$_} && $_ ne $name }
    map { $_->{to_table} } @{ $fks->{$name} || [] };
  push @$order, $name;
  return;
}

sub _without_views {
  my ($tables) = @_;
  return { map { $_ => $tables->{$_} }
    grep { (($tables->{$_} || {})->{kind} // 'table') ne 'view' } keys %{ $tables || {} } };
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'drop') {
    return sprintf 'DROP TABLE %s;', _db2_quote_table($self->table_name);
  }

  my @col_defs;
  my @pk_cols;

  for my $col (@{ $self->columns }) {
    push @pk_cols, $col->{column_name} if $col->{is_pk};

    my $type = _db2_column_type($col->{catalog_type}, $col->{catalog_size}, $col->{column_name});
    my $def = sprintf '  %s %s', _db2_quote_ident($col->{column_name}), $type;
    $def .= ' NOT NULL' if $col->{not_null};
    if ($col->{is_auto_increment}) {
      $def .= ' ' . _db2_identity_clause();
    }
    elsif (defined $col->{catalog_default}) {
      # As it is: the model's default_value is SYSCAT.COLUMNS.DEFAULT, which is
      # the SQL text of the default already ('it''s', 0, CURRENT TIMESTAMP).
      # Quoting it once more made the text itself the default (karr k41).
      $def .= ' DEFAULT ' . $col->{catalog_default};
    }
    push @col_defs, $def;
  }

  if (@pk_cols) {
    push @col_defs, sprintf '  PRIMARY KEY (%s)',
      join(', ', map { _db2_quote_ident($_) } @pk_cols);
  }

  # Named inline UNIQUE constraints, the clause of install_ddl (karr k39, ADR
  # 0009). A nullable column is refused as there; the columns of this op are
  # the catalog shape, so not_null is the test.
  my %not_null = map { $_->{column_name} => $_->{not_null} } @{ $self->columns };
  for my $uc (@{ $self->unique_constraints || [] }) {
    my ($name, $cols) = @$uc;
    _refuse_nullable_unique($self->table_name, $name,
      [ grep { !$not_null{$_} } @$cols ]);
    push @col_defs, '  ' . _unique_constraint_clause($name, $cols);
  }

  # Named inline FK constraints, rendered through the same shared clause builder
  # as DBIO::DB2::DDL->install_ddl so a table created via the diff apply/upgrade
  # path gets the deterministic fk_<table>_<cols> name and its ON DELETE/UPDATE
  # rule -- both come straight from the target model. Without this, the server
  # would assign a random FK name (the next compare phantom-drops+adds it) and
  # the referential rule would be silently lost (ADR 0005).
  for my $fk (@{ $self->foreign_keys }) {
    push @col_defs, '  ' . _fk_constraint_clause($fk);
  }

  return sprintf "CREATE TABLE %s (\n%s\n);",
    _db2_quote_table($self->table_name), join(",\n", @col_defs);
}


sub summary {
  my ($self) = @_;
  return sprintf '%s table: %s', $self->summary_prefix, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Diff::Table - Diff operations for DB2 tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a table-level diff operation in DB2: C<CREATE TABLE> or
C<DROP TABLE>. C<create> ops capture the target columns and foreign keys
so C<as_sql> can emit the full inline definition in a single statement.

The columns of a C<create> op are read out of the catalog of the compare
schema by L<DBIO::DB2::Introspect::Columns/fetch>, and C<as_sql> renders the
internal catalog fields (ADR 0013), not the normalized ones and not the shape of
a result class:

=over 4

=item * C<catalog_type> is C<TYPENAME> and C<catalog_size> the catalog's
length. L<DBIO::DB2::Type> leaves it out for the types Db2 declares without one
(C<INTEGER>, not C<INTEGER(4)>).

=item * C<catalog_default> is the SQL text of the default and is written as it
is. C<_db2_default_literal>, which L<DBIO::DB2::DDL> uses on the value of a
result class, would quote it a second time.

=item * A column with C<is_auto_increment> gets the identity clause
L<DBIO::DB2::DDL/install_ddl> writes. The model does not carry the identity's
own attributes, so it is always C<START WITH 1, INCREMENT BY 1>.

=back

C<new>, the C<action> accessor and C<summary_prefix> come from
L<DBIO::Diff::Op>.

=head1 METHODS

=head2 diff

    my @ops = DBIO::DB2::Diff::Table->diff(
        $source_tables, $target_tables,
        $target_columns, $target_fks, $target_unique_constraints,
    );

The optional last argument is the C<unique_constraints> section of the target
model (C<< { $table => [ [ $name, \@columns ], ... ] } >>); a C<create> op
renders them inline, the clause L<DBIO::DB2::DDL/install_ddl> writes.

Entries of kind C<view> are left out on both sides: L<DBIO::DB2::Diff::View>
creates and drops them (ADR 0011).

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
