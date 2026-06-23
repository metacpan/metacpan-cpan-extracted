package DBIO::DuckDB::Introspect::Tables;
# ABSTRACT: Introspect DuckDB tables and views

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema, $catalog) = @_;
  $schema //= 'main';

  my $sql = q{
    SELECT table_name, table_type
    FROM information_schema.tables
    WHERE table_schema = ?
      AND table_name NOT LIKE 'sqlite_%'
  };
  my @bind = ($schema);

  if (defined $catalog) {
    $sql .= q{ AND table_catalog = ?};
    push @bind, $catalog;
  }

  $sql .= q{ ORDER BY table_name};

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

version 0.900000

=head1 DESCRIPTION

Fetches DuckDB table and view metadata via C<information_schema.tables>.
Skips system schemas (C<information_schema>, C<pg_catalog>).

=head1 METHODS

=head2 fetch

    my $tables = DBIO::DuckDB::Introspect::Tables->fetch($dbh, $schema);
    my $tables = DBIO::DuckDB::Introspect::Tables->fetch($dbh, $schema, $catalog);

Returns a hashref keyed by table name. Each value has: C<table_name>,
C<kind> (C<table> or C<view>), C<schema>.

When C<$catalog> is defined an C<AND table_catalog = ?> clause is added.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
