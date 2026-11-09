use strict;
use warnings;
use Test::More;

# LIVE test for the karr k22 WP2 / core k70 '?' seam contract, end to end: the
# transport's query seam is fed SQL in the sql_maker '?' dialect and must shape
# it to PostgreSQL '$N' INTERNALLY (DBIO::PostgreSQL::EV::Storage::_transform_sql)
# before it reaches libpq -- and SQL already in '$N' form must pass through
# unchanged. Offline coverage of the shaping itself is in t/03 and
# t/06-thin-transport-structure.t; this proves the rows actually come back
# correct against a real server.
#
# Dogfoods DBIO::PostgreSQL::EV::TestHarness.

use DBIO::PostgreSQL::EV::TestHarness;

BEGIN { DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live }

# A server that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

my $h = DBIO::PostgreSQL::EV::TestHarness->new;
my $async = $h->async;

# --- '?' dialect fed to _query_async resolves correct rows -------------------
{
  my @rows = $h->await(
    $async->_query_async('SELECT ?::int AS n, ?::text AS s', [ 42, 'hi' ])
  );
  is scalar(@rows), 1, 'single row returned for a ? query';
  is $rows[0][0], 42,   'first ? bound and returned correctly ($1)';
  is $rows[0][1], 'hi', 'second ? bound and returned correctly ($2)';
}

# --- multiple '?' numbered left-to-right across the statement ----------------
{
  my @rows = $h->await(
    $async->_query_async('SELECT ?::int AS a, ?::int AS b, ?::int AS c', [ 10, 20, 30 ])
  );
  is_deeply $rows[0], [ 10, 20, 30 ],
    'three ? placeholders numbered $1,$2,$3 in order';
}

# --- '$N' passthrough stays intact (idempotent shaping) ----------------------
{
  my @rows = $h->await(
    $async->_query_async('SELECT $1::int AS n', [ 7 ])
  );
  is $rows[0][0], 7, 'SQL already in $N form passes through and resolves correctly';
}

# --- the jsonpath operator, written '@\?', while a real ? beside it is shaped --
# The operator is written '@\?': its '?' is no bind and reaches the server as
# '@?'. The '?' in the jsonpath literal is text, and the separate '?'
# placeholder is $1. The same statement over the dbh: the k120 section below.
{
  my @rows = $h->await(
    $async->_query_async(
      q{SELECT ('{"a":1}'::jsonb @\? '$.a ? (@ == 1)') AS matched, ?::int AS n},
      [ 5 ],
    )
  );
  ok $rows[0][0], 'the jsonb operator written @\? matched, neither its ? nor the literal one bound';
  is $rows[0][1], 5, 'the real ? beside it became a bound $1';
}

