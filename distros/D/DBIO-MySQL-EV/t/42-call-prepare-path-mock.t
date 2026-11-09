use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Future; 1 } or plan skip_all => 'Future not installed';
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
}

use DBIO::MySQL::EV::QueryExecutor;

# karr k84: a CALL without bind values must not go through EV::MariaDB's
# query(), which calls back with the first result set and reads the rest of the
# answer only after the callback -- a statement with bind values that follows
# on the connection is then refused. It goes prepare -> execute -> close_stmt,
# like a statement with bind values. Everything else without binds stays a
# plain query. The result the caller gets is the same on both paths.

{
  package RecMDB;
  sub new { bless { ops => [] }, shift }
  sub ops { join ' ', @{ $_[0]{ops} } }
  sub query {
    my ($s, $sql, $cb) = @_;
    push @{ $s->{ops} }, 'query';
    $cb->([ [ 1 ] ]);
  }
  sub prepare {
    my ($s, $sql, $cb) = @_;
    push @{ $s->{ops} }, 'prepare';
    $cb->(7);
  }
  sub execute {
    my ($s, $stmt, $bind, $cb) = @_;
    push @{ $s->{ops} }, 'execute';
    $cb->([ [ 42 ] ]);
  }
  sub close_stmt {
    my ($s, $stmt, $cb) = @_;
    push @{ $s->{ops} }, 'close_stmt';
    $cb->(1);
  }
}

my $ex = DBIO::MySQL::EV::QueryExecutor->new;

my @calls = (
  'CALL p(7)',
  'call p(7)',
  "  \n\tCALL p(7)",
  "-- note\nCALL p(7)",
  "# note\nCALL p(7)",
  "/* note */ CALL p(7)",
  "/* a */ -- b\n  Call `p`()",
);
for my $sql (@calls) {
  (my $name = $sql) =~ s/\s+/ /g;
  my $mdb = RecMDB->new;
  my $f = $ex->execute($mdb, $sql, []);
  EV::run(EV::RUN_NOWAIT());   # the fake answers inside dispatch; the Future settles from the idle watcher (karr k51)
  is $mdb->ops, 'prepare execute close_stmt', "'$name' is prepared, executed, closed";
  ok $f->is_done, '... and answered';
  is_deeply [ $f->get ], [ [ 42 ] ], '... with the rows the execute returned';
}

for my $sql ('SELECT 1', 'CALLER()', 'SELECT 1 /* CALL p() */', "-- CALL p()\nSELECT 1", 'SET @a = 1; CALL p()', 'INSERT INTO t VALUES (1)') {
  (my $name = $sql) =~ s/\s+/ /g;
  my $mdb = RecMDB->new;
  my $f = $ex->execute($mdb, $sql, []);
  EV::run(EV::RUN_NOWAIT());   # the fake answers inside dispatch; the Future settles from the idle watcher (karr k51)
  is $mdb->ops, 'query', "'$name' without binds stays a plain query";
  is_deeply [ $f->get ], [ [ 1 ] ], '... same result shape';
}

{
  my $mdb = RecMDB->new;
  $ex->execute($mdb, 'CALL p(?)', [ 7 ]);
  is $mdb->ops, 'prepare execute close_stmt', 'a CALL with binds is unchanged';
}

done_testing;
