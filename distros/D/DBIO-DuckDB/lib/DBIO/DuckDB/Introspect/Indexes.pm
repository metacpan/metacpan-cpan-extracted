package DBIO::DuckDB::Introspect::Indexes;
# ABSTRACT: Introspect DuckDB indexes

use strict;
use warnings;

our $VERSION = '0.900004';



# The elements of the first parenthesised list of a CREATE INDEX statement,
# split at top-level commas. Double-quoted identifiers and single-quoted
# literals are skipped, so a comma or parenthesis in one does not count.
sub _index_elements {
  my ($sql) = @_;
  my ($depth, $start, $quote, @el, $cur) = (0);
  my @c = split //, $sql;
  for my $i (0 .. $#c) {
    my $ch = $c[$i];
    if ($quote) {
      $cur .= $ch if $depth;
      $quote = undef if $ch eq $quote;
      next;
    }
    if ($ch eq '"' || $ch eq "'") { $quote = $ch; $cur .= $ch if $depth; next }
    if ($ch eq '(') {
      $depth++;
      $cur .= $ch if $depth > 1;
      next;
    }
    if ($ch eq ')') {
      $depth--;
      if ($depth == 0) { push @el, $cur if defined $cur; last }
      $cur .= $ch;
      next;
    }
    if ($ch eq ',' && $depth == 1) { push @el, $cur; $cur = ''; next }
    $cur .= $ch if $depth;
  }
  for (@el) {
    s/^\s+|\s+$//g;
    s/^"((?:[^"]|"")*)"$/$1 =~ s{""}{"}gr/e unless /^\(/;
  }
  return @el;
}

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
    my @cols = _index_elements($sql);

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

version 0.900004

=head1 DESCRIPTION

Fetches index metadata via the C<duckdb_indexes()> system view. Each
entry captures C<index_name>, C<is_unique>, and the raw C<sql> of the
C<CREATE INDEX> statement. The column list, expression elements included,
is parsed out of the SQL.

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

An expression element of the index is kept as DuckDB writes it into the
statement, with its parentheses: C<(lower(b))>. A plain column is its name,
unquoted. DuckDB wraps every expression in a pair of parentheses and
normalises it (function names fold to upper case where it knows them), so
the same declaration always reads back as the same text.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
