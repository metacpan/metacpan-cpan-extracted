package DBIO::MSSQL::Introspect::Columns;
# ABSTRACT: Introspect MSSQL columns

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  my %columns;

  # Pull all columns for the schema in one go.
  my $col_sth = $dbh->prepare(q{
    SELECT table_name, column_name, data_type,
           is_nullable, column_default, ordinal_position,
           character_maximum_length
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = ?
    ORDER BY table_name, ordinal_position
  });
  $col_sth->execute($schema);

  while (my $row = $col_sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{table_name} };
    push @{ $columns{ $row->{table_name} } }, {
      column_name   => $row->{column_name},
      data_type     => $row->{data_type},
      not_null      => (lc($row->{is_nullable} // 'YES') eq 'no') ? 1 : 0,
      default_value => $row->{column_default},
      is_pk         => 0,
      pk_position   => 0,
      is_identity   => 0,
      is_auto_increment => 0,
      size         => $row->{character_maximum_length},
    };
  }

  # Primary-key membership.
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

  # Identity columns (auto-increment).
  my $id_sth = $dbh->prepare(q{
    SELECT c.table_name, c.column_name
    FROM INFORMATION_SCHEMA.COLUMNS c
    JOIN sys.columns sc ON c.column_name = sc.name AND c.table_name = OBJECT_NAME(sc.object_id)
    WHERE c.table_schema = ? AND sc.is_identity = 1
  });
  $id_sth->execute($schema);

  while (my $row = $id_sth->fetchrow_hashref) {
    my $list = $columns{ $row->{table_name} } or next;
    for my $col (@$list) {
      if ($col->{column_name} eq $row->{column_name}) {
        $col->{is_identity} = 1;
        $col->{is_auto_increment} = 1;
        last;
      }
    }
  }

  return \%columns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Introspect::Columns - Introspect MSSQL columns

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches column metadata via C<INFORMATION_SCHEMA.COLUMNS>. Primary key
information is joined in via C<INFORMATION_SCHEMA.KEY_COLUMN_USAGE> +
C<INFORMATION_SCHEMA.TABLE_CONSTRAINTS>.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::MSSQL::Introspect::Columns->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::MSSQL::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
column hashrefs in C<ordinal_position> order with keys:
C<column_name>, C<data_type>, C<not_null>, C<default_value>,
C<is_pk>, C<pk_position>, C<is_identity>, C<size>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
