package DBIO::DuckDB::Diff::Column;
# ABSTRACT: Diff operations for DuckDB columns

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::DuckDB::DDL::Emit qw(column_def);
use DBIO::Diff::Compare qw(norm_type changed_column_fields);

__PACKAGE__->mk_diff_accessors(qw/table_name column_name old_info new_info/);



sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;

  return $class->diff_nested($source_cols, $target_cols,
    index_by      => 'column_name',
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => sub {
      my ($old, $new) = @_;
      scalar changed_column_fields($old, $new);
    },
    on_new => sub {
      my ($table_name, $col_name, $tgt) = @_;
      $class->new(
        action      => 'add',
        table_name  => $table_name,
        column_name => $col_name,
        new_info    => $tgt,
      );
    },
    on_changed => sub {
      my ($table_name, $col_name, $old, $new) = @_;
      $class->new(
        action      => 'alter',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $old,
        new_info    => $new,
      );
    },
    on_gone => sub {
      my ($table_name, $col_name, $old) = @_;
      $class->new(
        action      => 'drop',
        table_name  => $table_name,
        column_name => $col_name,
        old_info    => $old,
      );
    },
  );
}


sub as_sql {
  my ($self) = @_;

  my $tbl = _quote_ident($self->table_name);
  my $col = _quote_ident($self->column_name);

  if ($self->action eq 'add') {
    my $info = $self->new_info;
    my $def  = column_def(
      name     => $self->column_name,
      type     => ($info->{data_type} || 'VARCHAR'),
      not_null => $info->{not_null},
      default  => $info->{default_value},
    );
    return sprintf 'ALTER TABLE %s ADD COLUMN %s;', $tbl, $def;
  }

  if ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP COLUMN %s;', $tbl, $col;
  }

  if ($self->action eq 'alter') {
    my $old = $self->old_info;
    my $new = $self->new_info;
    my @stmts;

    if (norm_type($old->{data_type}) ne norm_type($new->{data_type})) {
      push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s SET DATA TYPE %s;',
        $tbl, $col, ($new->{data_type} || 'VARCHAR');
    }
    if (($old->{not_null} // 0) != ($new->{not_null} // 0)) {
      push @stmts, $new->{not_null}
        ? sprintf('ALTER TABLE %s ALTER COLUMN %s SET NOT NULL;', $tbl, $col)
        : sprintf('ALTER TABLE %s ALTER COLUMN %s DROP NOT NULL;', $tbl, $col);
    }
    my $old_d = defined $old->{default_value} ? $old->{default_value} : '';
    my $new_d = defined $new->{default_value} ? $new->{default_value} : '';
    if ($old_d ne $new_d) {
      push @stmts, length $new_d
        ? sprintf('ALTER TABLE %s ALTER COLUMN %s SET DEFAULT %s;', $tbl, $col, $new_d)
        : sprintf('ALTER TABLE %s ALTER COLUMN %s DROP DEFAULT;', $tbl, $col);
    }
    return join "\n", @stmts;
  }
}


sub summary {
  my ($self) = @_;
  my $type = $self->new_info ? " ($self->{new_info}{data_type})" : '';
  return sprintf '  %scolumn: %s.%s%s',
    $self->summary_prefix, $self->table_name, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Diff::Column - Diff operations for DuckDB columns

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Column-level diff operations for DuckDB. Unlike SQLite, DuckDB has a
reasonably complete C<ALTER TABLE>:

=over 4

=item * C<ALTER TABLE ... ADD COLUMN>

=item * C<ALTER TABLE ... DROP COLUMN>

=item * C<ALTER TABLE ... ALTER COLUMN ... SET DATA TYPE>

=item * C<ALTER TABLE ... ALTER COLUMN ... SET / DROP NOT NULL>

=item * C<ALTER TABLE ... ALTER COLUMN ... SET / DROP DEFAULT>

=back

So actual type and nullability changes are emitted as real ALTER statements
rather than commented-out warnings.

Brand-new tables get their columns inline via L<DBIO::DuckDB::Diff::Table>
-- this module only sees columns of tables that exist in both models.

=head1 METHODS

=head2 diff

=head2 as_sql

=head2 summary

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
