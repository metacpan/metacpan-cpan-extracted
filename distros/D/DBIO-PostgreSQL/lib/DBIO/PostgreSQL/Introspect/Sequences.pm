package DBIO::PostgreSQL::Introspect::Sequences;
# ABSTRACT: Introspect PostgreSQL sequences

use strict;
use warnings;

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      sn.nspname AS schema_name,
      s.relname AS sequence_name,
      d.refobjid::regclass::text AS owned_by_table,
      a.attname AS owned_by_column,
      seq.seqstart AS start_value,
      seq.seqincrement AS increment,
      seq.seqmin AS min_value,
      seq.seqmax AS max_value,
      seq.seqcache AS cache_size,
      seq.seqcycle AS is_cycle,
      pg_catalog.format_type(seq.seqtypid, NULL) AS data_type
    FROM pg_catalog.pg_class s
    JOIN pg_catalog.pg_namespace sn ON sn.oid = s.relnamespace
    JOIN pg_catalog.pg_sequence seq ON seq.seqrelid = s.oid
    LEFT JOIN pg_catalog.pg_depend d
      ON d.objid = s.oid AND d.deptype = 'a'
    LEFT JOIN pg_catalog.pg_attribute a
      ON a.attrelid = d.refobjid AND a.attnum = d.refobjsubid
    WHERE s.relkind = 'S'
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('sn');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND sn.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY sn.nspname, s.relname';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %sequences;
  while (my $row = $sth->fetchrow_hashref) {
    my $key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    $sequences{$key} = {
      schema_name     => $row->{schema_name},
      sequence_name   => $row->{sequence_name},
      owned_by_table  => $row->{owned_by_table},
      owned_by_column => $row->{owned_by_column},
      start_value     => $row->{start_value},
      increment       => $row->{increment},
      min_value       => $row->{min_value},
      max_value       => $row->{max_value},
      cache_size      => $row->{cache_size},
      is_cycle        => $row->{is_cycle} ? 1 : 0,
      data_type       => $row->{data_type},
    };
  }

  return \%sequences;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Sequences - Introspect PostgreSQL sequences

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches sequence metadata from C<pg_catalog.pg_sequence>, including ownership
information (the table and column the sequence is attached to via C<pg_depend>),
start value, increment, min/max bounds, cache size, cycle flag, and data type.

=head1 METHODS

=head2 fetch

    my $sequences = DBIO::PostgreSQL::Introspect::Sequences->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.sequence_name>. Each entry has:
C<schema_name>, C<sequence_name>, C<owned_by_table>, C<owned_by_column>,
C<start_value>, C<increment>, C<min_value>, C<max_value>, C<cache_size>,
C<is_cycle>, C<data_type>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
