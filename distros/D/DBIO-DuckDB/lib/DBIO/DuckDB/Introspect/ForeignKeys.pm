package DBIO::DuckDB::Introspect::ForeignKeys;
# ABSTRACT: Introspect DuckDB foreign keys

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Introspect::Base ();



sub fetch {
  my ($class, $dbh, $schema, $tables, $catalog) = @_;
  $schema //= 'main';
  my %fks;

  # The columns come from duckdb_constraints(), which keeps the two column
  # lists of a key in order and side by side. information_schema cannot do
  # that: its constraint_column_usage has no position, and joining it to
  # key_column_usage pairs every key column with every parent column (a
  # composite key came out as n*n columns, and once more for each constraint
  # of the parent on the same columns). The actions and the match option come
  # from information_schema.referential_constraints, by constraint name.
  my $fk_sql = q{
    SELECT table_name, constraint_name,
           constraint_column_names, referenced_table, referenced_column_names
    FROM duckdb_constraints()
    WHERE constraint_type = 'FOREIGN KEY' AND schema_name = ?
  };
  my @fk_bind = ($schema);

  my $rules_sql = q{
    SELECT constraint_name, update_rule, delete_rule, match_option
    FROM information_schema.referential_constraints
    WHERE constraint_schema = ?
  };
  my @rules_bind = ($schema);

  if (defined $catalog) {
    $fk_sql .= q{ AND database_name = ?};
    push @fk_bind, $catalog;
    $rules_sql .= q{ AND constraint_catalog = ?};
    push @rules_bind, $catalog;
  }

  $fk_sql .= q{ ORDER BY table_name, constraint_name};

  my $sth = $dbh->prepare($fk_sql);
  my $ok = eval { $sth->execute(@fk_bind); 1 };
  return \%fks unless $ok;

  my %rule;
  {
    my $rsth = $dbh->prepare($rules_sql);
    if (eval { $rsth->execute(@rules_bind); 1 }) {
      while (my $row = $rsth->fetchrow_hashref) {
        $rule{ $row->{constraint_name} } = $row;
      }
    }
  }

  while (my $row = $sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{table_name} };
    my $rule = $rule{ $row->{constraint_name} } || {};
    push @{ $fks{ $row->{table_name} } }, {
      constraint_name => $row->{constraint_name},
      from_table   => $row->{table_name},
      from_columns => [ @{ $row->{constraint_column_names} } ],
      to_table     => $row->{referenced_table},
      to_columns   => [ @{ $row->{referenced_column_names} } ],
      on_update    => $rule->{update_rule},
      on_delete    => $rule->{delete_rule},
      match        => $rule->{match_option},
    };
  }

  return \%fks;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Introspect::ForeignKeys - Introspect DuckDB foreign keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches foreign-key metadata via C<information_schema.referential_constraints>
joined against C<key_column_usage>. Composite FKs are grouped by
constraint name.

DuckDB accepts FK declarations but does not enforce them as of 1.x. They
are still round-tripped here for schema correctness.

=head1 METHODS

=head2 fetch

    my $fks = DBIO::DuckDB::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);
    my $fks = DBIO::DuckDB::Introspect::ForeignKeys->fetch($dbh, $schema, $tables, $catalog);

Returns a hashref keyed by table name, each value an arrayref of FK
hashrefs with: C<constraint_name>, C<from_columns>, C<to_table>, C<to_columns>,
C<on_update>, C<on_delete>, C<match>.

When C<$catalog> is defined, C<AND tc.table_catalog = ?> and
C<AND rc.constraint_catalog = ?> clauses are added.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
