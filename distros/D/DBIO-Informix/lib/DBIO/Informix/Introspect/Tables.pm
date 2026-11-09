package DBIO::Informix::Introspect::Tables;
# ABSTRACT: Introspect Informix tables and views

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Informix::Introspect::Util ();



sub fetch {
  my ($class, $dbh, $schema) = @_;

  my $q = DBIO::Informix::Introspect::Util::qualifier($schema);

  my $sth = $dbh->prepare(qq{
    SELECT tabname, owner, tabtype
    FROM $q.systables
    WHERE tabtype IN ('T', 'V')
      AND tabid >= 100
    ORDER BY tabname
  });
  $sth->execute;

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    my $kind = $row->{tabtype} eq 'T' ? 'table' : 'view';
    $tables{ $row->{tabname} } = {
      table_name => $row->{tabname},
      owner      => do { my $o = $row->{owner}; $o =~ s/\s+\z// if defined $o; $o },
      kind       => $kind,
    };
  }

  # The name of each primary key, to drop it with (Informix has no DROP
  # PRIMARY KEY).
  my $psth = $dbh->prepare(qq{
    SELECT t.tabname, c.constrname
    FROM $q.sysconstraints c JOIN $q.systables t ON t.tabid = c.tabid
    WHERE c.constrtype = 'P' AND t.tabtype = 'T' AND t.tabid >= 100
  });
  $psth->execute;
  while (my $row = $psth->fetchrow_hashref) {
    my ($name, $constr) = @{$row}{qw(tabname constrname)};
    $tables{$name}{primary_key_name} = $constr =~ s/\s+\z//r if exists $tables{$name};
  }

  # A view carries the text the server keeps for it (sysviews, in chunks of
  # one row each in the order of seqno). The server writes the definition in
  # its own form (owner-qualified, columns listed, padded with blanks), so
  # two definitions are the same when their words are.
  my @views = grep { $tables{$_}{kind} eq 'view' } keys %tables;
  if (@views) {
    my $vsth = $dbh->prepare(qq{
      SELECT t.tabname, v.seqno, v.viewtext
      FROM $q.sysviews v JOIN $q.systables t ON t.tabid = v.tabid
      WHERE t.tabtype = 'V' AND t.tabid >= 100
      ORDER BY t.tabname, v.seqno
    });
    $vsth->execute;
    my %text;
    while (my ($name, undef, $chunk) = $vsth->fetchrow_array) {
      $text{$name} .= $chunk;
    }
    for my $name (@views) {
      my $def = $text{$name} // '';
      $def =~ s/\s+/ /g;
      $def =~ s/\s*;?\s*\z//;
      $tables{$name}{definition} = $def;
    }
  }

  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Introspect::Tables - Introspect Informix tables and views

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches Informix table and view metadata from C<systables>.

Measured against Informix 15.0.1. User tables are the ones with
C<tabid E<gt>= 100>, whoever owns them (the database owner, usually the
connecting user, is C<informix>, as is the owner of the catalog). C<$schema> is validated (C<\w+>) and used as the database
qualifier, C<"$schema":informix.systables>.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::Informix::Introspect::Tables->fetch($dbh, $schema);

Returns a hashref keyed by table name. Each value is a hashref with
keys: C<table_name>, C<kind> (C<table> or C<view>), C<owner>, and for a
view its C<definition> (the C<CREATE VIEW> statement of the server, blanks
collapsed).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
