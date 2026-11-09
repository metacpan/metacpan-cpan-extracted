use strict;
use warnings;

use Test::More;

use DBIO::SQLite::Test;
use DBIO::SQLite::Storage;
use DBIO::Storage::DBI;
use DBIO::Storage::Statistics;

# ADR 0040 replaced the string hook _explain_sql with _explain_query($sql,
# \@bind), which owns the WHOLE operation of obtaining a query plan and returns
# the plan as rows. This file is about why SQLite had to override it, and it is
# deliberately not written as a string comparison against
# "EXPLAIN QUERY PLAN ..." -- that would pin the fix without recording the
# defect, and the defect is the whole point.
#
# SQLite ACCEPTS a bare EXPLAIN. It does not reject it, does not return nothing,
# and does not warn: it answers with the VDBE bytecode of the compiled statement
# (addr/opcode/p1..p5/comment, one row per virtual machine instruction). That is
# a well-formed arrayref of row arrayrefs, exactly the type $rs->explain
# promises, so a caller inheriting core's default got a plausible object back
# that answers a question nobody asked. Every other engine in this rollout
# either speaks EXPLAIN or refuses it somewhere a human notices; this was the
# family's one SILENT wrong answer, which is why it was the round's highest
# priority (karr k23).
#
# The existing coverage -- t/resultset/correlate_explain.t and
# t/helpers/resultset_shortcuts.t -- asserts ref eq 'ARRAY' and rows > 0. Both
# of those hold on the bytecode dump too, which is demonstrated below rather
# than asserted from memory: it is the reason the defect survived a green suite.
#
# So the claim pinned here is the DIFFERENCE, taken against the same engine in
# the same run: what the driver answers, what core's inherited default would
# have answered, and the fact that only one of the two contains the plan.

my $schema  = DBIO::SQLite::Test->init_schema;
my $storage = $schema->storage;

note 'libsqlite ' . $storage->_server_info->{dbms_version};

# The two queries are chosen so their ACCESS STRATEGIES differ and the engine
# has to say so: cdid is the INTEGER PRIMARY KEY, title is not indexed at all.
# A plan that could not tell a keyed lookup from a full table scan would be
# useless whatever its formatting.
my $keyed  = $schema->resultset('CD')->search({ cdid => 2 });
my $sought = $schema->resultset('CD')->search({ title => 'Spoonful of bees' });

# ------------------------------------------------- the driver does override it

isnt (
  DBIO::SQLite::Storage->can('_explain_query'),
  DBIO::Storage::DBI->can('_explain_query'),
  'the driver overrides _explain_query -- inheriting core\'s base EXPLAIN here '
. 'is not a missing feature but a wrong answer, so this is the assertion the '
. 'whole file rests on',
);

# ----------------------------------------- what the inherited default would do

# Reached through can() on the base class rather than by unsetting the
# override, so the comparison is against the code core actually ships and stays
# honest if that code changes.
my ($sql, @bind) = @{ ${ $keyed->as_query } };
$sql =~ s/^\s*\((.*)\)\s*$/$1/s;    # as_query parenthesises; core strips too

my $inherited =
  DBIO::Storage::DBI->can('_explain_query')->($storage, $sql, \@bind);

is (
  ref $inherited,
  'ARRAY',
  'core\'s inherited EXPLAIN does NOT throw on SQLite -- it returns the same '
. 'arrayref-of-rows type as a real plan, which is the entire reason this bug '
. 'was silent',
);

ok (
  @$inherited > 0,
  '... and it is not empty either, so "explain returned rows" cannot '
. 'distinguish it from a plan',
);

is (
  $inherited->[0][1],
  'Init',
  '... because what it actually returns is VDBE bytecode: row 0 is the Init '
. 'opcode of the compiled statement, not a step of a query plan',
);

my @inherited_cells = map { grep { defined } @$_ } @$inherited;

ok (
  ! grep( { /\b(?:SCAN|SEARCH|USING)\b/ } @inherited_cells ),
  '... and no cell of the bytecode dump contains the plan vocabulary at all: '
. 'the index the query uses is never named, so the caller cannot recover the '
. 'answer they asked for by reading harder',
);

# ------------------------------------------------------- what the driver does

my $plan = $keyed->explain;

is (ref $plan, 'ARRAY', 'the driver\'s explain returns rows as well');
ok (@$plan > 0, '... and they are not empty');

isnt (
  $plan->[0][1],
  'Init',
  '... but they are not the bytecode dump: whatever the plan format of this '
. 'libsqlite, its second column is not a VDBE opcode',
);

# EXPLAIN QUERY PLAN's output format is documented as interactive-debugging
# material that may change between releases (it did change substantially in
# 3.24.0), so the assertions below deliberately match the vocabulary rather
# than a column layout or an exact string -- the stable claim is that the plan
# names the access strategy, not how it spaces it.
my ($keyed_detail)  = grep { /\bSEARCH\b/ } map { grep { defined } @$_ } @$plan;
my ($scan_detail)   = grep { /\bSCAN\b/ }
                      map  { grep { defined } @$_ } @{ $sought->explain };

ok (
  defined $keyed_detail && $keyed_detail =~ /\bme\b/ && $keyed_detail =~ /\bUSING\b/,
  'a lookup on the INTEGER PRIMARY KEY is reported as a SEARCH of "me" USING '
. "something -- got: " . ( $keyed_detail // '(no SEARCH row)' ),
);

ok (
  defined $scan_detail && $scan_detail =~ /\bme\b/,
  'and a predicate on the unindexed title column is reported as a SCAN of '
. '"me" -- got: ' . ( $scan_detail // '(no SCAN row)' ),
);

isnt (
  $keyed_detail,
  $scan_detail,
  'so the two access strategies are actually told apart. This is what explain '
. 'is called for, and it is precisely the answer the bytecode dump withholds: '
. 'both queries compile to opcodes, and neither dump says which index was '
. 'chosen',
);

# ------------------------------- the statement went through the storage path

# ADR 0040 section 3 makes it a contract requirement without engine-named
# exceptions: every statement an override issues goes through _execute_rendered.
# Reaching for $self->dbh would still produce a correct-looking plan here, so
# nothing above could catch that regression -- but it would silently give back
# the four things core k112 restored. The trace is the observable: it exists
# only because the statement travelled the storage's statement path, and it is
# where redact_bind_value (ADR 0025) sits.
{
  my @traced;

  $storage->debugobj(DBIO::Storage::Statistics->new);
  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(2);

  $keyed->explain;

  $storage->debug(0);
  $storage->debugcb(undef);

  is (
    scalar @traced,
    1,
    'the EXPLAIN reached _query_start -- so it went through _execute_rendered '
  . 'and not past the storage to $self->dbh, which would have traced nothing',
  );

  like (
    $traced[0] // '',
    qr/^EXPLAIN \s+ QUERY \s+ PLAN \s+ SELECT\b/x,
    '... and the statement the storage executed is EXPLAIN QUERY PLAN, named '
  . 'here once so a future rewrite of the override cannot quietly go back to '
  . 'the bare EXPLAIN while still returning rows',
  );

  like (
    $traced[0] // '',
    qr/'2'/,
    '... carrying the query\'s own bind value, which is the caller\'s data: '
  . 'the trace is exactly where redact_bind_value must get its chance at it '
  . '(ADR 0025), and a $dbh bypass would have skipped that seam',
  );
}

done_testing;
