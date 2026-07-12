package DBIO::SQLite::Introspect::ForeignKeys;
# ABSTRACT: Introspect SQLite foreign keys

use strict;
use warnings;

use DBIO::Introspect::Base ();



sub fetch {
  my ($class, $dbh, $tables) = @_;
  my %fks;

  for my $table_name (sort keys %$tables) {
    my $list = $dbh->selectall_arrayref(
      qq{PRAGMA foreign_key_list("$table_name")}, { Slice => {} }
    );
    next unless @$list;

    my $groups = DBIO::Introspect::Base->_aggregate_by_ordered($list, 'id');
    $fks{$table_name} = [ map {
      my ($id, $rows) = @$_;
      my $first = $rows->[0];
      my @from = map { $_->{from} } sort { $a->{seq} <=> $b->{seq} } @$rows;
      my @to   = map { $_->{to}   } sort { $a->{seq} <=> $b->{seq} } @$rows;
      +{
        fk_id        => $id,
        from_columns => \@from,
        to_table     => $first->{table},
        to_columns   => \@to,
        on_update    => $first->{on_update},
        on_delete    => $first->{on_delete},
        match        => $first->{match},
      };
    } @$groups ];
  }

  return \%fks;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Introspect::ForeignKeys - Introspect SQLite foreign keys

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches foreign key metadata via C<PRAGMA foreign_key_list()>. Composite
FKs are grouped by their C<id> via
L<DBIO::Introspect::Base/_aggregate_by_ordered> (preserves both
first-seen id order and column-seq order within each FK).

=head1 METHODS

=head2 fetch

    my $fks = DBIO::SQLite::Introspect::ForeignKeys->fetch($dbh, $tables);

Returns a hashref keyed by table name. Each value is an arrayref of
FK hashrefs with keys: C<fk_id>, C<from_columns> (arrayref),
C<to_table>, C<to_columns> (arrayref), C<on_update>, C<on_delete>,
C<match>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
