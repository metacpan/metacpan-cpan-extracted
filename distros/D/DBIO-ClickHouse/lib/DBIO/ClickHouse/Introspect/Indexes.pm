package DBIO::ClickHouse::Introspect::Indexes;
# ABSTRACT: Introspect ClickHouse data-skipping indexes via system.data_skipping_indices

use strict;
use warnings;

our $VERSION = '0.900004';



sub fetch {
  my ($class, $dbh, $tables, $database) = @_;

  my $sql = q{
    SELECT
      table,
      name,
      type,
      type_full,
      expr,
      granularity
    FROM system.data_skipping_indices
    WHERE database = %s
    ORDER BY table, name
  };
  my @bind;
  if (defined $database) {
    $sql = sprintf $sql, '?';
    push @bind, $database;
  }
  else {
    $sql = sprintf $sql, 'currentDatabase()';
  }

  my %indexes;

  my $sth = eval { my $s = $dbh->prepare($sql); $s->execute(@bind); $s }
    or return \%indexes;

  while (my $row = $sth->fetchrow_hashref) {
    my $table = $row->{table} // '';
    next unless exists $tables->{$table};

    $indexes{$table}{ $row->{name} } = {
      index_name  => $row->{name},
      expr        => $row->{expr},
      type        => $row->{type},
      type_full   => $row->{type_full},
      granularity => defined $row->{granularity} ? 0 + $row->{granularity} : undef,
    };
  }

  return \%indexes;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Introspect::Indexes - Introspect ClickHouse data-skipping indexes via system.data_skipping_indices

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches ClickHouse B<data-skipping index> metadata from
C<system.data_skipping_indices>, scoped to one database and filtered to the
tables surfaced by L<DBIO::ClickHouse::Introspect::Tables>.

=head2 These are not indexes in the DBIO sense

A data-skipping index is not a B-tree and not a constraint. It is a per-granule
summary (C<minmax>, C<set(N)>, C<bloom_filter>, C<ngrambf_v1>, ...) over an
B<expression>, used to skip granules during a scan. It enforces nothing, it
does not accelerate point lookups, and there is no unique variant.

Consequently this reader deliberately does B<not> produce the canonical
C<indexes> section shape (C<is_unique> + C<columns>), and
L<DBIO::ClickHouse::Introspect/table_uniq_info> does not read it. Feeding a
skipping index into C<table_uniq_info> would generate an
C<add_unique_constraint> in a regenerated schema and DBIO would then trust a
uniqueness ClickHouse never promised -- silently wrong lookups, not a missing
optimization. They get their own model section, C<data_skipping_indexes>.

They are also declared B<inline> in C<CREATE TABLE>
(C<INDEX name expr TYPE minmax GRANULARITY 4>), not with C<CREATE INDEX>, so
the diff layer has to treat adding one as C<ALTER TABLE ... ADD INDEX> and
must know the C<granularity> to render it.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::ClickHouse::Introspect::Indexes->fetch($dbh, $tables);
    my $indexes = DBIO::ClickHouse::Introspect::Indexes->fetch($dbh, $tables, $database);

Returns a hashref keyed by table name, each value a hashref keyed by index name
with: C<index_name>, C<expr> (the indexed expression, verbatim), C<type> (the
bare index type, e.g. C<minmax>), C<type_full> (with arguments, e.g.
C<set(100)>) and C<granularity>.

Returns an empty hashref when the query fails -- C<system.data_skipping_indices>
is missing on pre-20.x servers and can be hidden by C<READ> grants, and neither
is a reason to make the whole introspection unusable.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Introspect> - assembles the model from this and its sibling readers

=item * L<DBIO::ClickHouse::DDL> - which emits declared skipping indexes inline

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
