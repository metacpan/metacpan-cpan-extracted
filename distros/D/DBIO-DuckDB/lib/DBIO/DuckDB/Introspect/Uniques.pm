package DBIO::DuckDB::Introspect::Uniques;
# ABSTRACT: Introspect DuckDB UNIQUE constraints

use strict;
use warnings;

our $VERSION = '0.900004';


sub fetch {
  my ($class, $dbh, $schema, $tables, $catalog) = @_;
  $schema //= 'main';
  my %uniques;

  my $sql = q{
    SELECT table_name, constraint_name, constraint_column_names
    FROM duckdb_constraints()
    WHERE schema_name = ? AND constraint_type = 'UNIQUE'
  };
  my @bind = ($schema);
  if (defined $catalog) {
    $sql .= q{ AND database_name = ?};
    push @bind, $catalog;
  }
  $sql .= q{ ORDER BY table_name, constraint_name};

  my $sth = $dbh->prepare($sql);
  return \%uniques unless eval { $sth->execute(@bind); 1 };

  while (my $row = $sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{table_name} };
    $uniques{ $row->{table_name} }{ $row->{constraint_name} } = {
      constraint_name => $row->{constraint_name},
      columns         => [ @{ $row->{constraint_column_names} } ],
    };
  }

  return \%uniques;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Introspect::Uniques - Introspect DuckDB UNIQUE constraints

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches the C<UNIQUE> constraints of the tables, the ones written in
C<CREATE TABLE> (a unique I<index> is no constraint and is read by
L<DBIO::DuckDB::Introspect::Indexes>; the primary key by
L<DBIO::DuckDB::Introspect::Columns>). The diff compares them by their column
tuple, in order.

=head1 METHODS

=head2 fetch

    my $uniques = DBIO::DuckDB::Introspect::Uniques->fetch($dbh, $schema, $tables, $catalog);

A hashref C<< { $table => { $constraint_name => { constraint_name, columns } } } >>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
