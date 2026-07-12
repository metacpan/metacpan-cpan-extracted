package DBIO::PostgreSQL::Diff::Table;
# ABSTRACT: Diff operations for PostgreSQL tables

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::PostgreSQL::Introspect ();

__PACKAGE__->mk_diff_accessors(qw(schema_name table_name table_info columns));







sub diff {
  my ($class, $source, $target, $source_cols, $target_cols) = @_;
  my @ops;

  for my $key (sort keys %$target) {
    next if exists $source->{$key};
    my $t = $target->{$key};
    push @ops, $class->new(
      action      => 'create',
      schema_name => $t->{schema_name},
      table_name  => $t->{table_name},
      table_info  => $t,
      columns     => $target_cols->{$key} // [],
    );
  }

  for my $key (sort keys %$source) {
    next if exists $target->{$key};
    my $t = $source->{$key};
    push @ops, $class->new(
      action      => 'drop',
      schema_name => $t->{schema_name},
      table_name  => $t->{table_name},
      table_info  => $t,
    );
  }

  return @ops;
}


sub qualified_name {
  my ($self) = @_;
  return $self->schema_name . '.' . $self->table_name;
}


sub _identity_kind {
  return DBIO::PostgreSQL::Introspect->identity_kind(@_);
}

sub _column_def {
  my ($col) = @_;
  my $def = $col->{column_name} . ' ' . ($col->{data_type} // 'text');

  # NOT NULL
  $def .= ' NOT NULL' if $col->{not_null};

  # Default value
  if (defined $col->{default_value} && $col->{default_value} ne '') {
    $def .= sprintf ' DEFAULT %s', $col->{default_value};
  }

  # Identity
  my $kind = DBIO::PostgreSQL::Introspect->identity_kind($col->{identity});
  $def .= " GENERATED $kind AS IDENTITY" if $kind;

  # Generated columns (attgenerated = 's')
  $def .= ' GENERATED ALWAYS AS STORED' if $col->{generated} && $col->{generated} eq 's';

  return $def;
}

sub as_sql {
  my ($self) = @_;
  if ($self->action eq 'create') {
    my @col_defs = map { _column_def($_) } @{ $self->columns // [] };
    if (@col_defs) {
      return sprintf 'CREATE TABLE %s (%s);',
        $self->qualified_name, join ', ', @col_defs;
    }
    return sprintf 'CREATE TABLE %s ();', $self->qualified_name;
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'DROP TABLE %s CASCADE;', $self->qualified_name;
  }
}


sub summary {
  my ($self) = @_;
  return sprintf '  %stable: %s',
    ($self->action eq 'create' ? '+' : '-'), $self->qualified_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Table - Diff operations for PostgreSQL tables

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Represents a table-level diff operation: C<CREATE TABLE ...> (with full
column definitions for new tables) or C<DROP TABLE CASCADE>.
Instances are produced by L</diff> and consumed by L<DBIO::PostgreSQL::Diff>.

Diff::Column handles column ADDs for existing tables only; new tables get
their full column list inlined in the CREATE TABLE statement produced here.

=head1 ATTRIBUTES

=head2 schema_name

PostgreSQL schema containing the table.

=head2 table_name

The table name.

=head2 table_info

Hashref of table metadata from introspection (C<kind>, C<rls_enabled>, etc.).

=head2 columns

ArrayRef of column hashrefs for new tables (populated when C<action> is
C<create>), so that C<as_sql> can emit a complete CREATE TABLE with all
column definitions rather than an empty shell.

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Table->diff($source, $target, $source_cols, $target_cols);

Compares two table hashrefs (keyed by C<schema.table>) and returns operations
for tables present only in target (create) or only in source (drop).
For new tables, passes column metadata so C<as_sql> can emit a complete
CREATE TABLE with full column definitions (types, nullability, defaults,
identity). Diff::Column only handles ALTER for existing tables.

=head2 qualified_name

    my $fqn = $op->qualified_name;  # 'auth.users'

Returns the schema-qualified table name.

=head2 as_sql

Returns the SQL for this operation. For C<create>, emits a complete
CREATE TABLE with all column definitions inline (type, nullability,
default, identity). Diff::Column handles column ADDs for existing tables.

=head2 summary

Returns a one-line description such as C<+table: auth.users>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
