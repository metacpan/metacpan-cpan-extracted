package DBIO::Oracle::Introspect::Tables;
# ABSTRACT: Introspect Oracle tables and views

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema) = @_;

  my %tables;

  # Fetch tables from all_tables (owned tables)
  my $sth = $dbh->prepare(q{
    SELECT table_name, 'table' AS kind
    FROM all_tables
    WHERE owner = ?
      AND table_name NOT LIKE 'BIN$%'
      AND table_name NOT LIKE 'DR$%'
    UNION ALL
    SELECT view_name, 'view' AS kind
    FROM all_views
    WHERE owner = ?
    ORDER BY table_name
  });
  $sth->execute($schema, $schema);

  while (my $row = $sth->fetchrow_hashref) {
    $tables{ $row->{table_name} } = {
      table_name => $row->{table_name},
      kind       => $row->{kind},
      schema     => $schema,
    };
  }

  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Introspect::Tables - Introspect Oracle tables and views

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches Oracle table and view metadata via C<all_tables> and C<all_views>.
Skips system tables and recycle bin tables (C<BIN$*>).

=head1 METHODS

=head2 fetch

    my $tables = DBIO::Oracle::Introspect::Tables->fetch($dbh, $schema);

Returns a hashref keyed by table name. Each value has: C<table_name>,
C<kind> (C<table> or C<view>), C<schema>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
