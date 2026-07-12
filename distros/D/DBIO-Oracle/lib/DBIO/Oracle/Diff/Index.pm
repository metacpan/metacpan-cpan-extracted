package DBIO::Oracle::Diff::Index;
# ABSTRACT: Diff operations for Oracle indexes

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);

__PACKAGE__->mk_diff_accessors(qw(index_name table_name index_info));



sub diff {
  my ($class, $source, $target) = @_;
  return $class->diff_nested(
    $source, $target,
    scope => 'both',
    on_new => sub {
      my ($tbl, $idx_name, $idx) = @_;
      $class->new(
        action     => 'create',
        index_name => $idx_name,
        table_name => $tbl,
        index_info => $idx,
      );
    },
    on_gone => sub {
      my ($tbl, $idx_name, $idx) = @_;
      $class->new(
        action     => 'drop',
        index_name => $idx_name,
        table_name => $tbl,
        index_info => $idx,
      );
    },
  );
}


sub as_sql {
  my ($self) = @_;

  my $idx = _quote_ident($self->index_name);
  my $tbl = _quote_ident($self->table_name);
  my $info = $self->index_info;
  my $cols = join(', ', map { _quote_ident($_) } @{ $info->{columns} // [] });

  if ($self->action eq 'create') {
    my $unique = $info->{is_unique} ? 'UNIQUE ' : '';
    return sprintf 'CREATE %sINDEX %s ON %s (%s);',
      $unique, $idx, $tbl, $cols;
  }

  if ($self->action eq 'drop') {
    return sprintf 'DROP INDEX %s;', $idx;
  }
}


sub summary {
  my ($self) = @_;
  return sprintf '  %sindex: %s on %s',
    $self->summary_prefix, $self->index_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Diff::Index - Diff operations for Oracle indexes

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Index-level diff operations for Oracle.

=head1 ATTRIBUTES

=head2 index_name

The bare index name.

=head2 table_name

The bare table name the index belongs to.

=head2 index_info

Hashref of index metadata: C<is_unique>, C<columns>.

=head1 METHODS

=head2 diff

    my @ops = DBIO::Oracle::Diff::Index->diff($source, $target);

Walks tables present in B<both> C<$source> and C<$target> (C<scope = both>).
Source-only tables have their indexes cascaded by the table drop, so they
are not walked here; brand-new tables inline their indexes in the CREATE
TABLE statement emitted by L<DBIO::Oracle::Diff::Table>, so target-only
tables are skipped too.

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
