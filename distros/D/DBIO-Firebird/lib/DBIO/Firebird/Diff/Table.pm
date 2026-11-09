package DBIO::Firebird::Diff::Table;
# ABSTRACT: Diff operations for Firebird tables

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Exception ();
use DBIO::Firebird::Diff::Constraint ();
use DBIO::Firebird::DDL qw(_firebird_quote_ident _firebird_column_clauses);
use DBIO::Firebird::Type qw(render_size);


# new() and the action accessor come from DBIO::Diff::Op.
__PACKAGE__->mk_diff_accessors(qw/table_name table_info columns foreign_keys old_info/);


sub diff {
  my ($class, $source, $target, $target_columns, $target_fks, $source_columns, $source_fks) = @_;
  $source_fks //= {};
  $target_columns //= {};
  $target_fks     //= {};

  my @ops;

  for my $name (sort keys %$target) {
    next if exists $source->{$name};
    next if ($target->{$name}{kind} // 'table') eq 'view';
    push @ops, $class->new(
      action       => 'create',
      table_name   => $name,
      table_info   => $target->{$name},
      columns      => $target_columns->{$name} // [],
      foreign_keys => $target_fks->{$name}     // [],
    );
  }

  # DROP TABLE of a table another table's foreign key points at is refused, so
  # the tables go child before parent (karr k34). Only keys between tables
  # dropped here count. Where tables point at each other no order exists: the
  # keys among the rest are dropped first (ALTER TABLE ... DROP CONSTRAINT),
  # then the tables.
  my %gone = map { $_ => 1 } grep { !exists $target->{$_} && ($source->{$_}{kind} // 'table') ne 'view' } keys %$source;
  my %refs;    # parent => { child => [ fk, ... ] }
  for my $child (keys %gone) {
    for my $fk (@{ $source_fks->{$child} // [] }) {
      my $parent = $fk->{to_table};
      next unless defined $parent && $gone{$parent} && $parent ne $child;
      push @{ $refs{$parent}{$child} }, $fk;
    }
  }
  my %left = %gone;
  while (%left) {
    # droppable now: no table still left points at it
    my @now = sort grep { my $p = $_; !grep { $left{$_} } keys %{ $refs{$p} // {} } } keys %left;
    unless (@now) {
      # a cycle: drop every key among the tables left, then they are all free
      for my $parent (sort keys %left) {
        for my $child (sort grep { $left{$_} } keys %{ $refs{$parent} // {} }) {
          push @ops, DBIO::Firebird::Diff::Constraint->new(
            action => 'drop', kind => 'fk', table_name => $child,
            constraint_name => $_->{constraint_name}, info => $_,
          ) for @{ $refs{$parent}{$child} };
        }
      }
      %refs = map { $_ => {} } keys %left;
      next;
    }
    for my $name (@now) {
      push @ops, $class->new(
        action     => 'drop',
        table_name => $name,
        table_info => $source->{$name},
      );
      delete $left{$name};
    }
  }

  # A name that is a table on one side and a view on the other: the data of
  # the table or the definition of the view would be lost, so no statement is
  # written (refusal). A view on both sides is Diff::View's.
  for my $name (sort keys %$target) {
    next unless exists $source->{$name};
    my ($was, $is) = map { ($_->{$name}{kind} // 'table') } $source, $target;
    next if $was eq $is;
    push @ops, $class->new(
      action     => 'change',
      table_name => $name,
      table_info => $target->{$name},
      old_info   => $source->{$name},
    );
  }

  return @ops;
}


sub refusal {
  my ($self) = @_;
  my ($is, $was) = map { $_ // '' } (($self->table_info // {})->{kind}, ($self->{old_info} // {})->{kind});
  return unless $self->action eq 'change' && $is ne $was;
  return sprintf 'the database has a %s and the schema a %s under this name', $was || 'table', $is || 'table';
}


sub refusal_error {
  my ($class, @ops) = @_;
  return join "\n",
    sprintf('refusing to diff %d name%s that change%s between table and view',
      scalar @ops, (@ops == 1 ? '' : 's'), (@ops == 1 ? 's' : '')),
    '',
    (map { sprintf '  %s: %s', _firebird_quote_ident($_->table_name), $_->refusal } @ops),
    '',
    'Turning a table into a view (or a view into a table) would drop the one to',
    'create the other. Drop it yourself, then run the diff again. No statement was',
    'generated. The difference is still reported by diff, has_changes and summary.',
    '', '';
}


sub as_sql {
  my ($self) = @_;

  DBIO::Exception->throw(ref($self)->refusal_error($self)) if $self->refusal;

  if ($self->action eq 'drop') {
    return sprintf 'DROP TABLE %s;', _firebird_quote_ident($self->table_name);
  }

  my @col_defs;
  my @pk_cols;

  for my $col (@{ $self->columns }) {
    push @pk_cols, $col->{column_name} if $col->{is_pk};

    my $type = $col->{data_type} || 'VARCHAR';
    my $def = sprintf '  %s %s%s', _firebird_quote_ident($col->{column_name}), $type,
      render_size($col->{size});
    # IDENTITY, DEFAULT, NOT NULL: the one order of the column clause, shared
    # with install_ddl (karr k46).
    $def .= _firebird_column_clauses(
      identity => $col->{is_auto_increment},
      default  => $col->{default_value},
      not_null => $col->{not_null},
    );
    push @col_defs, $def;
  }

  if (@pk_cols) {
    push @col_defs, sprintf '  PRIMARY KEY (%s)',
      join(', ', map { _firebird_quote_ident($_) } @pk_cols);
  }

  # No foreign key here: they are ALTER TABLE ... ADD CONSTRAINT after every
  # table of the diff (DBIO::Firebird::Diff::Constraint, karr k34), so the
  # order of the tables and a cycle between them do not matter.

  return sprintf "CREATE TABLE %s (\n%s\n);",
    _firebird_quote_ident($self->table_name), join(",\n", @col_defs);
}


sub summary {
  my ($self) = @_;
  my $kind = (($self->table_info // {})->{kind} // '') eq 'view' ? 'view' : 'table';
  return sprintf '%s %s: %s', $self->summary_prefix, $kind, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Diff::Table - Diff operations for Firebird tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a table-level diff operation in Firebird: C<CREATE TABLE> or
C<DROP TABLE>. C<create> ops capture the target columns so C<as_sql> can emit
the full definition in a single statement. The foreign keys and unique
constraints of the new table are separate operations
(L<DBIO::Firebird::Diff::Constraint>) that run after all tables exist.

=head1 METHODS

=head2 diff

    my @ops = DBIO::Firebird::Diff::Table->diff(
        $source_tables, $target_tables,
        $target_columns, $target_fks, $source_columns, $source_fks,
    );

The created tables, then the dropped ones in the order of the foreign keys of
C<$source_fks> (the C<foreign_keys> section of the source model): a table that
another dropped table's key points at is dropped after it. Where dropped
tables point at each other, C<ALTER TABLE ... DROP CONSTRAINT> operations
(L<DBIO::Firebird::Diff::Constraint>, action C<drop>) for the keys among them
come first. A key from a table that is kept is not this method's business: the
server refuses the drop of its target, and the key is a constraint difference.
Views are not this method's: their creation and removal are
L<DBIO::Firebird::Diff::View>. A name that is a table on one side and a view
on the other is a C<change> operation, refused (see L</refusal>).

=head2 refusal

    my $reason = $op->refusal;

The reason this operation is refused, else undef. A name that is a table in the
database and a view in the schema, or the reverse, is refused: dropping the
table to create the view (or the view to create the table) is not a change
this diff makes on its own (views that are views on both sides are
L<DBIO::Firebird::Diff::View>).

=head2 refusal_error

The text of the error for a list of refused operations: every name once.

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
