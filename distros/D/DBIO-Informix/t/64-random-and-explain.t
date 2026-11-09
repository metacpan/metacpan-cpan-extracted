use strict;
use warnings;

use Test::More;

use DBIO::Optional::Dependencies ();
use DBIO::Test;
use DBIO::Test::Schema;
use DBIO::Storage::DBI;
use DBIO::Informix::Storage;

# karr k23 / core ADR 0011 and ADR 0040 -- two hooks Informix has no honest
# answer to. Both are refused with a message that says why, instead of
# inheriting core's spelling and failing in the server.
#
#   _random_function  -- core answers RANDOM(). Informix 15.0.1 has no random
#                        function at all: RANDOM(), RAND(), DBMS_RANDOM_RANDOM
#                        and the dbms_random package are all answered with
#                        SQL -674 "Routine can not be resolved" (measured, and
#                        re-measured by the live block below). There is no
#                        spelling to put in its place, so the hook refuses.
#   _explain_query    -- core issues "EXPLAIN <query>", which is SQL -201 on
#                        Informix. The engine's plan facility is SET EXPLAIN
#                        [ON [AVOID_EXECUTE]], and it writes the plan to the
#                        file sqexplain.out on the SERVER. The one place SQL
#                        can see a plan, sysmaster:syssqexplain, holds the
#                        statements executing right now (the explain of the
#                        query that reads it) and not the one run before, so
#                        there is no second statement to read a plan back
#                        with (ADR 0040 section 7: the engine answers
#                        somewhere this seam does not reach). The operation
#                        refuses, and does so before any statement is issued.

sub informix_schema {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::Informix::Storage');
  return $schema->connect(@_);
}

my $schema  = informix_schema('dbi:Informix:ixdb@ixserver');
my $storage = $schema->storage;

# --- _random_function --------------------------------------------------------

isnt (
  DBIO::Informix::Storage->can('_random_function'),
  DBIO::Storage::DBI->can('_random_function'),
  '_random_function is a real override of core\'s RANDOM(), by coderef identity',
);

{
  my $func = eval { $storage->_random_function };
  my $err  = $@;

  is ($func, undef, '_random_function names no function');
  like ($err, qr/Informix has no random-number function/,
    '... and says so rather than handing out core\'s RANDOM()');
  like ($err, qr/-674/, '... quoting what the server answers');
}

{
  my $rs  = eval { $schema->resultset('Artist')->rand(3) };
  my $err = $@;

  is ($rs, undef, '$rs->rand refuses at query-build time');
  like ($err, qr/no random-number function/,
    '... with this driver\'s message, not a -674 from the server');
}

# --- _explain_query ----------------------------------------------------------

ok !DBIO::Informix::Storage->can('_explain_sql'),
  'this driver carries no dead override of the removed _explain_sql';

isnt (
  DBIO::Informix::Storage->can('_explain_query'),
  DBIO::Storage::DBI->can('_explain_query'),
  '_explain_query is a real override of core\'s bare EXPLAIN, by coderef identity',
);

is (
  $storage->can('_explain_query'),
  DBIO::Informix::Storage->can('_explain_query'),
  '... and a never-connected storage resolves to it',
);

{
  my $mocked = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::Informix::Storage',
  );
  my $mock = $mocked->storage;
  $mock->reset_captured;

  my $plan = eval {
    $mocked->resultset('Artist')->search({ name => 'x' })->explain;
  };
  my $err = $@;

  is ($plan, undef, '$rs->explain refuses');
  like ($err, qr/Informix cannot return a query plan/, '... naming the engine');
  like ($err, qr/sqexplain\.out/,
    '... saying where Informix writes the plan instead');
  like ($err, qr/-201/, '... and what the inherited EXPLAIN would have drawn');
  my @captured = $mock->captured_queries;
  is (scalar @captured, 0,
    '... before any statement is issued: nothing reached the server, and '
  . 'in particular no EXPLAIN that the engine does not have');
}

ok (! $storage->connected, 'none of the above opened a connection');

# ------------------------------------------------------------------- live

SKIP: {
  my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run the live half', 4
    unless $dsn;

  skip 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix'), 4
    unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');

  my $dbh = informix_schema($dsn, $user, $pass)->storage->dbh;
  my $refused = sub { eval { $dbh->prepare($_[0]); 1 } ? '' : "$@" };

  # The facts the refusals quote. If a server ever grows a random function or
  # a plan statement, one of these goes red and the refusal is due for review.
  for my $f ('RANDOM()', 'RAND()', 'DBMS_RANDOM_RANDOM()') {
    like ($refused->("SELECT FIRST 1 $f FROM sysmaster:sysdual"), qr/-674/,
      "live: the server has no $f");
  }

  like ($refused->('EXPLAIN SELECT tabid FROM systables'), qr/-201/,
    'live: the server has no EXPLAIN statement');
}

done_testing;
