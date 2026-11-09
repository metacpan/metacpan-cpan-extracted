use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::SQLMaker;

# The core half of the upsert conditional conflict branch
# (ADR 0036 section 1).
#
# { -attempted => $col } is core's engine-neutral marker for "the value this
# statement tried to insert". In the update SET list it is only ever a
# top-level value; in the condition of the DO UPDATE branch it may sit at ANY
# depth. Both drivers that render the condition (dbio-postgresql, dbio-sqlite)
# had to substitute it before _recurse_where saw it, and solved it twice:
# _upsert_condition_sql is that mechanism lifted into core, parameterized over
# the one engine-specific piece, _upsert_attempted_sql.
#
# The substitution rides SQL::Abstract's own expansion pass rather than a
# hand-written walk -- that pass already visits every node, which is what makes
# "at any depth" true by construction instead of by enumeration. The tests
# below therefore exist to pin the *consequences* of that choice, because the
# alternative (a walk) fails exactly where enumeration was incomplete.
#
# MOCK ONLY -- no DB, no DSN. Rendering only.
#
# Comparisons are raw strings on purpose. is_same_sql normalizes parentheses
# and reorders AND/OR operands, and the central regression here (bare
# right-hand-side position, below) is a MISSING '=' -- a difference a
# normalizing comparator can swallow.

# Core has no default for the engine token, so a test needs a stand-in driver
# SQLMaker. This one spells it the way SQLite does; PostgreSQL's EXCLUDED and
# MySQL's VALUES(col) / new.col differ only in this one string.
{
  package DBIO::Test::SQLMaker::Attempted;
  use base 'DBIO::SQLMaker';

  sub _upsert_attempted_sql { 'excluded.' . $_[0]->_quote($_[1]) }
}

my $sm = DBIO::Test::SQLMaker::Attempted->new(quote_char => '"', name_sep => '.');

# --- the two vocabularies -------------------------------------------------

# The canonical last-write-wins guard. An unqualified column is the STORED row
# (the row the statement collided with); the marker is the ATTEMPTED value.
# Both sides of the comparison in one condition is the whole point of the
# feature: without it the caller must choose between overwriting newer data and
# giving up atomicity.
#
# NOTE (karr k205): a bare stored column renders unqualified only when NO target
# table is given -- the calls in this section pass none. In a real ON CONFLICT
# DO UPDATE the stored row shares scope with the EXCLUDED pseudo-row, so a bare
# column is ambiguous and the driver passes the target table so it is qualified.
# That path is pinned in "k205: stored side qualified with the target table"
# below; this section pins the no-table (back-compat) rendering.
{
  my ($sql, @bind) = $sm->_upsert_condition_sql(
    { updated_at => { '<' => { -attempted => 'updated_at' } } }
  );

  is $sql, '"updated_at" < excluded."updated_at"',
    'stored column on the left, attempted value on the right';
  is_deeply \@bind, [], 'the marker contributes no bind value';
}

# THE regression this file exists for. { rank => { -attempted => 'rank' } } is
# the caller saying "equal to the attempted value". A raw literal in the bare
# right-hand-side position renders as OPERATOR-plus-operand -- SQL::Abstract
# reads a literal on the right of a column as the operator itself -- which
# would silently produce '"rank" excluded."rank"'. make_unop_expander turns
# that position into a comparison before the node is rendered, which is what
# makes -literal correct in every position and an -ident detour unnecessary.
# If this ever breaks, this is the test that must fail.
{
  my ($sql, @bind) = $sm->_upsert_condition_sql({ rank => { -attempted => 'rank' } });

  is $sql, '"rank" = excluded."rank"',
    'bare right-hand-side marker renders as an equality comparison';
  unlike $sql, qr/"rank"\s+excluded/,
    'and NOT as the operator-shaped "rank" excluded."rank"';
  is_deeply \@bind, [], 'still no bind from the marker';
}

