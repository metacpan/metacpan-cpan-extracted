use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';

# ResultSet methods whose whole point is producing a fragment for use inside
# a bigger query (folded in from DBIx::Class::Helper::ResultSet::Util's
# correlate(), ::SearchOr and ::Shortcut::ResultsExist's
# results_exist_as_query). Fake storage only.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my $rs = $schema->resultset('Artist');

# --- A) results_exist_as_query: an EXISTS(...) fragment, not a boolean --
#
# Unlike results_exist/results_exist_async this never touches the storage
# execution path, so it is fully testable as a SQL shape.
#
# The fragment is whatever the storage's _exists_value_sql hook renders,
# wrapped in the one decoration core is allowed to add: a pair of parentheses
# (ADR 0037 section 2). The base rendering is the standard CASE form; the
# seam itself is covered in t/test/23_exists_query_seam.t.

is_same_sql_bind(
  $rs->results_exist_as_query,
  '( SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me") THEN 1 ELSE 0 END )',
  [],
  'with no condition, it is a bare EXISTS over the whole source',
);

is_same_sql_bind(
  $rs->results_exist_as_query({ name => 'foo' }),
  '( SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me" WHERE ( "name" = ? ))'
    . ' THEN 1 ELSE 0 END )',
  [ [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'foo' ] ],
  'the optional condition narrows the EXISTS subquery',
);

# The dummy "42" projection is deliberate: EXISTS only cares whether a row
# comes back, not what is in it. A prior search()'s own column projection
# must not leak into this subquery.
is_same_sql_bind(
  $rs->search(undef, { columns => ['name'] })->results_exist_as_query,
  $rs->results_exist_as_query,
  'an earlier explicit projection does not leak into the EXISTS subquery',
);

# --- B) correlate: a ResultSet correlated to the invocant's alias --------

{
  my $corr = $rs->correlate('cds');

  is($corr->current_source_alias, 'cds_alias',
    'correlate() aliases the related ResultSet as "<rel>_alias"');

  is_same_sql_bind(
    $corr->as_query,
    '(SELECT "cds_alias"."cdid", "cds_alias"."artist", "cds_alias"."title",'
      . ' "cds_alias"."year", "cds_alias"."genreid", "cds_alias"."single_track"'
      . ' FROM cd "cds_alias" WHERE ( "cds_alias"."artist" = "me"."artistid" ))',
    [],
    'the correlated ResultSet\'s WHERE ties it back to the outer "me" alias',
  );
}

# The documented use case: embedded as a scalar subquery in '+columns'.
is_same_sql_bind(
  $rs->search(undef, {
    '+columns' => { cd_count => $rs->correlate('cds')->count_rs->as_query },
  })->as_query,
  '(SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield",'
    . ' (SELECT COUNT( * ) FROM cd "cds_alias" WHERE ( "cds_alias"."artist" = "me"."artistid" ))'
    . ' FROM "artist" "me")',
  [],
  'correlate() composes into a per-row count subquery, the documented use case',
);

# --- C) search_or: OR's together the resolved WHERE of each operand -----

{
  my $a = $rs->search({ rank => 1 });
  my $b = $rs->search({ rank => 2 });

  is_same_sql_bind(
    $rs->search_or([ $a, $b ])->as_query,
    '(SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield"'
      . ' FROM "artist" "me" WHERE ( "rank" = ? OR "rank" = ? ))',
    [
      [ { dbic_colname => 'rank', sqlt_datatype => 'integer' } => 1 ],
      [ { dbic_colname => 'rank', sqlt_datatype => 'integer' } => 2 ],
    ],
    'search_or([a, b]) ORs the two conditions together',
  );

  # The upstream guarantee this component exists for: the invocant's own
  # filter still applies, ANDed onto the OR group - search_or is not a
  # replacement for the invocant's condition, only an addition to it.
  my $filtered = $rs->search({ charfield => 'X' });
  is_same_sql_bind(
    $filtered->search_or([ $a, $b ])->as_query,
    '(SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield"'
      . ' FROM "artist" "me" WHERE ( ( "rank" = ? OR "rank" = ? ) AND "charfield" = ? ))',
    [
      [ { dbic_colname => 'rank', sqlt_datatype => 'integer' } => 1 ],
      [ { dbic_colname => 'rank', sqlt_datatype => 'integer' } => 2 ],
      [ { dbic_colname => 'charfield', sqlt_datatype => 'char', sqlt_size => 10 } => 'X' ],
    ],
    'the invocant\'s own condition still limits the result, same as upstream promises',
  );

  throws_ok { $rs->search_or([ $a, $schema->resultset('CD') ]) } 'DBIO::Exception',
    'a ResultSet from a different result_source throws a typed exception';
  throws_ok { $rs->search_or([ $a, $schema->resultset('CD') ]) }
    qr/All ResultSets passed to search_or must have the same result_source/,
    'the exception says why';
}

done_testing;
