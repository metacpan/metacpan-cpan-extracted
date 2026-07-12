package DBIO::Sybase::Diff::Table;
# ABSTRACT: Diff Sybase ASE tables

use strict;
use warnings;

use DBIO::Diff::Op ();
use DBIO::SQL::Util ();
use DBIO::Sybase::DDL ();


sub diff {
  my ($class, $source, $target, $target_columns, $target_fks) = @_;
  $target_columns //= {};
  $target_fks     //= {};
  my @ops;

  for my $name (sort keys %$target) {
    # Existing tables are reconciled column-by-column and index-by-index by
    # DBIO::Sybase::Diff::Column / ::Index. There is no table-level ALTER op:
    # Sybase ASE cannot convert a table to a view (or vice versa) in place, so
    # a kind change is left for a human rather than emitting a broken stub.
    next if exists $source->{$name};
    push @ops, DBIO::Sybase::Diff::Table::Create->new(
      action  => 'create',
      table   => $target->{$name},
      columns => $target_columns->{$name} // [],
    );
  }

  for my $name (sort keys %$source) {
    push @ops, DBIO::Sybase::Diff::Table::Drop->new(
      action => 'drop',
      table  => $source->{$name},
    ) unless exists $target->{$name};
  }

  return @ops;
}

package DBIO::Sybase::Diff::Table::Create;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table columns));

sub as_sql {
  my $self = shift;
  my $tbl = DBIO::SQL::Util::_quote_ident($self->table->{table_name});
  my @col_defs;

  my $cols = $self->columns // [];
  for my $col (@$cols) {
    my $type = DBIO::Sybase::DDL::sybase_column_type($col->{data_type});
    my $def  = sprintf '  %s %s',
      DBIO::SQL::Util::_quote_ident($col->{column_name}), $type;
    $def .= ' NOT NULL' if $col->{not_null};
    $def .= DBIO::Sybase::DDL::sybase_default_clause($col->{default_value});
    $def .= ' IDENTITY' if $col->{is_auto_increment};
    push @col_defs, $def;
  }

  sprintf "CREATE TABLE %s (\n%s\n);", $tbl, join(",\n", @col_defs);
}
sub summary {
  my $self = shift;
  "CREATE TABLE " . $self->table->{table_name};
}

package DBIO::Sybase::Diff::Table::Drop;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table));

sub as_sql {
  my $self = shift;
  "DROP TABLE " . $self->table->{table_name};
}
sub summary {
  my $self = shift;
  "DROP TABLE " . $self->table->{table_name};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Diff::Table - Diff Sybase ASE tables

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Compares two table sets and generates table-level diff operations.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