# --- depth: what riding the expansion pass buys ---------------------------

# Nested -and/-or. A hand-written walk has to recurse into both itself; the
# expander is simply called wherever the pass arrives.
{
  my ($sql) = $sm->_upsert_condition_sql({
    -and => [
      { updated_at => { '<' => { -attempted => 'updated_at' } } },
      { -or => [
        { rank => { '>'  => { -attempted => 'rank' } } },
        { name => { '!=' => { -attempted => 'name' } } },
      ] },
    ],
  });

  is $sql,
    '( "updated_at" < excluded."updated_at" AND ( "rank" > excluded."rank" OR "name" != excluded."name" ) )',
    'substituted inside nested -and/-or';
}

# Inside an -in list, mixed with ordinary bound values.
{
  my ($sql, @bind) = $sm->_upsert_condition_sql(
    { rank => { -in => [ 1, { -attempted => 'rank' }, 3 ] } }
  );

  is $sql, '"rank" IN ( ?, excluded."rank", ? )',
    'substituted inside an -in list';
  is_deeply \@bind, [ 1, 3 ],
    'the surrounding list values still bind, in list order, and the marker adds none';
}

# Inside -between, which takes a pair and is a different node shape again.
{
  my ($sql, @bind) = $sm->_upsert_condition_sql(
    { rank => { -between => [ { -attempted => 'rank' }, 100 ] } }
  );

  is $sql, '( "rank" BETWEEN excluded."rank" AND ? )',
    'substituted inside -between';
  is_deeply \@bind, [ 100 ], 'the other end of the range still binds';
}

# As a function argument -- a position no enumeration of "operator RHS, -in,
# -between" would have covered.
{
  my ($sql) = $sm->_upsert_condition_sql(
    { updated_at => { '<' => { -coalesce => [ { -attempted => 'updated_at' }, \'0' ] } } }
  );

  is $sql, '"updated_at" < COALESCE(excluded."updated_at", 0)',
    'substituted inside a function argument';
}

# --- binds -----------------------------------------------------------------

# Bind values from the surrounding condition come out in statement order, and
# the marker interleaves without displacing them. Getting this wrong is the
# quiet failure mode of any substitution scheme: valid SQL, wrong values.
{
  my ($sql, @bind) = $sm->_upsert_condition_sql({
    -and => [
      { name       => 'foo' },
      { updated_at => { '<' => { -attempted => 'updated_at' } } },
      { rank       => { '>' => 3 } },
    ],
  });

  is $sql,
    '( "name" = ? AND "updated_at" < excluded."updated_at" AND "rank" > ? )',
    'markers and placeholders sit where the condition put them';
  is_deeply \@bind, [ 'foo', 3 ],
    'binds keep their order across the marker, which contributes none';
}

# --- literals pass through untouched ---------------------------------------

# A literal is engine SQL the caller wrote on purpose -- it is the escape hatch
# for conditions the abstract form cannot express, so nothing here may rewrite
# it.
{
  my ($sql, @bind) = $sm->_upsert_condition_sql(\'excluded.rank > artist.rank');
  is $sql, 'excluded.rank > artist.rank', 'a plain literal passes through verbatim';
  is_deeply \@bind, [], 'and carries no bind';
}

{
  my ($sql, @bind) = $sm->_upsert_condition_sql(\[ 'excluded.rank > ?', 5 ]);
  is $sql, 'excluded.rank > ?', 'a literal-with-bind passes through verbatim';
  is_deeply \@bind, [ 5 ], 'with its bind value';
}

{
  my ($sql, @bind) = $sm->_upsert_condition_sql({
    -and => [ { rank => { '>' => { -attempted => 'rank' } } }, \[ 'x > ?', 7 ] ],
  });

  is $sql, '( "rank" > excluded."rank" AND x > ? )',
    'a literal alongside a marker: only the marker is substituted';
  is_deeply \@bind, [ 7 ], 'the literal keeps its bind';
}

