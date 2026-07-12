package DBIO::DuckDB::Introspect::Columns;
# ABSTRACT: Introspect DuckDB columns

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema, $tables, $catalog) = @_;
  $schema //= 'main';
  my %columns;

  # Pull all columns for the schema in one go.
  my $col_sql = q{
    SELECT table_name, column_name, data_type,
           is_nullable, column_default, ordinal_position
    FROM information_schema.columns
    WHERE table_schema = ?
  };
  my @col_bind = ($schema);

  if (defined $catalog) {
    $col_sql .= q{ AND table_catalog = ?};
    push @col_bind, $catalog;
  }

  $col_sql .= q{ ORDER BY table_name, ordinal_position};

  my $col_sth = $dbh->prepare($col_sql);
  $col_sth->execute(@col_bind);

  while (my $row = $col_sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{table_name} };
    push @{ $columns{ $row->{table_name} } }, {
      column_name   => $row->{column_name},
      data_type     => $row->{data_type},
      not_null      => (lc($row->{is_nullable} // 'YES') eq 'no') ? 1 : 0,
      default_value => $row->{column_default},
      is_pk         => 0,
      pk_position   => 0,
    };
  }

  # Primary-key membership.
  my $pk_sql = q{
    SELECT kcu.table_name, kcu.column_name, kcu.ordinal_position
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
     AND tc.table_schema    = kcu.table_schema
     AND tc.table_name      = kcu.table_name
    WHERE tc.constraint_type = 'PRIMARY KEY'
      AND tc.table_schema    = ?
  };
  my @pk_bind = ($schema);

  if (defined $catalog) {
    $pk_sql .= q{ AND kcu.table_catalog = ?};
    push @pk_bind, $catalog;
  }

  my $pk_sth = $dbh->prepare($pk_sql);
  $pk_sth->execute(@pk_bind);

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

  return \%columns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Introspect::Columns - Introspect DuckDB columns

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches column metadata via C<information_schema.columns>. Primary-key
information is joined in via C<information_schema.key_column_usage> +
C<table_constraints>.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::DuckDB::Introspect::Columns->fetch($dbh, $schema, $tables);
    my $columns = DBIO::DuckDB::Introspect::Columns->fetch($dbh, $schema, $tables, $catalog);

Given the tables hashref from L<DBIO::DuckDB::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
column hashrefs in C<ordinal_position> order with keys:
C<column_name>, C<data_type>, C<not_null>, C<default_value>,
C<is_pk>, C<pk_position>.

When C<$catalog> is defined, C<AND table_catalog = ?> clauses are added
to both the columns and primary-key queries.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
