package DBIO::MySQL::Introspect::Indexes;
# ABSTRACT: Introspect MySQL/MariaDB indexes

use strict;
use warnings;

use DBIO::MySQL::Introspect::Util ();



sub fetch {
  my ($class, $dbh, $tables) = @_;
  my %indexes;

  my $sth = $dbh->prepare(q{
    SELECT
      table_name,
      index_name,
      non_unique,
      seq_in_index,
      column_name,
      index_type
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
    ORDER BY table_name, index_name, seq_in_index
  });
  $sth->execute;

  while (my $row = $sth->fetchrow_hashref) {
    next unless DBIO::MySQL::Introspect::Util->keep_table($tables, $row->{table_name});

    my $idx_name   = $row->{index_name};
    my $is_unique  = $row->{non_unique} ? 0 : 1;

    my $origin;
    if ($idx_name eq 'PRIMARY') {
      $origin = 'pk';
    }
    elsif ($is_unique) {
      $origin = 'u';
    }
    else {
      $origin = 'c';
    }

    my $entry = $indexes{ $row->{table_name} }{$idx_name} //= {
      index_name => $idx_name,
      is_unique  => $is_unique,
      columns    => [],
      index_type => $row->{index_type},
      origin     => $origin,
    };
    $entry->{columns}[ $row->{seq_in_index} - 1 ] = $row->{column_name};
  }

  return \%indexes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Introspect::Indexes - Introspect MySQL/MariaDB indexes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches index metadata from C<information_schema.statistics>, scoped to the
current C<DATABASE()> and filtered to the tables surfaced by
L<DBIO::MySQL::Introspect::Tables>. Multi-column indexes are reassembled
from their per-column C<statistics> rows in C<seq_in_index> order.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::MySQL::Introspect::Indexes->fetch($dbh, $tables);

Given the tables hashref from L<DBIO::MySQL::Introspect::Tables>, returns a
hashref keyed by table name. Each value is a hashref of index hashrefs keyed
by index name, with keys: C<index_name>, C<is_unique>, C<columns> (arrayref),
C<index_type>, C<origin> (C<pk> / C<u> / C<c>).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
