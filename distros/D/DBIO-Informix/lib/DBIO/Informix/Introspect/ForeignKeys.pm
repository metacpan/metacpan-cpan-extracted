package DBIO::Informix::Introspect::ForeignKeys;
# ABSTRACT: Introspect Informix foreign keys

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Informix::Introspect::Util ();



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  my %fks;

  local $dbh->{FetchHashKeyName} = 'NAME_lc';

  my $q       = DBIO::Informix::Introspect::Util::qualifier($schema);
  my $parts   = DBIO::Informix::Introspect::Util::_parts_sql();
  my $rparts  = DBIO::Informix::Introspect::Util::_rparts_sql();
  my %names;   # tabid => { colno => colname }

  for my $from_table (sort keys %$tables) {
    my $sth = $dbh->prepare(qq{
      SELECT c.constrname AS fk_name,
             t.tabid AS tabid,
             rt.tabname AS to_table,
             r.ptabid AS ptabid,
             $parts,
             $rparts,
             r.matchtype AS match, r.updrule AS upd_rule, r.delrule AS del_rule
      FROM $q.sysconstraints c
      JOIN $q.systables t ON c.tabid = t.tabid
      JOIN $q.sysreferences r ON c.constrid = r.constrid
      JOIN $q.sysconstraints rc ON r.primary = rc.constrid
      JOIN $q.systables rt ON r.ptabid = rt.tabid
      JOIN $q.sysindexes i ON i.tabid = c.tabid AND i.idxname = c.idxname
      JOIN $q.sysindexes ri ON ri.tabid = r.ptabid AND ri.idxname = rc.idxname
      WHERE c.constrtype = 'R'
        AND t.tabname = ?
      ORDER BY c.constrname
    });
    $sth->execute($from_table);
    my @rows = @{ $sth->fetchall_arrayref({}) };
    $sth->finish;

    for my $row (@rows) {
      my $from_names = $names{ $row->{tabid} }  //= DBIO::Informix::Introspect::Util::column_names($dbh, $q, $row->{tabid});
      my $to_names   = $names{ $row->{ptabid} } //= DBIO::Informix::Introspect::Util::column_names($dbh, $q, $row->{ptabid});

      push @{ $fks{$from_table} }, {
        fk_name      => $row->{fk_name},
        from_columns => [ DBIO::Informix::Introspect::Util::names_for(
          $from_names, DBIO::Informix::Introspect::Util::part_columns($row, 'part')) ],
        to_table     => $row->{to_table},
        to_columns   => [ DBIO::Informix::Introspect::Util::names_for(
          $to_names, DBIO::Informix::Introspect::Util::part_columns($row, 'rpart')) ],
        match        => $row->{match},
        upd_rule     => $row->{upd_rule},
        del_rule     => $row->{del_rule},
      };
    }
  }

  return \%fks;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Introspect::ForeignKeys - Introspect Informix foreign keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches foreign key metadata via C<sysconstraints> (C<constrtype = 'R'>)
and C<sysreferences>. Column numbers are resolved to names: the referencing
side through C<sysconstraints.idxname> -> C<sysindexes.part1..16> ->
C<syscolumns.colno> of the child table; the referenced side through
C<sysreferences.primary> -> that constraint's C<idxname> -> C<sysindexes>
-> C<syscolumns> of the table C<sysreferences.ptabid>. Only the tables
passed in are read, in the database named by C<$schema> (validated,
C<\w+>).

Measured against Informix 15.0.1: the C<sysreferences> columns
C<matchtype>, C<updrule>, C<delrule> exist and answer as documented
(C<N>, C<R>, and C<R> or C<C>). They are documented (HCL OneDB SQL reference,
I<sysreferences>, L<https://help.hcl-software.com/onedb/1.0.1/sqr/ids_sqr_055.html>):
C<delrule> is C<C> (cascading delete) or C<R> (restrict, the default);
C<updrule> and C<matchtype> are reserved and always show C<R> and C<N>.
The result keys are the raw C<match>, C<upd_rule> and C<del_rule>;
L<DBIO::Informix::Introspect> maps them to the canonical C<on_update> and
C<on_delete>.

=head1 METHODS

=head2 fetch

    my $fks = DBIO::Informix::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);

Returns a hashref keyed by table name. Each value is an arrayref of
foreign key hashrefs with keys: C<fk_name>, C<from_columns>, C<to_table>,
C<to_columns>, C<match>, C<upd_rule>, C<del_rule>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
