package DBIO::SQLite::Introspect::Tables;
# ABSTRACT: Introspect SQLite tables and views

use strict;
use warnings;



sub fetch {
  my ($class, $dbh) = @_;

  my $sth = $dbh->prepare(q{
    SELECT name, type, sql
    FROM sqlite_master
    WHERE type IN ('table', 'view')
      AND name NOT LIKE 'sqlite_%'
    ORDER BY name
  });
  $sth->execute;

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    my $sql = $row->{sql} // '';

    # Detect WITHOUT ROWID and STRICT modifiers from the original CREATE
    my $without_rowid = $sql =~ /\bWITHOUT\s+ROWID\b/i  ? 1 : 0;
    my $strict        = $sql =~ /\)\s*STRICT\s*;?\s*$/i ? 1 : 0;

    $tables{ $row->{name} } = {
      table_name    => $row->{name},
      kind          => $row->{type},
      sql           => $sql,
      without_rowid => $without_rowid,
      strict        => $strict,
    };
  }

  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::Introspect::Tables - Introspect SQLite tables and views

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches SQLite table and view metadata from C<sqlite_master>. Skips
internal C<sqlite_*> objects and the C<dbio_changelog>/migration tables
when present.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::SQLite::Introspect::Tables->fetch($dbh);

Returns a hashref keyed by table name. Each value is a hashref with
keys: C<table_name>, C<kind> (C<table> or C<view>), C<sql> (the original
C<CREATE> statement from C<sqlite_master>), C<without_rowid>, C<strict>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
