package DBIO::DB2::Introspect::Tables;
# ABSTRACT: Introspect DB2 tables and views

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema) = @_;
  local $dbh->{FetchHashKeyName} = 'NAME_lc';   # DBD::DB2 upper-cases hashref keys

  my $sth = $dbh->prepare(q{
    SELECT tabname, type, tabschema
    FROM syscat.tables
    WHERE tabschema = ?
      AND tabname NOT LIKE 'EX%'
    ORDER BY tabname
  });
  $sth->execute($schema);

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    # syscat.tables.type is a single char: 'V' = view, 'T' = table, etc.
    my $type = uc($row->{type} // '');
    my $kind = $type eq 'V' ? 'view' : 'table';
    $tables{ $row->{tabname} } = {
      table_name => $row->{tabname},
      kind       => $kind,
      schema     => $row->{tabschema},
    };
  }

  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Introspect::Tables - Introspect DB2 tables and views

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches DB2 table and view metadata via C<SYSCAT.TABLES>.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::DB2::Introspect::Tables->fetch($dbh, $schema);

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
