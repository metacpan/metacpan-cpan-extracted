package DBIO::MySQL::Introspect::ForeignKeys;
# ABSTRACT: Introspect MySQL/MariaDB foreign keys

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Introspect::Base ();
use DBIO::MySQL::Introspect::Util ();



sub fetch {
  my ($class, $dbh, $tables) = @_;

  # On MySQL 8 the information_schema result-column labels come back UPPERCASE
  # regardless of the case written in the SELECT, while MariaDB returns them
  # lowercase. Force lowercase hash keys for this fetch so the $row->{lc} reads
  # below (and _aggregate_by_ordered's 'table_name'/'constraint_name' keys)
  # resolve on both engines. fetchall_arrayref({}) honours the sth's
  # FetchHashKeyName, which is captured from the dbh at prepare time.
  local $dbh->{FetchHashKeyName} = 'NAME_lc';

  my $mariadb = (scalar($dbh->selectrow_array('SELECT VERSION()')) // '') =~ /mariadb/i ? 1 : 0;

  my $sth = $dbh->prepare(q{
    SELECT
      kcu.table_name,
      kcu.constraint_name,
      kcu.column_name,
      kcu.referenced_table_name,
      kcu.referenced_column_name,
      kcu.ordinal_position,
      rc.update_rule,
      rc.delete_rule
    FROM information_schema.key_column_usage kcu
    JOIN information_schema.referential_constraints rc
      ON  rc.constraint_schema = kcu.table_schema
      AND rc.constraint_name   = kcu.constraint_name
    WHERE kcu.table_schema = DATABASE()
      AND kcu.referenced_table_name IS NOT NULL
    ORDER BY kcu.table_name, kcu.constraint_name, kcu.ordinal_position
  });
  $sth->execute;

  my $rows = $sth->fetchall_arrayref({});
  @$rows = grep { DBIO::MySQL::Introspect::Util->keep_table($tables, $_->{table_name}) } @$rows;

  # Group rows by table (preserving first-seen order) -- _aggregate_by_ordered
  # gives us an array of [ table, [ rows ] ] pairs, so the order in which
  # tables appear in the source DB is preserved.
  my $by_table = DBIO::Introspect::Base->_aggregate_by_ordered($rows, 'table_name');

  my %fks;
  for my $pair (@$by_table) {
    my ($tbl, $tbl_rows) = @$pair;

    # Within a table, group by constraint_name (also ordered, also first-seen
    # first). All rows of one constraint share its to_table / on_update /
    # on_delete, so we can lift those from any row -- the first one is fine.
    my $by_constraint = DBIO::Introspect::Base->_aggregate_by_ordered($tbl_rows, 'constraint_name');

    for my $ck_pair (@$by_constraint) {
      my ($name, $ck_rows) = @$ck_pair;
      my $head = $ck_rows->[0];
      push @{ $fks{$tbl} }, {
        constraint_name => $name,
        from_columns    => [ map { $_->{column_name} }            @$ck_rows ],
        to_table        => $head->{referenced_table_name},
        to_columns      => [ map { $_->{referenced_column_name} }  @$ck_rows ],
        on_update       => _rule($head->{update_rule}, $mariadb),
        on_delete       => _rule($head->{delete_rule}, $mariadb),
      };
    }
  }

  return \%fks;
}

# NO ACTION and RESTRICT are one action on a MariaDB (karr k116), two on a MySQL.
sub _rule {
  my ($rule, $mariadb) = @_;
  return 'RESTRICT' if $mariadb && defined $rule && uc $rule eq 'NO ACTION';
  return $rule;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Introspect::ForeignKeys - Introspect MySQL/MariaDB foreign keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches foreign key metadata by joining
C<information_schema.key_column_usage> against
C<information_schema.referential_constraints>, scoped to the current
C<DATABASE()> and filtered to the tables surfaced by
L<DBIO::MySQL::Introspect::Tables>. Composite foreign keys are grouped per
constraint via L<DBIO::Introspect::Base/_aggregate_by_ordered> (preserves
both first-seen table/constraint order and the column pairing within each
constraint).

=head1 METHODS

=head2 fetch

    my $fks = DBIO::MySQL::Introspect::ForeignKeys->fetch($dbh, $tables);

Given the tables hashref from L<DBIO::MySQL::Introspect::Tables>, returns a
hashref keyed by table name. Each value is an arrayref of foreign key
hashrefs (one per constraint) with keys: C<constraint_name>,
C<from_columns> (arrayref), C<to_table>, C<to_columns> (arrayref),
C<on_update>, C<on_delete>.

C<on_update> and C<on_delete> are what C<information_schema> reports, with one
exception: on a MariaDB, C<NO ACTION> is read as C<RESTRICT>. MariaDB stores
C<RESTRICT> where the DDL names no action (what C<install_ddl> writes for
C<NO ACTION>), but keeps an explicit C<NO ACTION> of a constraint made by hand
or by another tool; both check at once, and a diff that compared the two words
would drop and add the same constraint. MySQL reports
C<NO ACTION> and C<RESTRICT> and they stay two. Which server it is, the
version string says (C<SELECT VERSION()>), as in
L<DBIO::MySQL::Introspect::Columns>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
