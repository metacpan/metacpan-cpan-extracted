package DBIO::Informix::Diff::Index;
# ABSTRACT: Diff operations for Informix indexes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_index_fields);
use DBIO::Informix::Util qw(_quote_ident);

__PACKAGE__->mk_diff_accessors(qw(index_name table_name index_info replaced));



sub diff {
  my ($class, $source, $target) = @_;

  my @ops;

  for my $table (sort keys %$target) {
    for my $name (sort keys %{ $target->{$table} // {} }) {
      my $tgt_idx = $target->{$table}{$name};
      my $src_idx = $source->{$table} && $source->{$table}{$name};
      if (!$src_idx) {
        push @ops, $class->new(
          action     => 'create',
          index_name => $name,
          table_name => $table,
          index_info => $tgt_idx,
        );
      }
      elsif (changed_index_fields(_compare_view($src_idx), _compare_view($tgt_idx))) {
        # Definition changed -- Informix has no ALTER INDEX, emit drop+create
        push @ops, $class->new(
          action     => 'drop',
          index_name => $name,
          table_name => $table,
          index_info => $src_idx,
          replaced   => 1,
        );
        push @ops, $class->new(
          action     => 'create',
          index_name => $name,
          table_name => $table,
          index_info => $tgt_idx,
        );
      }
    }
  }

  for my $table (sort keys %$source) {
    for my $name (sort keys %{ $source->{$table} // {} }) {
      next if $target->{$table} && $target->{$table}{$name};
      push @ops, $class->new(
        action     => 'drop',
        index_name => $name,
        table_name => $table,
        index_info => $source->{$table}{$name},
      );
    }
  }

  return @ops;
}

# Informix introspected indexes carry C<unique>; L</changed_index_fields> expects
# the canonical C<is_unique>. The C<columns> field is already in canonical
# shape. Build a comparison-only view, leave the original index_info alone
# for C<as_sql>.
sub _compare_view {
  my ($idx) = @_;
  return {
    is_unique => $idx->{unique} ? 1 : 0,
    columns   => $idx->{columns},
  };
}


sub as_sql {
  my ($self) = @_;

  my $idx_name = _quote_ident($self->index_name);
  my $tab_name = _quote_ident($self->table_name);
  my $cols = join(', ', map { _quote_ident($_) } @{$self->index_info->{columns}});

  if ($self->action eq 'drop') {
    return sprintf 'DROP INDEX %s;', $idx_name;
  }

  my $unique = $self->index_info->{unique} ? 'UNIQUE ' : '';
  return sprintf 'CREATE %sINDEX %s ON %s (%s);', $unique, $idx_name, $tab_name, $cols;
}


sub summary {
  my ($self) = @_;
  return sprintf '%s index: %s on %s',
    $self->summary_prefix, $self->index_name, $self->table_name;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Diff::Index - Diff operations for Informix indexes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Represents an index-level diff operation in Informix: C<CREATE INDEX>,
C<DROP INDEX>, or a C<DROP> + C<CREATE> pair when an existing index's
uniqueness or column list changes (Informix has no single
C<ALTER INDEX> statement, so a definition change is emitted as two ops).

=head1 ATTRIBUTES

=head2 replaced

True for the C<drop> that is the first half of a C<drop> + C<create> of one
index whose definition changed: it replaces the index and drops none, so it
counts as changing, not destructive (core ADR 0080,
L<DBIO::Diff::Base/destructive_operations>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::Informix::Diff::Index->diff(
        $source_indexes, $target_indexes,
    );

Compares two index hashrefs (keyed by table name) and returns C<create>
ops for indexes present only in target, C<drop> ops for indexes only in
source, and a C<drop> + C<create> pair for indexes whose definition
(uniqueness or column list) differs. Change detection delegates to
L<DBIO::Diff::Compare/changed_index_fields>.

=head2 as_sql

Returns the SQL for this operation. C<create> emits C<CREATE [UNIQUE] INDEX>.
C<drop> emits C<DROP INDEX>.

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
