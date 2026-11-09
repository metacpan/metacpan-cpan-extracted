package DBIO::Sybase::Introspect::ForeignKeys;
# ABSTRACT: Introspect Sybase ASE foreign keys

use strict;
use warnings;

our $VERSION = '0.900004';



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  my %foreign_keys;

  my $keys = join ', ',
    (map { "col_name(r.tableid, r.fokey$_) AS fk$_" } 1 .. 16),
    (map { "col_name(r.reftabid, r.refkey$_) AS rk$_" } 1 .. 16);

  my $rows = $dbh->selectall_arrayref(qq{
    SELECT o.name AS table_name,
           object_name(r.constrid) AS constraint_name,
           object_name(r.reftabid) AS ref_table_name,
           r.keycnt, $keys
    FROM sysreferences r
    JOIN sysobjects o ON o.id = r.tableid
    JOIN sysusers   u ON u.uid = o.uid
    WHERE u.name = ?
      AND r.pmrydbname IS NULL
      AND r.frgndbname IS NULL
    ORDER BY o.name, object_name(r.constrid)
  }, { Slice => {} }, $schema);

  for my $row (@$rows) {
    next unless exists $tables->{ $row->{table_name} };
    for my $n (1 .. ($row->{keycnt} // 0)) {
      push @{ $foreign_keys{ $row->{table_name} } }, {
        constraint_name => $row->{constraint_name},
        column_name     => $row->{"fk$n"},
        ref_table_name  => $row->{ref_table_name},
        ref_column_name => $row->{"rk$n"},
        update_rule     => 'NO ACTION',
        delete_rule     => 'NO ACTION',
      };
    }
  }

  return \%foreign_keys;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Introspect::ForeignKeys - Introspect Sybase ASE foreign keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches foreign key metadata from the ASE system catalog: C<sysreferences>
(one row per constraint, key columns as colids C<fokey1..16> /
C<refkey1..16>, resolved with C<col_name()>), joined to C<sysobjects> /
C<sysusers> for the owner of the referencing table. SAP ASE has no
C<INFORMATION_SCHEMA> views.

ASE has no declarative referential actions -- C<ON DELETE> / C<ON UPDATE> is
a syntax error (Msg 156, ASE 16.0 SP02); a reference always restricts. Both
rules are therefore reported as C<NO ACTION>, which
L<DBIO::Sybase::Diff::ForeignKey> renders as no clause. A schema that
declares any other action is refused by L<DBIO::Sybase::DDL>, so
the two sides of a deploy diff never disagree on one. References into
another database (C<pmrydbname> / C<frgndbname> set) are skipped: their
colids and table ids belong to that database's catalog.

=head1 METHODS

=head2 fetch

    my $fks = DBIO::Sybase::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::Sybase::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
per-column rows (C<constraint_name>, C<column_name>, C<ref_table_name>,
C<ref_column_name>, C<update_rule>, C<delete_rule>) in key order, which
L<DBIO::Sybase::Introspect> groups into one entry per constraint.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
