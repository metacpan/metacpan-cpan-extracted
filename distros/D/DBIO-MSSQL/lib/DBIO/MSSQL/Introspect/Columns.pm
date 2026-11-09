package DBIO::MSSQL::Introspect::Columns;
# ABSTRACT: Introspect MSSQL columns

use strict;
use warnings;

our $VERSION = '0.900004';



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  my %columns;

  # Every column below is aliased explicitly and in lower case: an alias is
  # echoed into the result metadata verbatim, which is the one way to be sure
  # of the hash keys without depending on the handle's FetchHashKeyName.
  # INFORMATION_SCHEMA reports its columns UPPERCASE; unaliased, the key case
  # in the row hash is decided by the transport, not by this code.
  #
  # Pull all columns for the schema in one go.
  my $col_sth = $dbh->prepare(q{
    SELECT table_name AS table_name, column_name AS column_name,
           data_type AS data_type, is_nullable AS is_nullable,
           column_default AS column_default,
           ordinal_position AS ordinal_position,
           character_maximum_length AS character_maximum_length
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
    SELECT kcu.table_name AS table_name, kcu.column_name AS column_name,
           kcu.ordinal_position AS ordinal_position,
           tc.constraint_name AS constraint_name
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
        $col->{pk_constraint_name} = $row->{constraint_name};
        last;
      }
    }
  }

  # Is the index behind the primary key clustered? (karr k74)
  my $cl_sth = $dbh->prepare(q{
    SELECT t.name AS table_name, i.type_desc AS index_kind
    FROM sys.indexes i
    JOIN sys.tables t ON i.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE i.is_primary_key = 1 AND s.name = ?
  });
  $cl_sth->execute($schema);
  while (my $row = $cl_sth->fetchrow_hashref) {
    my $list = $columns{ $row->{table_name} } or next;
    $_->{is_pk} && ($_->{pk_clustered} = lc($row->{index_kind} // '') eq 'clustered' ? 1 : 0)
      for @$list;
  }

  # Identity columns (auto-increment).
  my $id_sth = $dbh->prepare(q{
    SELECT c.table_name AS table_name, c.column_name AS column_name
    FROM INFORMATION_SCHEMA.COLUMNS c
    JOIN sys.columns sc ON c.column_name = sc.name AND c.table_name = OBJECT_NAME(sc.object_id)
     AND c.table_schema = OBJECT_SCHEMA_NAME(sc.object_id)
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

  # DEFAULT constraint names. INFORMATION_SCHEMA.COLUMNS reports the default
  # EXPRESSION (column_default) but not the name of the object holding it, and
  # T-SQL drops a default by name -- so the name has to come from sys.
  #
  # Every column is aliased explicitly and in lower case: an alias is echoed
  # into the result metadata verbatim, which is the one way to be sure of the
  # hash keys below without depending on the handle's FetchHashKeyName.
  my $df_sth = $dbh->prepare(q{
    SELECT o.name  AS table_name,
           c.name  AS column_name,
           dc.name AS constraint_name
    FROM sys.default_constraints dc
    JOIN sys.columns c
      ON c.object_id = dc.parent_object_id
     AND c.column_id = dc.parent_column_id
    JOIN sys.objects o
      ON o.object_id = dc.parent_object_id
    JOIN sys.schemas s
      ON s.schema_id = o.schema_id
    WHERE s.name = ?
  });
  $df_sth->execute($schema);

  while (my $row = $df_sth->fetchrow_hashref) {
    my $list = $columns{ $row->{table_name} } or next;
    for my $col (@$list) {
      if ($col->{column_name} eq $row->{column_name}) {
        $col->{default_constraint_name} = $row->{constraint_name};
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

version 0.900004

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
C<is_pk>, C<pk_position>, C<is_identity>, C<size>,
C<default_constraint_name>, and on the columns of the primary key
C<pk_constraint_name> and C<pk_clustered>.

C<pk_clustered> is 1 when the index behind the primary key is C<CLUSTERED>, 0
when it is C<NONCLUSTERED> (C<sys.indexes>, C<is_primary_key = 1>), on each
column of the key. It is compared (L<DBIO::MSSQL::Diff::PrimaryKey>): the
classes create the key clustered, and a live key that is not is replaced.

C<pk_constraint_name> is the live name of the primary key, on each of its
columns: the key is dropped by that name (L<DBIO::MSSQL::Diff::PrimaryKey>), and
a key created without a name has one the server made up. It is not compared.

C<default_constraint_name> is the live, server-assigned name of the column's
C<DEFAULT> constraint (C<undef> when the column has none). Transact-SQL has no
C<ALTER COLUMN ... DROP DEFAULT>: a default is an object in its own right and
is removed with C<< ALTER TABLE ... DROP CONSTRAINT <name> >>, so
L<DBIO::MSSQL::Diff::Column> cannot replace a default without knowing that
name. It is carried for the same reason and on the same terms as the
foreign-key C<constraint_name> of the canonical model (ADR 0021): metadata for
the diff/deploy layer, B<not> a compared attribute -- two servers name the same
default differently, so comparing it would make every deploy report a phantom
change. C<DBIO::Diff::Compare::changed_column_fields> does not look at it, and
neither does C<DBIO::Introspect::Base::table_columns_info>, which projects a
fixed key set.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
