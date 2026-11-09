package DBIO::Informix::Diff::Table;
# ABSTRACT: Diff operations for Informix tables

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception;

use DBIO::Informix::Util qw(_quote_ident);
use DBIO::Informix::ColumnDef qw(column_def_sql);

__PACKAGE__->mk_diff_accessors(qw(table_name table_info columns replaced));



sub diff {
  my ($class, $source, $target, $target_columns) = @_;
  $target_columns //= {};

  my @ops;

  for my $name (sort keys %$target) {
    # A view that is in both with another definition is dropped and created.
    if (exists $source->{$name}) {
      my ($old, $new) = ($source->{$name}, $target->{$name});
      if (($old->{kind} // 'table') ne ($new->{kind} // 'table')) {
        # DROP TABLE would take the rows, DROP VIEW is not what the table is:
        # refused when the statement is asked for (as_sql), not simplified.
        my $op = $class->new(action => 'change', table_name => $name, table_info => $new);
        $op->{old_info} = $old;
        push @ops, $op;
      }
      elsif ( (($new->{kind} // '') eq 'view' and ($old->{definition} // '') ne ($new->{definition} // ''))) {
        push @ops, $class->new(action => 'drop', table_name => $name, table_info => $old, replaced => 1);
        push @ops, $class->new(action => 'create', table_name => $name, table_info => $new,
          columns => $target_columns->{$name} // []);
      }
      next;
    }
    push @ops, $class->new(
      action     => 'create',
      table_name => $name,
      table_info => $target->{$name},
      columns    => $target_columns->{$name} // [],
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


sub is_view {
  my ($self) = @_;
  return 0 if $self->action eq 'change';
  my $i = $self->table_info;
  return (ref $i eq 'HASH' && ($i->{kind} // '') eq 'view') ? 1 : 0;
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'change') {
    my $old = $self->{old_info}{kind} // 'table';
    DBIO::Exception->throw(sprintf
      "%s: the database has a %s and the schema a %s (a table and view of one name); "
      . "the rows of a table are not dropped to make a view, nor a view replaced by a table here",
      $self->table_name, $old, $old eq 'view' ? 'table' : 'view');
  }

  if ($self->is_view) {
    return sprintf 'DROP VIEW %s;', _quote_ident($self->table_name)
      if $self->action eq 'drop';
    # the definition is the CREATE VIEW the server keeps (owner-qualified)
    my $def = $self->table_info->{definition};
    DBIO::Exception->throw(sprintf 'view %s: the model holds no definition to write it from',
      $self->table_name) unless defined $def && length $def;
    return $def . ';';
  }

  if ($self->action eq 'drop') {
    return sprintf 'DROP TABLE %s;', _quote_ident($self->table_name);
  }

  my @col_defs;
  my @pk_cols;

  for my $col (@{ $self->columns }) {
    push @pk_cols, $col if $col->{is_pk};
    push @col_defs, '  ' . column_def_sql(
      name              => $col->{column_name},
      type              => $col->{data_type},
      size              => $col->{size},
      not_null          => $col->{not_null},
      default_value     => $col->{default_value},
      is_auto_increment => $col->{is_auto_increment},
    );
  }

  # The PK is a table-level constraint, in key order (pk_position);
  # columns without a position keep their table order.
  if (@pk_cols) {
    my @ordered = map { $_->{column_name} }
      sort { ($a->{pk_position} || 0) <=> ($b->{pk_position} || 0) } @pk_cols;
    push @col_defs, sprintf '  PRIMARY KEY (%s)',
      join(', ', map { _quote_ident($_) } @ordered);
  }

  return sprintf "CREATE TABLE %s (\n%s\n);",
    _quote_ident($self->table_name), join(",\n", @col_defs);
}


sub summary {
  my ($self) = @_;
  return sprintf '%s %s: %s', $self->summary_prefix,
    ($self->is_view ? 'view' : 'table'), $self->table_name;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Diff::Table - Diff operations for Informix tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a table-level diff operation in Informix: C<CREATE TABLE> or
C<DROP TABLE>. The SQL is generated directly from the introspected target
columns and the PK constraint inline. Foreign keys are never part of the
C<CREATE TABLE>: the referenced table may be created later in the same diff,
so they follow as C<ALTER TABLE ... ADD CONSTRAINT> from
L<DBIO::Informix::Diff::ForeignKey>.

=head1 ATTRIBUTES

=head2 replaced

True for the C<drop> of a view that is the first half of a C<drop> + C<create>
of that view with another definition: it replaces the view and drops none, so
it counts as changing, not destructive (core ADR 0080,
L<DBIO::Diff::Base/destructive_operations>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::Informix::Diff::Table->diff(
        $source_tables, $target_tables,
        $target_columns,
    );

Compares two table hashrefs (keyed by table name) and returns C<create>
ops for tables present only in target and C<drop> ops for tables only in
source. Custom walk (rather than C<DBIO::Diff::Op::diff_toplevel>) because
the C<create> op needs the target's column metadata inlined for
C<as_sql> to emit a complete C<CREATE TABLE> body.

=head2 is_view

True when the operation is on a view.

=head2 as_sql

Returns the SQL for this operation. For C<create>, emits a full
C<CREATE TABLE>. For C<drop>, emits C<DROP TABLE>.

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
