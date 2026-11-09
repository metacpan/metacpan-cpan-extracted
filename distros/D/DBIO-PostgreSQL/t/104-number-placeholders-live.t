use strict;
use warnings;
use Test::More;

# LIVE test for the '?' contract of the future_io transport (karr k120, from
# dbio-postgresql-ev k84): the query seam is fed SQL in the sql_maker '?'
# dialect and numbers it to PostgreSQL '$N' INTERNALLY
# (DBIO::PostgreSQL::Storage::Async::_transform_sql, which answers through
# DBIO::PostgreSQL::Util::number_placeholders) before it reaches DBD::Pg. The
# numbering itself is held offline in t/104-number-placeholders.t; this proves
# the statements run and the rows come back against a real server.
#
# WHY IT MATTERS: the dbh of the very same schema hands literal SQL to DBD::Pg,
# which numbers a '?' only where PostgreSQL reads SQL -- not in a dollar-quoted
# body, not in a comment, not behind the backslashed quote of an E'' string.
# The transport has to read the statement the same way: numbering one of those
# leaves it with a $N nobody bound, with a changed literal, or with a $1 inside
# a comment that DBD::Pg refuses the statement over. A layer sends exactly such
# text through this seam (a dollar-quoted cypher body, dbio-postgresql-age).
#
# Needs no table and creates nothing.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

# A Future::IO event-loop implementation is required to drive the non-blocking
# socket watcher. IO::Async is the recommended one (as dbio-async uses).
BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io roundtrip';
}

use DBD::Pg;
use DBIO::Test;

# DBIO::Test::Schema keeps no driver in its class: this file runs it on
# PostgreSQL (core ADR 0067).
DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async, which
# is only a recommends. A runtime require (after the DB gate above), so a no-DB
# run still skips with the DSN message first.
eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

# A server that is not there fails the file, with a plan (karr k113).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

my $schema = DBIO::Test::Schema->connect($dsn, $user, $pass, { async => 'future_io' });
my $async  = $schema->storage->async;
isa_ok $async, 'DBIO::PostgreSQL::Storage::Async', 'the future_io transport';

# The rows of a statement sent through the transport's query seam, or undef and
# a diag with the error.
my $over_future_io = sub {
  my ($sql, @bind) = @_;
  my $rows = eval { [ $async->_query_async($sql, [@bind])->get ] };
  diag $@ unless $rows;
  return $rows;
};

# --- the '?' dialect fed to _query_async resolves the right rows --------------
is_deeply $over_future_io->('SELECT ?::int AS n, ?::text AS s', 42, 'hi'), [[ 42, 'hi' ]],
  'two ? bound and returned as $1 and $2';
is_deeply $over_future_io->('SELECT ?::int AS a, ?::int AS b, ?::int AS c', 10, 20, 30),
  [[ 10, 20, 30 ]], 'three ? numbered $1, $2, $3 in order';
is_deeply $over_future_io->('SELECT $1::int AS n', 7), [[ 7 ]],
  'SQL already in $N form passes through';

# The jsonpath operator is written '@\?': its ? is no bind, and neither is the
# one in the jsonpath literal; the separate ? beside them is $1. The statement
# is the same text for the dbh, where DBD::Pg reads \? as a literal question
# mark, and the rows are the same.
{
  my $sql  = q{SELECT ('{"a":1}'::jsonb @\? '$.a ? (@ == 1)')::int AS matched, ?::int AS n};
  my $sync = eval { $schema->storage->dbh->selectall_arrayref($sql, undef, 5) };
  diag $@ unless $sync;
  is_deeply $sync, [[ 1, 5 ]],
    'the jsonb operator written @\? matches over the dbh, the real ? beside it is bound';
  is_deeply $over_future_io->($sql, 5), $sync,
    '... and gives the same rows over the future_io transport';
}

# Written bare, the ? of '@?' is a placeholder over both ways: the statement
# has two parameters and is refused with one bind, at the dbh and here. It does
# not run with the bind in the operator's place.
{
  my $sql = q{SELECT ('{"a":1}'::jsonb @? '$.a')::int AS matched, ?::int AS n};
  my $sync = eval { $schema->storage->dbh->selectall_arrayref($sql, undef, 5) };
  ok !$sync, 'a bare @? beside one bind: refused at the dbh';
  my $rows = eval { [ $async->_query_async($sql, [ 5 ])->get ] };
  my $err  = $@;
  ok !$rows, '... and over the future_io transport';
  like $err, qr/called with \d+ bind variables when \d+ are needed|syntax error/,
    '... as a statement with one parameter more than it has binds';

  is_deeply $over_future_io->('SELECT ?::int AS n', 7), [[ 7 ]],
    '... and the next statement runs';
}

