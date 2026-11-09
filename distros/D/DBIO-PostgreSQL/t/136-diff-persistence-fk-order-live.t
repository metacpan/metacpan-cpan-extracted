use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k121 (7): SET LOGGED / SET UNLOGGED in the order of the
# foreign keys.
#
# WHAT it claims: where a foreign key ties two tables whose persistence both
# change, the statements the diff writes run on a server -- the referencing
# table SET UNLOGGED first, the referenced one SET LOGGED first -- and the
# diff afterwards is empty. Where the two reference each other the server
# takes no order, and the diff is refused with A left as it was.
#
# The names are chosen so that the order of the names is the wrong one: the
# diff used to write them in it, and the server answered
#
#   could not change table "a_parent" to unlogged because it references
#   logged table "z_child"        (the server's wording; it is z_child that
#                                  holds the key, and it goes first)
#
# Database A is what there is, B what is wanted.

my ($dbh_a, $dbh_b) = map {
  my $h = LiveServer->control_dbh(
    login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
  $h->do('SET client_min_messages = warning');
  $h;
} qw( t136a t136b );

sub catalog {
  my ($dbh) = @_;
  my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
  delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
  return $model;
}

sub start_over {
  my ($sql_a, $sql_b) = @_;
  for my $dbh ($dbh_a, $dbh_b) {
    $dbh->do($_) for 'DROP SCHEMA public CASCADE', 'CREATE SCHEMA public';
  }
  $dbh_a->do($_) for @$sql_a;
  $dbh_b->do($_) for @$sql_b;
}

sub tables {
  my ($parent, $child, $persistence) = @_;
  my $word = $persistence eq 'u' ? 'UNLOGGED ' : '';
  return (
    "CREATE ${word}TABLE public.$parent (id integer PRIMARY KEY)",
    "CREATE ${word}TABLE public.$child (id integer PRIMARY KEY, parent_id integer REFERENCES public.$parent)",
  );
}

for my $case (
  [ 'to UNLOGGED', 'p', 'u', 'a_parent', 'z_child',
    [ 'ALTER TABLE public.z_child SET UNLOGGED;', 'ALTER TABLE public.a_parent SET UNLOGGED;' ] ],
  [ 'to LOGGED',   'u', 'p', 'z_parent', 'a_child',
    [ 'ALTER TABLE public.z_parent SET LOGGED;', 'ALTER TABLE public.a_child SET LOGGED;' ] ],
) {
  my ($label, $from, $to, $parent, $child, $expect) = @$case;
  start_over([ tables($parent, $child, $from) ], [ tables($parent, $child, $to) ]);

  my $diff = DBIO::PostgreSQL::Diff->new(source => catalog($dbh_a), target => catalog($dbh_b));
  my @whole = map { $_->as_sql } @{ $diff->operations };
  is_deeply(\@whole, $expect, "$label: the statements are in the order of the keys");

  ok(eval { $dbh_a->do($_) for @whole; 1 }, "$label: the server takes them") or diag $@;
  is_deeply(
    [ map { $_->as_sql } @{ DBIO::PostgreSQL::Diff->new(
        source => catalog($dbh_a), target => catalog($dbh_b))->operations } ],
    [], "$label: afterwards the diff is empty");
}

# A cycle of keys: refused, and A is left as it was.
for my $case ([ 'to UNLOGGED', 'p', 'u', 'UNLOGGED' ], [ 'to LOGGED', 'u', 'p', 'LOGGED' ]) {
  my ($label, $from, $to, $word) = @$case;
  my $make = sub {
    my $unlogged = $_[0] eq 'u' ? 'UNLOGGED ' : '';
    return (
      "CREATE ${unlogged}TABLE public.a (id integer PRIMARY KEY, b_id integer)",
      "CREATE ${unlogged}TABLE public.b (id integer PRIMARY KEY, a_id integer REFERENCES public.a)",
      'ALTER TABLE public.a ADD FOREIGN KEY (b_id) REFERENCES public.b',
    );
  };
  start_over([ $make->($from) ], [ $make->($to) ]);
  my $before = catalog($dbh_a);
  throws_ok {
    DBIO::PostgreSQL::Diff->new(source => $before, target => catalog($dbh_b))->operations
  } qr/\Arefusing to diff: public\.a, public\.b reference each other and are to be $word\b/m,
    "$label: a cycle of keys is refused";
  is_deeply(catalog($dbh_a), $before, "$label: nothing has changed");

  # What the refusal rests on: the server takes neither order.
  ok(!eval { $dbh_a->do("ALTER TABLE public.a SET $word"); 1 }, "$label: the server refuses a first");
  ok(!eval { $dbh_a->do("ALTER TABLE public.b SET $word"); 1 }, "$label: ... and b first");
}

$_->disconnect for $dbh_a, $dbh_b;

done_testing;
