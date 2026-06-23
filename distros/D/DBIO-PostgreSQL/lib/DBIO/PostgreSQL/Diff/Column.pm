package DBIO::PostgreSQL::Diff::Column;
# ABSTRACT: Diff operations for PostgreSQL columns

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_fields);
use DBIO::PostgreSQL::Introspect ();

__PACKAGE__->mk_diff_accessors(qw(table_key column_name old_info new_info));







# Field comparison spec for the PostgreSQL column model. Extends the
# canonical data_type / not_null / default_value / size set with the
# PostgreSQL-specific identity and generated flags (attidentity,
# attgenerated from pg_catalog). Both are compared as scalars — they are
# short opcodes ('a'/'d'/'s'/''), not user data.
my %_COLUMN_FIELD_SPEC = (
  type   => [qw/data_type/],
  bool   => [qw/not_null/],
  scalar => [qw/default_value identity generated/],
);

sub diff {
  my ($class, $source_cols, $target_cols, $source_tables, $target_tables) = @_;
  my @ops;

  # Only diff columns for tables that exist in both source and target.
  # Brand new tables are handled by Diff::Table as full CREATE TABLE
  # statements with columns inline.
  for my $table_key (sort keys %$target_cols) {
    next unless exists $source_tables->{$table_key} && exists $target_tables->{$table_key};

    my %source_by_name = map { $_->{column_name} => $_ } @{ $source_cols->{$table_key} // [] };
    my %target_by_name = map { $_->{column_name} => $_ } @{ $target_cols->{$table_key} // [] };

    # New columns
    for my $col_name (sort keys %target_by_name) {
      next if exists $source_by_name{$col_name};
      push @ops, $class->new(
        action      => 'add',
        table_key   => $table_key,
        column_name => $col_name,
        new_info    => $target_by_name{$col_name},
      );
    }

    # Dropped columns
    for my $col_name (sort keys %source_by_name) {
      next if exists $target_by_name{$col_name};
      push @ops, $class->new(
        action      => 'drop',
        table_key   => $table_key,
        column_name => $col_name,
        old_info    => $source_by_name{$col_name},
      );
    }

    # Altered columns
    for my $col_name (sort keys %target_by_name) {
      next unless exists $source_by_name{$col_name};
      my $src = $source_by_name{$col_name};
      my $tgt = $target_by_name{$col_name};

      my @changed = changed_fields($src, $tgt, %_COLUMN_FIELD_SPEC);
      next unless @changed;

      push @ops, $class->new(
        action      => 'alter',
        table_key   => $table_key,
        column_name => $col_name,
        old_info    => $src,
        new_info    => $tgt,
      );
    }
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  if ($self->action eq 'add') {
    my $type = $self->new_info->{data_type};
    my $sql = sprintf 'ALTER TABLE %s ADD COLUMN %s %s',
      $self->table_key, $self->column_name, $type;
    $sql .= ' NOT NULL' if $self->new_info->{not_null};
    my $kind = DBIO::PostgreSQL::Introspect->identity_kind($self->new_info->{identity});
    if ($kind) {
      $sql .= " GENERATED $kind AS IDENTITY";
    }
    elsif (defined $self->new_info->{default_value}) {
      $sql .= sprintf ' DEFAULT %s', $self->new_info->{default_value};
    }
    return "$sql;";
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'ALTER TABLE %s DROP COLUMN %s;',
      $self->table_key, $self->column_name;
  }
  elsif ($self->action eq 'alter') {
    my @stmts;
    my $src = $self->old_info;
    my $tgt = $self->new_info;

    if (($src->{data_type} // '') ne ($tgt->{data_type} // '')) {
      push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s TYPE %s;',
        $self->table_key, $self->column_name, $tgt->{data_type};
    }
    if (($src->{not_null} // 0) != ($tgt->{not_null} // 0)) {
      if ($tgt->{not_null}) {
        push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s SET NOT NULL;',
          $self->table_key, $self->column_name;
      } else {
        push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s DROP NOT NULL;',
          $self->table_key, $self->column_name;
      }
    }
    if (($src->{default_value} // '') ne ($tgt->{default_value} // '')) {
      if (defined $tgt->{default_value} && $tgt->{default_value} ne '') {
        push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s SET DEFAULT %s;',
          $self->table_key, $self->column_name, $tgt->{default_value};
      } else {
        push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s DROP DEFAULT;',
          $self->table_key, $self->column_name;
      }
    }

    # Identity transitions. attidentity is '' (none), 'a' (ALWAYS), 'd' (BY DEFAULT).
    my $src_id = $src->{identity} // '';
    my $tgt_id = $tgt->{identity} // '';
    if ($src_id ne $tgt_id) {
      my $src_kind = DBIO::PostgreSQL::Introspect->identity_kind($src_id);
      my $tgt_kind = DBIO::PostgreSQL::Introspect->identity_kind($tgt_id);
      if (!$src_kind && $tgt_kind) {
        push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s ADD GENERATED %s AS IDENTITY;',
          $self->table_key, $self->column_name, $tgt_kind;
      }
      elsif ($src_kind && !$tgt_kind) {
        push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s DROP IDENTITY;',
          $self->table_key, $self->column_name;
      }
      else {
        push @stmts, sprintf 'ALTER TABLE %s ALTER COLUMN %s SET GENERATED %s;',
          $self->table_key, $self->column_name, $tgt_kind;
      }
    }
    return join "\n", @stmts;
  }
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->summary_prefix;
  my $type = $self->new_info ? " ($self->{new_info}{data_type})" : '';
  return sprintf '  %scolumn: %s.%s%s', $prefix, $self->table_key, $self->column_name, $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Column - Diff operations for PostgreSQL columns

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Represents a column-level diff operation: C<ADD COLUMN>, C<DROP COLUMN>, or
C<ALTER COLUMN> (type change, nullability change, or default change). Only
columns on tables that exist in both source and target are compared.

=head1 ATTRIBUTES

=head2 table_key

The C<schema.table> key identifying which table the column belongs to.

=head2 column_name

The column name.

=head2 old_info

The source column metadata hashref (present for C<drop> and C<alter>).

=head2 new_info

The target column metadata hashref (present for C<add> and C<alter>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Column->diff(
        $source_cols, $target_cols, $source_tables, $target_tables,
    );

Compares column lists for tables that exist in both source and target.
Detects added columns, dropped columns, and altered columns (data type,
C<NOT NULL>, default value, or identity kind).

=head2 as_sql

Returns one or more C<ALTER TABLE> statements for this operation. For C<alter>,
may return multiple statements (one per changed attribute).

=head2 summary

Returns a one-line description such as C<+column: auth.users.avatar (text)>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
