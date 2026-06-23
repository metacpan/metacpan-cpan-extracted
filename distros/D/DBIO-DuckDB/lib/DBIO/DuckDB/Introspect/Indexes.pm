package DBIO::DuckDB::Introspect::Indexes;
# ABSTRACT: Introspect DuckDB indexes

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema, $tables, $catalog) = @_;
  $schema //= 'main';
  my %indexes;

  my $idx_sql = q{
    SELECT table_name, index_name, is_unique, is_primary, sql
    FROM duckdb_indexes()
    WHERE schema_name = ?
  };
  my @idx_bind = ($schema);

  if (defined $catalog) {
    $idx_sql .= q{ AND database_name = ?};
    push @idx_bind, $catalog;
  }

  $idx_sql .= q{ ORDER BY table_name, index_name};

  my $sth = $dbh->prepare($idx_sql);

  my $ok = eval { $sth->execute(@idx_bind); 1 };
  return \%indexes unless $ok;

  while (my $row = $sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{table_name} };
    next if $row->{is_primary};  # skip PK-backed auto indexes

    my $sql = $row->{sql} // '';
    my @cols;
    if ($sql =~ /\(([^()]*)\)/) {
      @cols = map { s/^\s+|\s+$//gr } split /,/, $1;
      s/^"(.*)"$/$1/ for @cols;
    }

    my $partial = ($sql =~ /\bWHERE\b/i) ? 1 : 0;

    $indexes{ $row->{table_name} }{ $row->{index_name} } = {
      index_name => $row->{index_name},
      is_unique  => $row->{is_unique} ? 1 : 0,
      columns    => \@cols,
      sql        => $sql,
      origin     => 'c',
      partial    => $partial,
    };
  }

  return \%indexes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Introspect::Indexes - Introspect DuckDB indexes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches index metadata via the C<duckdb_indexes()> system view. Each
entry captures C<index_name>, C<is_unique>, and the raw C<sql> of the
C<CREATE INDEX> statement. Column list is parsed out of the SQL when
possible.

Auto-generated indexes backing PRIMARY KEY and UNIQUE constraints are
omitted -- they belong to the table, not to explicit CREATE INDEX.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::DuckDB::Introspect::Indexes->fetch($dbh, $schema, $tables);
    my $indexes = DBIO::DuckDB::Introspect::Indexes->fetch($dbh, $schema, $tables, $catalog);

Returns a hashref keyed by table name, each value a hashref keyed by
index name with: C<index_name>, C<is_unique>, C<columns> (arrayref),
C<sql>, C<origin>, C<partial>.

When C<$catalog> is defined, C<AND database_name = ?> is added to the
C<duckdb_indexes()> query.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