# --- the marker's payload rule, in one place -------------------------------

# The expander is the single door every -attempted comes through, however deep
# it sat, so the payload is validated once rather than at each depth a walk
# would have to check.
for my $bad (
  [ 'undef'    => undef ],
  [ 'literal'  => \'x' ],
  [ 'arrayref' => [ 'a' ] ],
  [ 'hashref'  => { a => 1 } ],
) {
  my ($label, $payload) = @$bad;

  throws_ok {
    $sm->_upsert_condition_sql({ rank => { -attempted => $payload } })
  } qr/takes a plain column name/,
    "{ -attempted => $label } is refused";
}

# --- the operator does not leak --------------------------------------------

# -attempted is registered with local() for the duration of the one call, not
# in the constructor: it means nothing in a SELECT, and an operator left
# registered would render a pseudo-row reference in statements that have no
# attempted row at all. This is what local() buys, so it is asserted rather
# than assumed.
{
  ok !exists $sm->{expand_op}{attempted},
    'the -attempted operator is gone once the call returns';

  my ($sql) = $sm->where({ rank => { -attempted => 'rank' } });
  unlike $sql, qr/excluded/i,
    'a plain where() renders no pseudo-row reference for the marker';
}

# ... including when the call left through the throw above, since a leak on the
# error path would be just as wrong and is easy to introduce with an eval.
{
  eval { $sm->_upsert_condition_sql({ rank => { -attempted => undef } }) };
  ok !exists $sm->{expand_op}{attempted},
    'the operator is gone after a throw, too';
}

# --- core itself has no engine token ---------------------------------------

# ADR 0036 pins the split: core stays abstract, the driver SQLMaker renders the
# token. So the base class throws rather than guessing one engine's spelling --
# a developer-facing guard for a driver that declared supports_upsert without
# spelling its token, not a user-reachable path (core never routes an
# on_conflict structure to a SQLMaker whose storage lacks the capability).
{
  my $plain = DBIO::SQLMaker->new(quote_char => '"', name_sep => '.');

  throws_ok { $plain->_upsert_attempted_sql('rank') }
    qr/does not implement _upsert_attempted_sql/,
    'the base SQLMaker has no attempted-row token and says so';

  throws_ok { $plain->_upsert_condition_sql({ rank => { -attempted => 'rank' } }) }
    qr/does not implement _upsert_attempted_sql/,
    'and a condition carrying the marker fails on the same missing hook';
}

# --- k205: stored side qualified with the target table --------------------
#
# The regression this section exists for (karr k205, reproduced live against
# PostgreSQL 2026-09-21). In an ON CONFLICT DO UPDATE branch two correlations
# are in scope at once: the target table and the attempted-values pseudo-row
# (EXCLUDED). A bare stored-side column reaches the engine unqualified, and with
# the same name carried by both sides PostgreSQL cannot resolve it:
#
#   ERROR: column reference "score" is ambiguous
#
# _upsert_condition_sql takes the target table as a second argument; given one,
# every bare (single-part) column is qualified with it while the EXCLUDED marker
# and any already-qualified column are left exactly as they were. This is the
# core half of the fix -- the driver's own conflict builder threads the target
# table through. Properties, not existence: the STORED side gains the table, the
# ATTEMPTED side does NOT, and both are asserted independently.
#
# Comparisons stay raw strings for the same reason the rest of this file does:
# is_same_sql would normalize away exactly the qualification difference at issue.

# THE live bug. Before the target-table argument was honoured this rendered
# '"score" < excluded."score"' -- the ambiguous form PostgreSQL rejects.
{
  my ($sql, @bind) = $sm->_upsert_condition_sql(
    { score => { '<' => { -attempted => 'score' } } },
    'dbio_upsert_test',
  );

  is $sql, '"dbio_upsert_test"."score" < excluded."score"',
    'stored column qualified with the target table, attempted value is not';

  like $sql, qr/"dbio_upsert_test"\."score"\s*</,
    'the STORED side carries the target-table qualification';
  unlike $sql, qr/"dbio_upsert_test"\."?excluded/i,
    'the ATTEMPTED (EXCLUDED) side is NOT qualified with the target table';
  is_deeply \@bind, [], 'the marker still contributes no bind value';
}

