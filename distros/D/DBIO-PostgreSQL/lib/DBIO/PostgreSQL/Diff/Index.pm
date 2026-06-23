package DBIO::PostgreSQL::Diff::Index;
# ABSTRACT: Diff operations for PostgreSQL indexes

use strict;
use warnings;

use base 'DBIO::Diff::Op';

__PACKAGE__->mk_diff_accessors(qw(table_key index_name index_info));






sub diff {
  my ($class, $source, $target) = @_;
  my @ops;

  # Collect all index names across all tables
  my %src_indexes;
  for my $table_key (keys %$source) {
    for my $idx_name (keys %{ $source->{$table_key} }) {
      $src_indexes{$idx_name} = {
        table_key  => $table_key,
        index_info => $source->{$table_key}{$idx_name},
      };
    }
  }

  my %tgt_indexes;
  for my $table_key (keys %$target) {
    for my $idx_name (keys %{ $target->{$table_key} }) {
      $tgt_indexes{$idx_name} = {
        table_key  => $table_key,
        index_info => $target->{$table_key}{$idx_name},
      };
    }
  }

  # New indexes
  for my $name (sort keys %tgt_indexes) {
    if (!exists $src_indexes{$name}) {
      push @ops, $class->new(
        action     => 'create',
        table_key  => $tgt_indexes{$name}{table_key},
        index_name => $name,
        index_info => $tgt_indexes{$name}{index_info},
      );
      next;
    }
    # Changed indexes: compare definitions
    my $src_def = $src_indexes{$name}{index_info}{definition} // '';
    my $tgt_def = $tgt_indexes{$name}{index_info}{definition} // '';
    if ($src_def ne $tgt_def) {
      push @ops, $class->new(
        action     => 'drop',
        table_key  => $src_indexes{$name}{table_key},
        index_name => $name,
        index_info => $src_indexes{$name}{index_info},
      );
      push @ops, $class->new(
        action     => 'create',
        table_key  => $tgt_indexes{$name}{table_key},
        index_name => $name,
        index_info => $tgt_indexes{$name}{index_info},
      );
    }
  }

  # Dropped indexes
  for my $name (sort keys %src_indexes) {
    next if exists $tgt_indexes{$name};
    push @ops, $class->new(
      action     => 'drop',
      table_key  => $src_indexes{$name}{table_key},
      index_name => $name,
      index_info => $src_indexes{$name}{index_info},
    );
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;
  if ($self->action eq 'create') {
    # Use the full definition from introspection if available
    if ($self->index_info->{definition}) {
      return $self->index_info->{definition} . ';';
    }
    return sprintf 'CREATE INDEX %s ON %s (%s);',
      $self->index_name, $self->table_key,
      join(', ', @{ $self->index_info->{columns} // ['?'] });
  }
  elsif ($self->action eq 'drop') {
    return sprintf 'DROP INDEX %s;', $self->index_name;
  }
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '  %sindex: %s (on %s)', $prefix, $self->index_name, $self->table_key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Index - Diff operations for PostgreSQL indexes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Represents an index-level diff operation: C<CREATE INDEX> or C<DROP INDEX>.
When an index definition changes, it generates a C<DROP> followed by a
C<CREATE>. The full definition string from C<pg_get_indexdef> is used for
comparison, so partial indexes, expression indexes, and storage parameters are
all detected correctly.

=head1 ATTRIBUTES

=head2 table_key

The C<schema.table> key for the table this index belongs to.

=head2 index_name

The index name.

=head2 index_info

Index metadata hashref (C<definition>, C<access_method>, C<columns>, etc.).

=head1 METHODS

=head2 diff

    my @ops = DBIO::PostgreSQL::Diff::Index->diff($source, $target);

Compares index sets across all tables. Index identity is by name; definition
changes produce a drop-then-create pair.

=head2 as_sql

Returns the SQL for this operation. For C<create>, uses the full
C<pg_get_indexdef> definition string when available, otherwise generates a
basic C<CREATE INDEX> statement. For C<drop>, returns C<DROP INDEX name;>.

=head2 summary

Returns a one-line description such as C<+index: idx_users_tags (on auth.users)>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
