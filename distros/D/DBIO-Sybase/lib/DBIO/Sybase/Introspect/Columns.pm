package DBIO::Sybase::Introspect::Columns;
# ABSTRACT: Introspect Sybase ASE columns

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  my %columns;

  my $col_sth = $dbh->prepare(q{
    SELECT table_name, column_name, data_type,
           is_nullable, column_default, ordinal_position
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = ?
    ORDER BY table_name, ordinal_position
  });
  $col_sth->execute($schema);

  while (my $row = $col_sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{table_name} };
    push @{ $columns{ $row->{table_name} } }, {
      column_name        => $row->{column_name},
      data_type          => $row->{data_type},
      not_null           => (lc($row->{is_nullable} // 'YES') eq 'no') ? 1 : 0,
      default_value      => $row->{column_default},
      is_pk              => 0,
      pk_position        => 0,
      is_auto_increment  => 0,
    };
  }

  my $pk_sth = $dbh->prepare(q{
    SELECT kcu.table_name, kcu.column_name, kcu.ordinal_position
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
      ON tc.constraint_name = kcu.constraint_name
     AND tc.table_schema    = kcu.table_schema
     AND tc.table_name      = kcu.table_name
    WHERE tc.constraint_type = 'PRIMARY KEY'
      AND tc.table_schema    = ?
  });
  $pk_sth->execute($schema);

  while (my $row = $pk_sth->fetchrow_hashref) {
    my $list = $columns{ $row->{table_name} } or next;
    for my $col (@$list) {
      if ($col->{column_name} eq $row->{column_name}) {
        $col->{is_pk}       = 1;
        $col->{pk_position} = $row->{ordinal_position} || 1;
        last;
      }
    }
  }

  _mark_identity($dbh, $schema, \%columns);

  return \%columns;
}

# Flag identity (autoincrement) columns. The identity attribute is carried in
# syscolumns.status bit 0x80, which INFORMATION_SCHEMA does not surface. This
# is best-effort: any failure (privileges, non-ASE server) leaves
# is_auto_increment at its 0 default rather than aborting introspection.
sub _mark_identity {
  my ($dbh, $schema, $columns) = @_;

  my $rows = eval {
    my $sth = $dbh->prepare(q{
      SELECT o.name AS table_name, c.name AS column_name
      FROM syscolumns c
      JOIN sysobjects o ON c.id = o.id
      JOIN sysusers   u ON o.uid = u.uid
      WHERE o.type = 'U'
        AND u.name = ?
        AND (c.status & 128) = 128
    });
    $sth->execute($schema);
    $sth->fetchall_arrayref({});
  } or return;

  for my $row (@$rows) {
    my $list = $columns->{ $row->{table_name} } or next;
    for my $col (@$list) {
      if ($col->{column_name} eq $row->{column_name}) {
        $col->{is_auto_increment} = 1;
        last;
      }
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Introspect::Columns - Introspect Sybase ASE columns

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches column metadata via C<INFORMATION_SCHEMA.COLUMNS>. Primary key
information is joined in via C<INFORMATION_SCHEMA.KEY_COLUMN_USAGE> +
C<INFORMATION_SCHEMA.TABLE_CONSTRAINTS>.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::Sybase::Introspect::Columns->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::Sybase::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
column hashrefs in C<ordinal_position> order with keys:
C<column_name>, C<data_type>, C<not_null>, C<default_value>,
C<is_pk>, C<pk_position>, C<is_auto_increment>.

Identity (autoincrement) columns are detected from the C<syscolumns>
identity status bit (C<0x80>), which is not exposed through
C<INFORMATION_SCHEMA>. The detection query is best-effort: if it fails
(insufficient privileges, or a non-ASE server), columns are still returned
with C<is_auto_increment> defaulting to C<0>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