# The EXCLUDED half is byte-for-byte what it is with no table: only the stored
# side changed. Pin that by diffing the two renderings of the same condition.
{
  my $cond = sub { { score => { '<' => { -attempted => 'score' } } } };
  my ($plain) = $sm->_upsert_condition_sql($cond->());
  my ($qualified) = $sm->_upsert_condition_sql($cond->(), 'dbio_upsert_test');

  is $plain, '"score" < excluded."score"',
    'no target table: the pre-k205 unqualified rendering is unchanged';
  (my $requalified = $qualified) =~ s/"dbio_upsert_test"\.//;
  is $requalified, $plain,
    'stripping the target-table qualifier recovers the unqualified rendering '
  . 'exactly -- nothing else moved, EXCLUDED included';
}

# Depth: the qualification rides the expansion pass, so every stored column in a
# nested condition is qualified and every EXCLUDED marker is left alone.
{
  my ($sql) = $sm->_upsert_condition_sql({
    -and => [
      { updated_at => { '<' => { -attempted => 'updated_at' } } },
      { -or => [
        { rank => { '>'  => { -attempted => 'rank' } } },
        { name => { '!=' => 5 } },
      ] },
    ],
  }, 'artist');

  is $sql,
    '( "artist"."updated_at" < excluded."updated_at" AND ( "artist"."rank" > excluded."rank" OR "artist"."name" != ? ) )',
    'every stored column qualified at any depth; every EXCLUDED marker untouched';
}

# An already-qualified column is not re-qualified: it carries its own table part
# (more than one component), which the single-part test deliberately excludes.
{
  my ($sql) = $sm->_upsert_condition_sql(
    { 'me.score' => { '<' => { -attempted => 'score' } } },
    'dbio_upsert_test',
  );

  is $sql, '"me"."score" < excluded."score"',
    'a column that already names a correlation is left as written';
  unlike $sql, qr/dbio_upsert_test/,
    'and the target table is NOT prepended to it';
}

# A literal is engine SQL the caller wrote on purpose -- the target table must
# not touch it, exactly as the -attempted expander must not.
{
  my ($sql, @bind) = $sm->_upsert_condition_sql(
    \'excluded.rank > artist.rank', 'artist',
  );
  is $sql, 'excluded.rank > artist.rank',
    'a literal passes through verbatim even with a target table';
  is_deeply \@bind, [], 'and carries no bind';
}

# Binds keep their order across qualification and markers alike.
{
  my ($sql, @bind) = $sm->_upsert_condition_sql({
    -and => [
      { name       => 'foo' },
      { updated_at => { '<' => { -attempted => 'updated_at' } } },
      { rank       => { '>' => 3 } },
    ],
  }, 'artist');

  is $sql,
    '( "artist"."name" = ? AND "artist"."updated_at" < excluded."updated_at" AND "artist"."rank" > ? )',
    'stored columns qualified, marker untouched, placeholders in place';
  is_deeply \@bind, [ 'foo', 3 ],
    'binds keep their order across qualification and the marker';
}

# A schema-qualified target table splits into its own components, so the
# qualifier is a proper multi-part identifier, not one quoted lump.
{
  my ($sql) = $sm->_upsert_condition_sql(
    { score => { '<' => { -attempted => 'score' } } },
    'myschema.dbio_upsert_test',
  );

  is $sql, '"myschema"."dbio_upsert_test"."score" < excluded."score"',
    'a schema-qualified target table qualifies as separate identifier parts';
}

done_testing;
