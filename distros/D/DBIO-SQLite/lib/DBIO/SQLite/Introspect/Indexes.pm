package DBIO::SQLite::Introspect::Indexes;
# ABSTRACT: Introspect SQLite indexes

use strict;
use warnings;



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
      qq{PRAGMA index_list("$table_name")}, { Slice => {} }
    );

    my %t_idx;
    for my $idx (@$list) {
      my $info = $dbh->selectall_arrayref(
        qq{PRAGMA index_info("$idx->{name}")}, { Slice => {} }
      );
      my @cols = map { $_->{name} // '' } sort { $a->{seqno} <=> $b->{seqno} } @$info;

      my $sql = $sql_lookup->{ $idx->{name} }
        ? $sql_lookup->{ $idx->{name} }{sql}
        : undef;

      my $partial = ($sql && $sql =~ /\bWHERE\b/i) ? 1 : 0;

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

version 0.900000

=head1 DESCRIPTION

Fetches index metadata via C<PRAGMA index_list()> and C<PRAGMA
index_info()>, plus the original C<CREATE INDEX> statement from
C<sqlite_master> for partial / expression indexes. Skips
auto-generated indexes (PRIMARY KEY, UNIQUE constraint indexes).

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::SQLite::Introspect::Indexes->fetch($dbh, $tables);

Returns a hashref keyed by table name. Each value is a hashref keyed by
index name. Each index entry has: C<index_name>, C<is_unique>,
C<columns> (arrayref), C<sql> (CREATE statement, may be undef for
auto-generated UNIQUE indexes), C<origin> (C<c>=CREATE, C<u>=UNIQUE,
C<pk>=PRIMARY KEY), C<partial> (1 if WHERE clause present).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
