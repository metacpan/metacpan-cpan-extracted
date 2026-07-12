package DBIO::MSSQL::Diff::Column;
# ABSTRACT: Diff operations for MSSQL columns

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::MSSQL::DDL qw(_mssql_column_type);
use DBIO::Diff::Compare qw(changed_column_fields norm_type);


__PACKAGE__->mk_diff_accessors(qw/table_name column_name old_info new_info/);


sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;

  return $class->diff_nested($source_cols, $target_cols,
    index_by      => 'column_name',
    scope         => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when  => sub { scalar changed_column_fields($_[0], $_[1]) },
    on_new => sub {
      my ($table, $name, $new) = @_;
      $class->new(action => 'add', table_name => $table, column_name => $name, new_info => $new);
    },
    on_changed => sub {
      my ($table, $name, $old, $new) = @_;
      $class->new(action => 'alter', table_name => $table, column_name => $name,
        old_info => $old, new_info => $new);
    },
    on_gone => sub {
      my ($table, $name, $old) = @_;
      $class->new(action => 'drop', table_name => $table, column_name => $name, old_info => $old);
    },
  );
}


sub as_sql {
  my ($self) = @_;

  my $tbl = _quote_ident($self->table_name);
  my $col = _quote_ident($self->column_name);

  if ($self->action eq 'add') {
    my $info = $self->new_info;
    my $type = _mssql_column_type($info);
    my $sql  = sprintf 'ALTER TABLE %s ADD %s %s', $tbl, $col, $type;
    $sql .= ' NOT NULL' if $info->{not_null};
    if (defined $info->{default_value}) {
      $sql .= " DEFAULT $info->{default_value}";
    }
    return "$sql;";
  }

  if ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP COLUMN %s;', $tbl, $col;
  }

  if ($self->action eq 'alter') {
    my $old = $self->old_info;
    my $new = $self->new_info;
    my @stmts;

    if (norm_type($old->{data_type}) ne norm_type($new->{data_type})) {
      push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s %s;',
        $tbl, $col, _mssql_column_type($new);
    }
    if (($old->{not_null} // 0) != ($new->{not_null} // 0)) {
      push @stmts, $new->{not_null}
        ? sprintf('ALTER TABLE %s ALTER COLUMN %s NOT NULL;', $tbl, $col)
        : sprintf('ALTER TABLE %s ALTER COLUMN %s NULL;', $tbl, $col);
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
  my $type = $self->new_info ? ' (' . $self->new_info->{data_type} . ')' : '';
  return sprintf '  %scolumn: %s.%s%s',
    $self->summary_prefix, $self->table_name, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Diff::Column - Diff operations for MSSQL columns

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Column-level diff operations for MSSQL. MSSQL supports C<ALTER TABLE ADD/DROP COLUMN>,
C<ALTER COLUMN> for type/nullability/default changes. Built on
L<DBIO::Diff::Op> (the nested create/change/drop walk) and
L<DBIO::Diff::Compare> (the C<changed_column_fields> sameness predicate).

=head1 METHODS

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
