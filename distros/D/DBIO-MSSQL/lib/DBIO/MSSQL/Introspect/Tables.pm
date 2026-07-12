package DBIO::MSSQL::Introspect::Tables;
# ABSTRACT: Introspect MSSQL tables and views

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema) = @_;
  $schema //= 'dbo';

  my $sth = $dbh->prepare(q{
    SELECT table_name, table_type
    FROM INFORMATION_SCHEMA.TABLES
    WHERE table_schema = ?
    ORDER BY table_name
  });
  $sth->execute($schema);

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    my $type = lc($row->{table_type} // '');
    my $kind = $type =~ /view/ ? 'view' : 'table';
    $tables{ $row->{table_name} } = {
      table_name => $row->{table_name},
      kind       => $kind,
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

DBIO::MSSQL::Introspect::Tables - Introspect MSSQL tables and views

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches MSSQL table and view metadata via C<INFORMATION_SCHEMA.TABLES>.
Skips system tables.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::MSSQL::Introspect::Tables->fetch($dbh, $schema);

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
