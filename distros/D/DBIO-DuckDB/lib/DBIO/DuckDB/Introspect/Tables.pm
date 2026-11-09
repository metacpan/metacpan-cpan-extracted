package DBIO::DuckDB::Introspect::Tables;
# ABSTRACT: Introspect DuckDB tables and views

use strict;
use warnings;

our $VERSION = '0.900004';



sub fetch {
  my ($class, $dbh, $schema, $catalog) = @_;
  $schema //= 'main';

  my $sql = q{
    SELECT t.table_name, t.table_type, v.view_definition
    FROM information_schema.tables t
    LEFT JOIN information_schema.views v
      ON v.table_catalog = t.table_catalog
     AND v.table_schema = t.table_schema
     AND v.table_name = t.table_name
    WHERE t.table_schema = ?
      AND t.table_name NOT LIKE 'sqlite_%'
  };
  my @bind = ($schema);

  if (defined $catalog) {
    $sql .= q{ AND t.table_catalog = ?};
    push @bind, $catalog;
  }

  $sql .= q{ ORDER BY t.table_name};

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    my $type = lc($row->{table_type} // '');
    my $kind = $type =~ /view/ ? 'view' : 'table';
    $tables{ $row->{table_name} } = {
      table_name => $row->{table_name},
      kind       => $kind,
      schema     => $schema,
      ( $kind eq 'view' ? ( view_definition => $row->{view_definition} ) : () ),
    };
  }

  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Introspect::Tables - Introspect DuckDB tables and views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches DuckDB table and view metadata via C<information_schema.tables>.
Skips system schemas (C<information_schema>, C<pg_catalog>).

=head1 METHODS

=head2 fetch

    my $tables = DBIO::DuckDB::Introspect::Tables->fetch($dbh, $schema);
    my $tables = DBIO::DuckDB::Introspect::Tables->fetch($dbh, $schema, $catalog);

Returns a hashref keyed by table name. Each value has: C<table_name>,
C<kind> (C<table> or C<view>), C<schema>. A view also has
C<view_definition>, the text DuckDB keeps of its query; the diff compares it
(L<DBIO::DuckDB::Diff::View>).

When C<$catalog> is defined an C<AND table_catalog = ?> clause is added.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
