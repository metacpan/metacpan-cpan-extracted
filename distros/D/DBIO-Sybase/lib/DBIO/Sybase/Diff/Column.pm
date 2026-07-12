package DBIO::Sybase::Diff::Column;
# ABSTRACT: Diff Sybase ASE columns

use strict;
use warnings;

use DBIO::Diff::Compare qw(changed_column_fields);
use DBIO::Sybase::DDL ();


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;
  $source_tables  //= {};
  $target_tables  //= {};
  my @ops;

  for my $table (sort keys %$target) {
    my $s_cols = $source->{$table} // [];
    my $t_cols = $target->{$table} // [];

    my %s_idx = map { $_->{column_name} => $_ } @$s_cols;
    my %t_idx = map { $_->{column_name} => $_ } @$t_cols;

    for my $name (sort keys %t_idx) {
      if (exists $s_idx{$name}) {
        push @ops, DBIO::Sybase::Diff::Column::Alter->new(
          action => 'alter',
          table  => $table,
          from   => $s_idx{$name},
          to     => $t_idx{$name},
        ) if changed_column_fields($s_idx{$name}, $t_idx{$name});
      }
      else {
        push @ops, DBIO::Sybase::Diff::Column::Add->new(
          action => 'add',
          table  => $table,
          col    => $t_idx{$name},
        );
      }
    }

    for my $name (sort keys %s_idx) {
      push @ops, DBIO::Sybase::Diff::Column::Drop->new(
        action => 'drop',
        table  => $table,
        col    => $s_idx{$name},
      ) unless exists $t_idx{$name};
    }
  }

  return @ops;
}

package DBIO::Sybase::Diff::Column::Add;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table col));

sub as_sql {
  my $self = shift;
  sprintf 'ALTER TABLE %s ADD %s %s',
    $self->table, $self->col->{column_name}, $self->col->{data_type};
}
sub summary {
  my $self = shift;
  "ALTER TABLE $self->{table} ADD $self->{col}{column_name}";
}

package DBIO::Sybase::Diff::Column::Alter;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table from to));

sub as_sql {
  my $self = shift;
  my $tbl     = $self->table;
  my $col_name = $self->to->{column_name};
  my $type    = $self->to->{data_type};
  my $sql = "ALTER TABLE $tbl ALTER COLUMN $col_name $type";
  # Sybase ASE supports NOT NULL and DEFAULT in ALTER COLUMN
  $sql .= ' NOT NULL' if $self->to->{not_null};
  $sql .= DBIO::Sybase::DDL::sybase_default_clause($self->to->{default_value});
  $sql;
}
sub summary {
  my $self = shift;
  "ALTER TABLE $self->{table} ALTER $self->{to}{column_name}";
}

package DBIO::Sybase::Diff::Column::Drop;
use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table col));

sub as_sql {
  my $self = shift;
  "ALTER TABLE $self->{table} DROP COLUMN $self->{col}{column_name}";
}
sub summary {
  my $self = shift;
  "ALTER TABLE $self->{table} DROP $self->{col}{column_name}";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Diff::Column - Diff Sybase ASE columns

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Compares two column sets and generates column-level diff operations.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
