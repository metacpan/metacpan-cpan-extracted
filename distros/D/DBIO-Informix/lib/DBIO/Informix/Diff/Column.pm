package DBIO::Informix::Diff::Column;
# ABSTRACT: Diff operations for Informix columns

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_column_fields column_change_lossy);
use DBIO::Informix::Util qw(_quote_ident);
use DBIO::Informix::ColumnDef qw(column_def_sql);

__PACKAGE__->mk_diff_accessors(qw(table_name column_info from_info));



sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;

  my @ops;

  for my $table (sort keys %$target) {
    next unless $target_tables->{$table} && $source_tables->{$table};
    next if _is_view($target_tables->{$table}) || _is_view($source_tables->{$table});
    my %src_cols = map { $_->{column_name} => $_ } @{ $source->{$table} // [] };

    for my $col (@{ $target->{$table} }) {
      if (my $src = $src_cols{$col->{column_name}}) {
        if (changed_column_fields(_compare_view($src), _compare_view($col))) {
          push @ops, $class->new(
            action      => 'alter',
            table_name  => $table,
            column_info => $col,
            from_info   => $src,
          );
        }
      } else {
        push @ops, $class->new(
          action      => 'add',
          table_name  => $table,
          column_info => $col,
        );
      }
    }
  }

  for my $table (sort keys %$source) {
    next unless $source_tables->{$table} && $target_tables->{$table};
    next if _is_view($target_tables->{$table}) || _is_view($source_tables->{$table});
    my %tgt_cols = map { $_->{column_name} => $_ } @{ $target->{$table} // [] };

    for my $col (@{ $source->{$table} }) {
      unless (exists $tgt_cols{$col->{column_name}}) {
        push @ops, $class->new(
          action      => 'drop',
          table_name  => $table,
          column_info => $col,
        );
      }
    }
  }

  return @ops;
}

# A view is created whole or dropped whole: its columns are not altered.
sub _is_view { ref $_[0] eq 'HASH' && ($_[0]{kind} // '') eq 'view' }

# Build a comparison-only view of a column. Informix carries C<default_value>
# as a SCALAR ref to signal "literal SQL, do not quote" (see
# L<DBIO::Informix::ColumnDef>); dereference it here so L</changed_column_fields>'s
# string compare sees the same string on both sides. The original column_info
# (and its SCALAR ref) is left untouched for C<as_sql>.
sub _compare_view {
  my ($col) = @_;
  my $view = { %$col };
  if (ref $col->{default_value} eq 'SCALAR') {
    $view->{default_value} = ${ $col->{default_value} };
  }
  return $view;
}


sub as_sql {
  my ($self) = @_;

  my $col = $self->column_info;
  my $table = _quote_ident($self->table_name);

  if ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP (%s);',
      $table, _quote_ident($col->{column_name});
  }

  my $def = column_def_sql(
    name              => $col->{column_name},
    type              => $col->{data_type},
    size              => $col->{size},
    not_null          => $col->{not_null},
    default_value     => $col->{default_value},
    is_auto_increment => $col->{is_auto_increment},
  );

  return sprintf 'ALTER TABLE %s MODIFY (%s);', $table, $def
    if $self->action eq 'alter';

  return sprintf 'ALTER TABLE %s ADD (%s);', $table, $def;
}


my %LOSSLESS_PAIRS = map { ($_ => 1) } (
  'smallint->integer', 'smallint->int8', 'smallint->bigint',
  'integer->int8', 'integer->bigint',
  'int8->bigint', 'bigint->int8',
);

sub lossy {
  my ($self) = @_;
  return 0 unless $self->action eq 'alter';
  my ($old, $new) = ($self->from_info, $self->column_info);
  return column_change_lossy($old, $new, \%LOSSLESS_PAIRS) ? 1 : 0;
}


sub summary {
  my ($self) = @_;
  return sprintf '%s column: %s.%s',
    $self->summary_prefix, $self->table_name, $self->column_info->{column_name};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Diff::Column - Diff operations for Informix columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents a column-level diff operation in Informix: C<ALTER TABLE ADD (...)>,
C<ALTER TABLE ... DROP (col)>, or C<ALTER TABLE ... MODIFY (...)> when a column's type,
nullability, or default changes between source and target.

=head1 METHODS

=head2 diff

    my @ops = DBIO::Informix::Diff::Column->diff(
        $source_columns, $target_columns,
        $source_tables,  $target_tables,
    );

Compares two column hashrefs (keyed by table name) and returns C<add> ops
for columns present only in target, C<drop> ops for columns only in source,
only for tables present in both (a created table is created whole, a
dropped one dropped whole), and C<alter> ops for columns present in both whose definition (data type,
nullability, or default) differs. Change detection delegates to
L<DBIO::Diff::Compare/changed_column_fields>.

=head2 as_sql

Returns the SQL for this operation. C<add> emits C<ALTER TABLE t ADD (col type ...)> (Informix has no C<COLUMN> keyword there; live unmeasured),
C<drop> emits C<ALTER TABLE t DROP (col)> (Informix has no C<DROP COLUMN>; the DROP clause takes a column or a parenthesized list, HCL OneDB/Informix SQL Syntax, ALTER TABLE, ids_sqs_0086; live unmeasured), and C<alter> emits
C<ALTER TABLE ... MODIFY (...)> with the new column definition.

=head2 lossy

True for an C<alter> that may alter or lose stored values, so a deploy runs it
only with C<< allow_destructive => 1 >> (L<DBIO::Deploy::Base/apply>, ADR 0080).
The answer is L<DBIO::Diff::Compare/column_change_lossy>: a change of the type
is lossless only for a pair of integer types of the table below, measured on
Informix 15.0.1 (C<ALTER TABLE ... MODIFY> over rows at the limits of the
source type, every value read back unchanged); the same type with a size at
least as big is lossless as well. Everything else, a narrowing and a change
between kinds of type included, is lossy. A change of C<NOT NULL> or of the
default alone keeps every value and is not lossy; an C<add> or C<drop> is not
a change of a column (a drop is a destructive operation of its own).

    smallint -> integer, int8, bigint
    integer  -> int8, bigint
    int8     -> bigint
    bigint   -> int8

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