# --- karr k84: a statement the dbh runs, this transport runs with the same rows ---
#
# WHY: the dbh of this very schema hands literal SQL to DBD::Pg, which numbers a
# '?' only where PostgreSQL reads SQL -- not in a dollar-quoted body, not in a
# comment, not behind the backslashed quote of an E'' string. The transport has
# to read the statement the same way: numbering one of those leaves it with a
# $N nobody bound ("could not determine data type of parameter $1") or with a
# changed literal. Each statement goes over the dbh first -- that it runs there
# is the premise -- and then through the transport's query seam.
{
  my $dbh = $h->sync_storage->dbh;

  my $over_ev = sub {
    my ($sql, @bind) = @_;
    my $rows = eval { [ $h->await($async->_query_async($sql, [@bind])) ] };
    diag $@ unless $rows;
    return $rows;
  };

  for my $case (
    [ 'a tagged dollar-quoted body',
      q{SELECT $body$ what? $body$::text AS s, ?::int AS n}, [[ ' what? ', 7 ]] ],
    [ 'a $$ body',
      q{SELECT $$ what? $$::text AS s, length($$?$$) AS l, ?::int AS n}, [[ ' what? ', 1, 7 ]] ],
    [ 'a -- comment',
      "SELECT 1 AS a -- really?\n , ?::int AS n", [[ 1, 7 ]] ],
    [ 'a /* */ comment',
      q{SELECT /* why? */ ?::int AS n}, [[ 7 ]] ],
    [ q{an E'' string with a backslashed quote},
      q{SELECT E'it\'s ?' AS s, ?::int AS n}, [[ q{it's ?}, 7 ]] ],
    [ 'all of them in one statement',
      "SELECT \$q\$ a? \$q\$::text AS s, /* b? */ E'c\\'?' AS e, ?::int AS n -- d?\n , ?::text AS t",
      [[ ' a? ', q{c'?}, 7, 'seven' ]], [ 7, 'seven' ] ],
  ) {
    my ($name, $sql, $want, $bind) = @$case;
    $bind //= [ 7 ];

    my $sync = eval { $dbh->selectall_arrayref($sql, undef, @$bind) };
    diag $@ unless $sync;
    is_deeply $sync, $want, "k84 $name: runs over the dbh";
    is_deeply $over_ev->($sql, @$bind), $sync,
      "k84 $name: the same rows over the ev transport";
  }

  # --- karr k84 (c): a ? behind an @ that ends another operator ----------------
  #
  # A '?' behind an '@' is a placeholder like every other (dbio-postgresql
  # k120): DBD::Pg numbers it at the dbh, the transport numbers it the same
  # way, and the server reads '<@$1' as '<@' and a parameter. Compared over the
  # dbh and over the transport.
  for my $case (
    [ q{<@? is '<@' and a placeholder},
      q{SELECT (ARRAY[1] <@?::int[]) AS c}, [[ 1 ]], [ '{1,2}' ] ],
    [ q{<@? is '<@' and a placeholder, not contained},
      q{SELECT (ARRAY[3] <@?::int[]) AS c}, [[ 0 ]], [ '{1,2}' ] ],
    [ q{@@? is '@@' and a placeholder},
      q{SELECT ('a b'::tsvector @@?::tsquery) AS c}, [[ 1 ]], [ 'a' ] ],
  ) {
    my ($name, $sql, $want, $bind) = @$case;
    my $sync = eval { $dbh->selectall_arrayref($sql, undef, @$bind) };
    diag $@ unless $sync;
    # a boolean comes back 't'/'f' or 1/0 depending on the DBD::Pg; compare as bool
    my $norm = sub { [ map { [ map { /^(?:t|true)$/ ? 1 : /^(?:f|false)$/ ? 0 : $_ } @$_ ] } @{ $_[0] // [] } ] };
    my $got_ev = $over_ev->($sql, @$bind);
    is_deeply $norm->($sync), $norm->($want), "k84 $name: over the dbh";
    is_deeply $norm->($got_ev), $norm->($sync), "k84 $name: the same over the ev transport";
  }

  # --- dbio-postgresql k120: the bare @? is read alike over both ways ----------
  #
  # Written bare, the '?' of '@?' is a placeholder at the dbh and over the
  # transport: the statement has one parameter more than it has binds and runs
  # over neither. It does not run with the bind in the operator's place. What
  # each side says about it is its own text and is not held; that neither runs
  # it, and that both run the next statement, is.
  for my $case (
    [ q{a bound path},
      q{SELECT ('{"a":1}'::jsonb @? ?::jsonpath) AS c}, [ '$.a' ] ],
    [ q{a literal path, a bind beside it},
      q{SELECT ('{"a":1}'::jsonb @? '$.a') AS c, ?::int AS n}, [ 7 ] ],
  ) {
    my ($name, $sql, $bind) = @$case;
    my $sync = eval { $dbh->selectall_arrayref($sql, undef, @$bind) };
    ok !$sync, "k120 a bare @? with $name: does not run over the dbh";
    my $rows = eval { [ $h->await($async->_query_async($sql, [@$bind])) ] };
    ok !$rows, "k120 a bare @? with $name: nor over the ev transport";

    is_deeply scalar eval { $dbh->selectall_arrayref('SELECT ?::int AS n', undef, 7) }, [[ 7 ]],
      "k120 a bare @? with $name: the next statement runs over the dbh";
    is_deeply $over_ev->('SELECT ?::int AS n', 7), [[ 7 ]],
      "k120 a bare @? with $name: ... and over the ev transport";
  }

  # --- karr k84 / dbio-postgresql k120: \? is a literal question mark ----------
  #
  # DBD::Pg (3.7.1 or later, dbio-postgresql's cpanfile) takes "\?" outside a
  # string as a '?' that is no placeholder and sends it without the backslash;
  # the transport has no DBD::Pg, so its numbering drops the backslash. The
  # operators '?' and '@?' are written this way and run over the dbh and over
  # the transport with the same rows: the dbh's answer is the measure, and both
  # answers of the jsonpath operator are held, so a numbering that swallowed or
  # added a $N fails.
  for my $case (
    [ q{the jsonb key operator \?, a bind beside it},
      q{SELECT ('{"a":1}'::jsonb \? 'a') AS c, ?::int AS n}, [[ 1, 7 ]], [ 7 ] ],
    [ q{the jsonb key operator \? on a missing key},
      q{SELECT ('{"a":1}'::jsonb \? 'b') AS c, ?::int AS n}, [[ 0, 7 ]], [ 7 ] ],
    [ q{the jsonb any-key operator \?| over bound keys, one matching},
      q{SELECT ('{"a":1}'::jsonb \?| ARRAY[?, ?]) AS c}, [[ 1 ]], [ 'x', 'a' ] ],
    [ q{the jsonb any-key operator \?| over bound keys, none matching, a bind beside it},
      q{SELECT ('{"a":1}'::jsonb \?| ARRAY[?, ?]) AS c, ?::int AS n}, [[ 0, 7 ]], [ 'x', 'y', 7 ] ],
    [ q{the jsonb all-keys operator \?& over bound keys, all present},
      q{SELECT ('{"a":1,"b":2}'::jsonb \?& ARRAY[?, ?]) AS c}, [[ 1 ]], [ 'a', 'b' ] ],
    [ q{the jsonb all-keys operator \?& over bound keys, one missing, a bind beside it},
      q{SELECT ('{"a":1}'::jsonb \?& ARRAY[?, ?]) AS c, ?::int AS n}, [[ 0, 7 ]], [ 'a', 'b', 7 ] ],
    [ q{the jsonb key operator \? over a bound key, a bind beside it},
      q{SELECT ('{"a":1}'::jsonb \? ?) AS c, ?::int AS n}, [[ 1, 7 ]], [ 'a', 7 ] ],
    [ q{the operator @\? and a bound path that matches},
      q{SELECT ('{"a":1}'::jsonb @\? ?::jsonpath) AS c}, [[ 1 ]], [ '$.a' ] ],
    [ q{the operator @\? and a bound path that does not},
      q{SELECT ('{"a":1}'::jsonb @\? ?::jsonpath) AS c}, [[ 0 ]], [ '$.b' ] ],
    [ q{the operator @\? and a literal path, a bind beside it},
      q{SELECT ('{"a":1}'::jsonb @\? '$.a') AS c, ?::int AS n}, [[ 1, 7 ]], [ 7 ] ],
    [ q{the operator @\? and a literal path with a ? of its own, a bind beside it},
      q{SELECT ('{"a":1}'::jsonb @\? '$.a ? (@ == 1)') AS c, ?::int AS n}, [[ 1, 5 ]], [ 5 ] ],
    [ q{\? in a string stays as it is, a bind beside it},
      q{SELECT '\?'::text AS s, ?::int AS n}, [[ '\?', 7 ]], [ 7 ] ],
  ) {
    my ($name, $sql, $want, $bind) = @$case;
    my $norm = sub { [ map { [ map { /^(?:t|true)$/ ? 1 : /^(?:f|false)$/ ? 0 : $_ } @$_ ] } @{ $_[0] // [] } ] };
    my $sync = eval { $dbh->selectall_arrayref($sql, undef, @$bind) };
    diag $@ unless $sync;
    is_deeply $norm->($sync), $norm->($want), "k120 $name: over the dbh";
    is_deeply $norm->($over_ev->($sql, @$bind)), $norm->($sync),
      "k120 $name: the same over the ev transport";
  }

  # A statement that mixes $N and ? is refused, as DBD::Pg refuses it, before
  # anything is sent -- never run with one value in two places.
  {
    my $f = eval { $async->_query_async('SELECT $1::int, ?::int', [ 1, 2 ]) };
    ok !$f && $@ =~ /mixes \$N and \?/,
      'k120 a statement that mixes $N and ? is refused by the transport';
    ok !eval { $dbh->selectall_arrayref('SELECT $1::int, ?::int', undef, 1, 2); 1 },
      'k120 ... as the dbh refuses it';
  }

  # No bind at all (karr k88, the cases of dbio-postgresql's
  # t/104-number-placeholders-live.t): every $N the numbering adds is one too
  # many, and the server refuses the statement for it.
  for my $case (
    [ 'a -- comment and no bind',
      "SELECT 1 AS a -- really?\n", [[ 1 ]] ],
    [ 'a /* */ comment and no bind',
      q{SELECT /* why? and how? */ 2 AS a}, [[ 2 ]] ],
    [ 'a dollar-quoted body and no bind',
      q{SELECT $fn$ SELECT 1 WHERE 'a' ? 'b' $fn$::text AS body}, [[ q{ SELECT 1 WHERE 'a' ? 'b' } ]] ],
  ) {
    my ($name, $sql, $want) = @$case;
    my $sync = eval { $dbh->selectall_arrayref($sql) };
    diag $@ unless $sync;
    is_deeply $sync, $want, "k88 $name: runs over the dbh";
    is_deeply $over_ev->($sql), $sync,
      "k88 $name: the same rows over the ev transport";
  }

  # Where the server reads further than DBD::Pg 3.20.2 does, the server is the
  # measure: /* */ nests, a lowercase e opens an escape string, a carriage
  # return ends a -- comment, and an E'' string continued on the next line
  # stays an escape string. The dbh is not asked here -- what it does with
  # these is DBD::Pg's reading, and not one to hold.
  for my $case (
    [ 'a nested /* */ comment',
      q{SELECT /* a /* in? */ out? */ ?::int AS n}, [[ 7 ]] ],
    [ q{a lowercase e'' string},
      q{SELECT e'it\'s ?' AS s, ?::int AS n}, [[ q{it's ?}, 7 ]] ],
    [ 'a -- comment ended by a carriage return',
      "SELECT 1 AS a -- really?\r , ?::int AS n", [[ 1, 7 ]] ],
    [ q{an E'' string continued on the next line},
      "SELECT E'a'\n  'b\\'c ?' AS s, ?::int AS n", [[ q{ab'c ?}, 7 ]] ],
  ) {
    my ($name, $sql, $want) = @$case;
    is_deeply $over_ev->($sql, 7), $want,
      "k84 $name: read as the server reads it";
  }
}

$h->disconnect;

done_testing;
