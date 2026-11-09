package DBIO::SQLite::Introspect::Indexes;
# ABSTRACT: Introspect SQLite indexes

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::SQLite::Util qw(quote_identifier sql_tokens);



sub fetch {
  my ($class, $dbh, $tables) = @_;
  my %indexes;

  # Lookup of CREATE INDEX statements from sqlite_master so we can detect
  # partial indexes and recover the original column expressions.
  my $sql_lookup = $dbh->selectall_hashref(
    q{SELECT name, sql FROM sqlite_master WHERE type = 'index'},
    'name',
  );

  for my $table_name (sort keys %$tables) {
    my $list = $dbh->selectall_arrayref(
      sprintf('PRAGMA index_list(%s)', quote_identifier($table_name)),
      { Slice => {} },
    );

    my %t_idx;
    for my $idx (@$list) {
      my $info = $dbh->selectall_arrayref(
        sprintf('PRAGMA index_info(%s)', quote_identifier($idx->{name})),
        { Slice => {} },
      );
      my @cols = map { $_->{name} // '' } sort { $a->{seqno} <=> $b->{seqno} } @$info;

      my $sql = $sql_lookup->{ $idx->{name} }
        ? $sql_lookup->{ $idx->{name} }{sql}
        : undef;

      # The keyword, not the letters: an index, a table or a column may be
      # named "where", and stands in the statement between quotes then.
      my $partial = ($sql && grep {
        $_->[0] eq 'word' && uc $_->[1] eq 'WHERE'
      } sql_tokens($sql)) ? 1 : 0;

      $t_idx{ $idx->{name} } = {
        index_name => $idx->{name},
        is_unique  => $idx->{unique} ? 1 : 0,
        columns    => \@cols,
        sql        => $sql,
        origin     => $idx->{origin},
        partial    => $partial,
      };
    }
    $indexes{$table_name} = \%t_idx if %t_idx;
  }

  return \%indexes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Introspect::Indexes - Introspect SQLite indexes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches index metadata via C<PRAGMA index_list()> and C<PRAGMA
index_info()>, plus the original C<CREATE INDEX> statement from
C<sqlite_master> for partial / expression indexes. Auto-generated
indexes (origin C<u> / C<pk>) are kept in the model with their origin;
L<DBIO::SQLite::Diff::Index> skips them when diffing.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::SQLite::Introspect::Indexes->fetch($dbh, $tables);

Returns a hashref keyed by table name. Each value is a hashref keyed by
index name. Each index entry has: C<index_name>, C<is_unique>,
C<columns> (arrayref), C<sql> (CREATE statement, may be undef for
auto-generated UNIQUE indexes), C<origin> (C<c>=CREATE, C<u>=UNIQUE,
C<pk>=PRIMARY KEY), C<partial> (1 if WHERE clause present -- the keyword, as
L<DBIO::SQLite::Util/sql_tokens> reads the statement; a quoted name C<"where">
is not one).

A table and an index are named to the C<PRAGMA>s through
L<DBIO::SQLite::Util/quote_identifier>, so a name that holds a double quote is
read like any other.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
