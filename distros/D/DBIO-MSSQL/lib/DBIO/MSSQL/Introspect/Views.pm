package DBIO::MSSQL::Introspect::Views;
# ABSTRACT: Introspect MSSQL view definitions

use strict;
use warnings;

our $VERSION = '0.900004';


sub fetch {
  my ($class, $dbh, $schema) = @_;
  $schema //= 'dbo';

  my $sth = $dbh->prepare(q{
    SELECT v.name AS view_name, CAST(LEN(m.definition) AS int) AS len
    FROM sys.views v
    JOIN sys.sql_modules m ON m.object_id = v.object_id
    WHERE v.schema_id = SCHEMA_ID(?) AND m.definition IS NOT NULL
    ORDER BY v.name
  });
  $sth->execute($schema);
  my @views = map { [ $_->{view_name}, $_->{len} ] } @{ $sth->fetchall_arrayref({}) };

  my %defs;
  for my $view (@views) {
    my ($name, $len) = @$view;
    my $text = '';
    for (my $at = 1; $at <= $len; $at += 4000) {
      my $piece_sql = sprintf q{
        SELECT CAST(SUBSTRING(m.definition, %d, 4000) AS nvarchar(4000)) AS piece
        FROM sys.views v
        JOIN sys.sql_modules m ON m.object_id = v.object_id
        WHERE v.schema_id = SCHEMA_ID(?) AND v.name = ?
      }, $at;
      my ($piece) = $dbh->selectrow_array($piece_sql, undef, $schema, $name);
      $text .= $piece // '';
    }
    $defs{$name} = $text;
  }
  return \%defs;
}


sub dependencies {
  my ($class, $dbh, $schema) = @_;
  $schema //= 'dbo';
  my $sth = $dbh->prepare(q{
    SELECT DISTINCT v.name AS view_name, rs.name AS ref_schema, rv.name AS ref_name
    FROM sys.sql_expression_dependencies d
    JOIN sys.views v  ON v.object_id  = d.referencing_id
    JOIN sys.views rv ON rv.object_id = d.referenced_id
    JOIN sys.schemas rs ON rs.schema_id = rv.schema_id
    WHERE v.schema_id = SCHEMA_ID(?)
    ORDER BY v.name, rs.name, rv.name
  });
  $sth->execute($schema);
  my %deps;
  push @{ $deps{ $_->{view_name} } }, [ $_->{ref_schema}, $_->{ref_name} ]
    for @{ $sth->fetchall_arrayref({}) };
  return \%deps;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Introspect::Views - Introspect MSSQL view definitions

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Reads the stored text of the views of one schema from C<sys.sql_modules>. The
text is what the server was given: it begins with C<CREATE VIEW ... AS> (or
C<CREATE OR ALTER VIEW>), written as the author wrote it.
L<DBIO::MSSQL::Diff::View> compares the part after C<AS>.

=head1 METHODS

=head2 fetch

    my $defs = DBIO::MSSQL::Introspect::Views->fetch($dbh, $schema);

A hashref keyed by view name, each value the full definition text. The text is
read in pieces of 4000 characters (C<nvarchar(4000)>), because a long value
(C<nvarchar(max)>) is cut at the session's C<TEXTSIZE> over DBD::Sybase, without
an error. A view whose text the server does not give (an encrypted view) is not
in the result.

=head2 dependencies

    my $deps = DBIO::MSSQL::Introspect::Views->dependencies($dbh, $schema);

For every view of C<$schema> that reads other views
(C<sys.sql_expression_dependencies>), a list of C<[ schema, name ]> of the views
it reads, keyed by view name. A view that reads no view is not in the result.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
