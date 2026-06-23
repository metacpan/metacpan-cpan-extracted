package DBIO::MySQL::Diff::Index;
# ABSTRACT: Diff operations for MySQL/MariaDB indexes

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::Diff::Compare qw(changed_index_fields);

__PACKAGE__->mk_diff_accessors(qw(
  table_name index_name index_info
));



sub diff {
  my ($class, $source, $target) = @_;

  # Indexes need a "union" view of the per-table membership: an index on
  # a brand-new table is just as much a create as one on a table that
  # exists in both source and target, and an index on a table that is
  # being dropped is just as much a drop. So we walk with `scope => 'all'`:
  #   * target tables  -> on_new, on_changed
  #   * source-only tables -> on_gone
  #   * both-side tables  -> member-level comparison + on_gone for
  #                          members that vanished
  # That's three kinds of "thing happened" with one walk.
  return $class->diff_nested(
    $source, $target,
    scope      => 'all',
    skip       => \&_is_auto,
    changed_when => \&changed_index_fields,
    on_new => sub {
      my ($table_name, $index_name, $index_info) = @_;
      $class->new(action => 'create', table_name => $table_name,
        index_name => $index_name, index_info => $index_info);
    },
    on_changed => sub {
      my ($table_name, $index_name, $old_info, $new_info) = @_;
      (
        $class->new(action => 'drop',   table_name => $table_name,
          index_name => $index_name, index_info => $old_info),
        $class->new(action => 'create', table_name => $table_name,
          index_name => $index_name, index_info => $new_info),
      );
    },
    on_gone => sub {
      my ($table_name, $index_name, $index_info) = @_;
      $class->new(action => 'drop', table_name => $table_name,
        index_name => $index_name, index_info => $index_info);
    },
  );
}

sub _is_auto {
  my ($info) = @_;
  return 0 unless defined $info->{origin};
  return $info->{origin} eq 'pk' || $info->{origin} eq 'u';
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'create') {
    my $unique = $self->index_info->{is_unique} ? 'UNIQUE ' : '';
    my $cols = join ', ',
      map { "`$_`" } @{ $self->index_info->{columns} // [] };
    return sprintf 'CREATE %sINDEX `%s` ON `%s` (%s);',
      $unique, $self->index_name, $self->table_name, $cols;
  }
  return sprintf 'DROP INDEX `%s` ON `%s`;',
    $self->index_name, $self->table_name;
}


sub summary {
  my ($self) = @_;
  my $prefix = $self->action eq 'create' ? '+' : '-';
  return sprintf '  %sindex: %s on %s',
    $prefix, $self->index_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Diff::Index - Diff operations for MySQL/MariaDB indexes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Represents an index-level diff operation: C<CREATE INDEX> or
C<DROP INDEX>. Auto-generated indexes (PRIMARY KEY and UNIQUE constraint
indexes from inline column definitions) are skipped -- they belong to
the table itself.

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
