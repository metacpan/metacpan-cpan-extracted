use strict;
use warnings;

BEGIN { $DBD::Oracle::VERSION = 1.80 }

use Test::More;

use DBIO::Oracle::Introspect::Tables;
use DBIO::Oracle::Introspect::Indexes;
use DBIO::Oracle::Introspect::ForeignKeys;
use DBIO::Oracle::Introspect::Keys;
use DBIO::Oracle::Introspect::Views;

# What the introspection returns is in the same order in every session
# language. A plain ORDER BY on a name sorts by the NLS_SORT of the session --
# under GERMAN a_x, aB and Ab come in another order than under BINARY, and
# the foreign keys of a table, the views a view rests on, listed in that
# order, change with the language the client was started in. So every name in
# an ORDER BY of the introspection is sorted by NLSSORT(name, 'NLS_SORT=BINARY'),
# whatever the session says; a position (column_position, position,
# column_id) is a number and is left as it is. The session itself keeps its
# own NLS_SORT: nothing here changes it.
#
# This file pins the text of every ORDER BY the readers send; the live half,
# with names GERMAN sorts differently, is t/104-introspect-order-live.t.

my @sql;
{
  package Spy::Dbh;
  sub new { bless {}, shift }
  sub func { [ 19, 0 ] }
  sub prepare        { push @sql, $_[1]; Spy::Sth->new }
  sub prepare_cached { push @sql, $_[1]; Spy::Sth->new }

  package Spy::Sth;
  sub new { bless {}, shift }
  sub execute {}
  sub fetchrow_hashref {}
  sub fetchrow_array {}
  sub finish {}
}

my $dbh = Spy::Dbh->new;
my %tables = ( T => { table_name => 'T', kind => 'view', schema => 'S' } );

my %run = (
  Tables      => sub { DBIO::Oracle::Introspect::Tables->fetch($dbh, 'S') },
  Indexes     => sub { DBIO::Oracle::Introspect::Indexes->fetch($dbh, 'S', \%tables) },
  Keys        => sub { DBIO::Oracle::Introspect::Keys->fetch($dbh, 'S', \%tables) },
  ForeignKeys => sub { DBIO::Oracle::Introspect::ForeignKeys->fetch($dbh, 'S', \%tables) },
  Views       => sub { DBIO::Oracle::Introspect::Views->fetch($dbh, 'S', \%tables) },
);

my $POSITION = qr/^(?:\w+\.)?(?:column_position|position|column_id)$/i;
my $BINARY   = qr/^NLSSORT\(\s*[\w.]+\s*,\s*'NLS_SORT=BINARY'\s*\)$/i;

for my $name (sort keys %run) {
  @sql = ();
  $run{$name}->();
  ok scalar(@sql), "$name sends a query";

  for my $sql (@sql) {
    my ($clause) = $sql =~ /ORDER\s+BY\s+(.*?)\s*\z/s or next;
    my @items = split /,(?![^()]*\))/, $clause;
    s/^\s+|\s+$//g for @items;
    my @names = grep { $_ !~ $POSITION } @items;
    ok scalar(@names), "$name: ORDER BY $clause sorts by a name";
    my @bad = grep { $_ !~ $BINARY && $_ ne 'c.constraint_type' } @names;
    is_deeply \@bad, [],
      "$name: every name in ORDER BY is sorted binary, not by the NLS_SORT of the session";
  }
}

done_testing;