# --- a statement the dbh runs, this transport runs with the same rows ---------
#
# Each statement goes over the dbh first -- that it runs there is the premise
# -- and then through the transport's query seam.
{
  my $dbh = $schema->storage->dbh;

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
    # No bind at all: every $N the numbering adds is one too many.
    [ 'a -- comment and no bind',
      "SELECT 1 AS a -- really?\n", [[ 1 ]], [] ],
    [ 'a /* */ comment and no bind',
      q{SELECT /* why? and how? */ 2 AS a}, [[ 2 ]], [] ],
    [ 'a dollar-quoted body and no bind',
      q{SELECT $fn$ SELECT 1 WHERE 'a' ? 'b' $fn$::text AS body}, [[ q{ SELECT 1 WHERE 'a' ? 'b' } ]], [] ],
  ) {
    my ($name, $sql, $want, $bind) = @$case;
    $bind //= [ 7 ];

    my $sync = eval { $dbh->selectall_arrayref($sql, undef, @$bind) };
    diag $@ unless $sync;
    is_deeply $sync, $want, "$name: runs over the dbh";
    is_deeply $over_future_io->($sql, @$bind), $sync,
      "$name: the same rows over the future_io transport";
  }
}

# --- where DBD::Pg reads less than the server ---------------------------------
#
# This transport does not hand the numbered statement to the server itself:
# DBD::Pg reads it once more, looking for $N (pg_placeholder_dollaronly), by a
# scanner of its own. Measured with DBD::Pg 3.20.2: it does not nest /* */, a
# lowercase e opens no escape string for it, nor does the continuation of an
# E'' string on the next line, and a carriage return does not end its --
# comment. The numbering holds the server's reading all the same (offline, in
# t/104-number-placeholders.t), and what DBD::Pg makes of the difference is
# one of two things, and nothing else:
#   * it still finds every $N, and the statement runs with the server's rows;
#   * a $N is hidden from it, and it refuses the statement before it is sent.
# It passes a $N on as it finds it, so there is no third outcome in which the
# statement runs with other binds. The dbh is not asked here: it refuses or
# misreads these statements itself.
{
  my $REFUSED = qr/called with \d+ bind variables when \d+ are needed|Invalid placeholders/;

  # The nesting does not get in DBD::Pg's way as long as what follows the first
  # '*/' holds nothing it reads as a quote or a $N.
  is_deeply $over_future_io->(q{SELECT /* a /* in? */ out? */ ?::int AS n}, 7), [[ 7 ]],
    'a nested /* */ comment: read as the server reads it';

  for my $case (
    [ q{a lowercase e'' string},
      q{SELECT e'it\'s ?' AS s, ?::int AS n}, [[ q{it's ?}, 7 ]] ],
    [ 'a -- comment ended by a carriage return',
      "SELECT 1 AS a -- really?\r , ?::int AS n", [[ 1, 7 ]] ],
    [ q{an E'' string continued on the next line},
      "SELECT E'a'\n  'b\\'c ?' AS s, ?::int AS n", [[ q{ab'c ?}, 7 ]] ],
    [ 'a nested /* */ comment with a quote behind its inner end',
      q{SELECT /* a /* b */ it's */ ?::int AS n}, [[ 7 ]] ],
  ) {
    my ($name, $sql, $want) = @$case;
    my $rows = eval { [ $async->_query_async($sql, [ 7 ])->get ] };
    my $err  = $@;
    if ($rows) {
      is_deeply $rows, $want, "$name: read as the server reads it";
    }
    else {
      like $err, $REFUSED,
        "$name: refused by DBD::Pg $DBD::Pg::VERSION before it is sent, not run with other binds";
    }
  }

  # The connection is none the worse for a refusal.
  is_deeply $over_future_io->('SELECT ?::int AS n', 7), [[ 7 ]],
    '... and the next statement runs';
}

# --- a ? directly behind an @ that ends another operator ----------------------
#
# A '?' behind an '@' is a placeholder like every other (karr k120): the dbh
# numbers it, the server reads '<@$1' as '<@' and a parameter, and the
# transport has to give the same rows.
{
  my $dbh = $schema->storage->dbh;

  for my $case (
    [ 'a ? glued to <@',
      q{SELECT ARRAY[1] <@?::int[] AS sub}, [[ 1 ]], '{1,2}' ],
    [ 'a ? glued to @@',
      q{SELECT ('{"a":1}'::jsonb @@?::jsonpath) AS m}, [[ 1 ]], '$.a == 1' ],
  ) {
    my ($name, $sql, $want, $bind) = @$case;

    my $sync = eval { $dbh->selectall_arrayref($sql, undef, $bind) };
    diag $@ unless $sync;
    is_deeply $sync, $want, "$name: runs over the dbh";
    is_deeply $over_future_io->($sql, $bind), $sync,
      "$name: the same rows over the future_io transport";
  }
}

$async->disconnect;

done_testing;
