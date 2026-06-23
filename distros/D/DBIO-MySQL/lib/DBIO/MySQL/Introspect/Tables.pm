package DBIO::MySQL::Introspect::Tables;
# ABSTRACT: Introspect MySQL/MariaDB tables and views

use strict;
use warnings;



sub fetch {
  my ($class, $dbh) = @_;

  my $sth = $dbh->prepare(q{
    SELECT
      table_name      AS name,
      table_type      AS table_type,
      engine          AS engine,
      table_collation AS table_collation,
      row_format      AS row_format,
      table_comment   AS comment
    FROM information_schema.tables
    WHERE table_schema = DATABASE()
    ORDER BY table_name
  });
  $sth->execute;

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    my $kind = ($row->{table_type} // '') eq 'VIEW' ? 'view' : 'table';
    $tables{ $row->{name} } = {
      table_name      => $row->{name},
      kind            => $kind,
      engine          => $row->{engine},
      table_collation => $row->{table_collation},
      row_format      => $row->{row_format},
      comment         => $row->{comment},
    };
  }
  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Introspect::Tables - Introspect MySQL/MariaDB tables and views

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches MySQL/MariaDB table and view metadata from
C<information_schema.tables>, scoped to the current C<DATABASE()>.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::MySQL::Introspect::Tables->fetch($dbh);

Returns a hashref keyed by table name. Each value is a hashref with keys:
C<table_name>, C<kind> (C<table> or C<view>), C<engine>,
C<table_collation>, C<row_format>, C<comment>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
