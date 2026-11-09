package DBIO::MSSQL::Diff::Table;
# ABSTRACT: Diff operations for MSSQL tables

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::MSSQL::DDL qw(_mssql_column_type _quote_ident _quote_table _constraint_name);


__PACKAGE__->mk_diff_accessors(qw/table_name table_info columns/);


sub view_names {
  my ($class, @sections) = @_;
  my %seen;
  for my $tables (@sections) {
    for my $name (keys %{ $tables // {} }) {
      my $kind = ref $tables->{$name} eq 'HASH' ? $tables->{$name}{kind} : undef;
      $seen{$name} = 1 if defined $kind && $kind eq 'view';
    }
  }
  return sort keys %seen;
}


sub diff {
  my ($class, $source, $target, $target_columns) = @_;
  $target_columns //= {};

  # a view is not a table: no CREATE TABLE for a declared one, no DROP TABLE
  # for a live one (a view is Diff::View's)
  my %is_view = map { $_ => 1 } $class->view_names($source, $target);
  $source = { map { $_ => $source->{$_} } grep { !$is_view{$_} } keys %$source };
  $target = { map { $_ => $target->{$_} } grep { !$is_view{$_} } keys %$target };

  return $class->diff_toplevel($source, $target,
    create => sub {
      my ($name) = @_;
      $class->new(
        action       => 'create',
        table_name => $name,
        table_info => $target->{$name},
        columns    => $target_columns->{$name} // [],
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


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'drop') {
    return sprintf 'DROP TABLE %s;', _quote_table($self->table_name);
  }

  my @col_defs;
  my @pk_cols;

  for my $col (@{ $self->columns }) {

    my $type = _mssql_column_type($col, $self->table_name, $col->{column_name});
    my $def = sprintf '  %s %s', _quote_ident($col->{column_name}), $type;
    $def .= ' NOT NULL' if $col->{not_null};
    if (defined $col->{default_value}) {
      $def .= " DEFAULT $col->{default_value}";
    }
    if ($col->{is_identity}) {
      $def .= ' IDENTITY(1,1)';
    }
    push @col_defs, $def;
  }

  @pk_cols = map { $_->{column_name} }
    sort { ($a->{pk_position} || 0) <=> ($b->{pk_position} || 0) }
    grep { $_->{is_pk} } @{ $self->columns };
  if (@pk_cols) {
    push @col_defs, sprintf '  CONSTRAINT %s PRIMARY KEY (%s)',
      _quote_ident(_constraint_name('PK', $self->table_name)),
      join(', ', map { _quote_ident($_) } @pk_cols);
  }

  return sprintf "CREATE TABLE %s (\n%s\n);",
    _quote_table($self->table_name), join(",\n", @col_defs);
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

DBIO::MSSQL::Diff::Table - Diff operations for MSSQL tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Table-level diff operations for MSSQL. Handles C<CREATE TABLE>, C<DROP TABLE>.
A model entry with C<< kind => 'view' >> is not a table: it gets neither
statement (see L</view_names>). C<create> ops capture the target columns so
C<as_sql> can emit the full inline definition. The table is created B<without>
its foreign keys: they are C<ALTER TABLE ... ADD CONSTRAINT> operations of
L<DBIO::MSSQL::Diff::ForeignKey>, which L<DBIO::MSSQL::Diff> runs after every
table exists (an inline C<FOREIGN KEY> needs its target to exist already, and
two new tables cannot reference each other that way). Built on
L<DBIO::Diff::Op> (the C<create>/C<drop> walk and accessor/summary plumbing).

=head1 METHODS

=head2 view_names

    my @views = DBIO::MSSQL::Diff::Table->view_names($tables, ...);

The sorted names of the entries of the given C<tables> sections of a model that
are views (C<< kind => 'view' >>). L<DBIO::MSSQL::Introspect::Tables> keeps
views in C<tables> beside the tables. A view is no table: this class gives it
no statement, L<DBIO::MSSQL::Diff::View> does. L<DBIO::MSSQL::Diff::Column>
and L<DBIO::MSSQL::Diff::Index> use this to leave out what hangs off a view.

=head2 diff

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
