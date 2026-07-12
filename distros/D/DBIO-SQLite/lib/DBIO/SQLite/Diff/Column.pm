package DBIO::SQLite::Diff::Column;
# ABSTRACT: Diff operations for SQLite columns

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_column_fields);
use DBIO::SQL::Util qw(_quote_ident);
use namespace::clean;


__PACKAGE__->mk_diff_accessors(qw/table_name column_name old_info new_info/);


sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;

  # The create/change/drop walk over columns nested under retained tables is
  # the generic DBIO::Diff::Op->diff_nested. Only tables present in both models
  # are walked (scope 'both') -- columns of brand-new / dropped tables ride
  # along with the table op. changed_column_fields is the per-engine "did this
  # column change" predicate; everything else here is SQLite-shaped ops.
  return $class->diff_nested($source_cols, $target_cols,
    index_by      => 'column_name',
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => sub { scalar changed_column_fields($_[0], $_[1]) },
    on_new => sub {
      my ($table, $name, $new) = @_;
      $class->new(
        action      => 'add',
        table_name  => $table,
        column_name => $name,
        new_info    => $new,
      );
    },
    on_changed => sub {
      my ($table, $name, $old, $new) = @_;
      $class->new(
        action      => 'alter',
        table_name  => $table,
        column_name => $name,
        old_info    => $old,
        new_info    => $new,
      );
    },
    on_gone => sub {
      my ($table, $name, $old) = @_;
      $class->new(
        action      => 'drop',
        table_name  => $table,
        column_name => $name,
        old_info    => $old,
      );
    },
  );
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'add') {
    my $info = $self->new_info;
    my $type = $info->{data_type} // 'TEXT';
    my $sql  = sprintf 'ALTER TABLE %s ADD COLUMN %s %s',
      _quote_ident($self->table_name),
      _quote_ident($self->column_name),
      $type;
    $sql .= ' NOT NULL' if $info->{not_null};
    if (defined $info->{default_value}) {
      $sql .= " DEFAULT $info->{default_value}";
    }
    return "$sql;";
  }
  if ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP COLUMN %s;',
      _quote_ident($self->table_name),
      _quote_ident($self->column_name);
  }
  if ($self->action eq 'alter') {
    return sprintf
      "-- ALTER COLUMN not supported by SQLite ALTER TABLE; rebuild required for %s.%s\n"
      . "-- old: %s%s\n-- new: %s%s",
      $self->table_name, $self->column_name,
      ($self->old_info->{data_type} // ''),
      ($self->old_info->{not_null}  ? ' NOT NULL' : ''),
      ($self->new_info->{data_type} // ''),
      ($self->new_info->{not_null}  ? ' NOT NULL' : '');
  }
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'add' ? '+' : $self->action eq 'drop' ? '-' : '~';
  my $type = $self->new_info ? " ($self->{new_info}{data_type})" : '';
  return sprintf '  %scolumn: %s.%s%s', $prefix, $self->table_name, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Diff::Column - Diff operations for SQLite columns

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Represents a column-level diff operation in SQLite. Only ADD COLUMN is
supported as a true ALTER -- SQLite has very limited C<ALTER TABLE>:
since 3.25 it can rename columns and since 3.35 it can drop columns,
but type changes still require the create-new-table-and-copy dance.

For now this module emits:

=over 4

=item * C<ALTER TABLE ... ADD COLUMN ...> for added columns

=item * C<ALTER TABLE ... DROP COLUMN ...> for dropped columns (3.35+)

=item * A descriptive comment for type / nullability changes -- a true
        in-place ALTER is impossible. When the target table's original
        C<CREATE> statement is known, L<DBIO::SQLite::Diff> hoists such a
        column into a whole-table L<DBIO::SQLite::Diff::Rebuild> instead, and
        this comment is never emitted; it only stands as a fallback when no
        captured DDL is available (the compiled-model path).

=back

Brand-new tables get their columns inline via L<DBIO::SQLite::Diff::Table>
-- this module only sees columns of tables that exist in both source
and target.

=head1 METHODS

=head2 diff

    my @ops = DBIO::SQLite::Diff::Column->diff(
        $source_columns, $target_columns,
        $source_tables,  $target_tables,
    );

Compares column lists for tables that exist in both source and target.

=head2 as_sql

Returns the C<ALTER TABLE> statement for this operation, or a comment
for unsupported alterations.

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
