use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';

# The remaining always-on ResultSet chainers (folded in from
# DBIx::Class::Helper::ResultSet::{Me,Bare,OneRow,Random} and
# ::Shortcut::{Distinct,GroupBy,HRI,Prefetch}), plus core's own page() -
# tested here alongside them since limited_page (t/helpers/column_shortcuts.t)
# is built directly on top of it. Fake storage only.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

my $rs = $schema->resultset('Artist');

my $all = '"me"."artistid", "me"."name", "me"."rank", "me"."charfield"';

sub artist_sql {
  my ($select, $tail) = @_;
  return "(SELECT $select FROM \"artist\" \"me\"" . ($tail ? " $tail" : '') . ')';
}

# --- A) me: current_source_alias with a dot, for search conditions ---

is($rs->me, 'me.', 'me() with no argument is the alias plus a dot');
is($rs->me('title'), 'me.title', 'me($col) appends the column to the alias');

is($rs->search(undef, { alias => 'artist' })->me, 'artist.',
  'me() follows the ResultSet\'s own alias, not a literal "me"');

# The actual point of me(): disambiguating a column that exists on both
# sides of a join, same fixture as the null/not_null/like/not_like tests
# in t/helpers/search_shortcuts.t.
{
  my $cds = $schema->resultset('CD')->search(undef, { join => 'tracks' });

  is_same_sql_bind(
    $cds->search({ $cds->me('title') => 'Fireworks' })->as_query,
    '(SELECT "me"."cdid", "me"."artist", "me"."title", "me"."year",'
      . ' "me"."genreid", "me"."single_track" FROM cd "me"'
      . ' LEFT JOIN "track" "tracks" ON "tracks"."cd" = "me"."cdid"'
      . ' WHERE ( "me"."title" = ? ))',
    [ [ { dbic_colname => 'me.title', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'Fireworks' ] ],
    'me() qualifies a condition column that would otherwise be ambiguous',
  );
}

# --- B) distinct / group_by -------------------------------------------

is_same_sql_bind(
  $rs->distinct->as_query,
  artist_sql($all, 'GROUP BY ' . $all),
  [],
  'distinct with no argument defaults to true (GROUP BY every selected column)',
);

is_same_sql_bind(
  $rs->distinct(1)->as_query,
  $rs->distinct->as_query,
  'distinct(1) is the same as the no-argument form',
);

is_same_sql_bind(
  $rs->distinct(0)->as_query,
  artist_sql($all),
  [],
  'distinct(0) turns it back off - a plain || would treat 0 as "use the default"',
);

is_same_sql_bind(
  $rs->group_by(['rank'])->as_query,
  artist_sql($all, 'GROUP BY "rank"'),
  [],
  'group_by() sets the GROUP BY clause verbatim, unqualified',
);

is_same_sql_bind(
  $rs->group_by('rank')->as_query,
  $rs->group_by(['rank'])->as_query,
  'a plain scalar column name works the same as a one-element arrayref',
);

is_same_sql_bind(
  $rs->group_by(['rank', 'name'])->as_query,
  artist_sql($all, 'GROUP BY "rank", "name"'),
  [],
  'group_by() takes several columns and keeps their order',
);

# --- C) hri: sets result_class, actually changes what next() returns --

is(
  $rs->hri->result_class,
  'DBIO::ResultClass::HashRefInflator',
  'hri() sets result_class to the HashRefInflator',
);

{
  $storage->mock(qr/SELECT.*FROM "artist"/i, [
    [ 1, 'Caterwauler McCrae', 13, undef ],
  ]);

  my $row = $rs->hri->next;
  is(ref($row), 'HASH', 'hri() makes next() return a plain hashref, not a Row');
  is_deeply(
    $row,
    { artistid => 1, name => 'Caterwauler McCrae', rank => 13, charfield => undef },
    'the hashref carries the row data',
  );
}

# --- D) prefetch: adds the related columns and a LEFT JOIN ------------

is_same_sql_bind(
  $rs->prefetch('cds')->as_query,
  '(SELECT ' . $all
    . ', "cds"."cdid", "cds"."artist", "cds"."title", "cds"."year",'
    . ' "cds"."genreid", "cds"."single_track"'
    . ' FROM "artist" "me" LEFT JOIN cd "cds" ON "cds"."artist" = "me"."artistid")',
  [],
  'prefetch(single relation) merges in its columns via a LEFT JOIN',
);

is_same_sql_bind(
  $rs->prefetch('cds', 'onekeys')->as_query,
  '(SELECT ' . $all
    . ', "cds"."cdid", "cds"."artist", "cds"."title", "cds"."year",'
    . ' "cds"."genreid", "cds"."single_track", "onekeys"."id", "onekeys"."artist", "onekeys"."cd"'
    . ' FROM "artist" "me"'
    . ' LEFT JOIN cd "cds" ON "cds"."artist" = "me"."artistid"'
    . ' LEFT JOIN "onekey" "onekeys" ON "onekeys"."artist" = "me"."artistid")',
  [],
  'prefetch(rel1, rel2) - the variadic form wraps the extra relations into one arrayref',
);

# --- E) no_columns / bare ----------------------------------------------

is_same_sql_bind(
  $rs->no_columns->as_query,
  '(SELECT * FROM "artist" "me")',
  [],
  'no_columns() clears the projection down to a bare *',
);

is_same_sql_bind(
  $rs->no_columns->add_columns(['name'])->as_query,
  artist_sql('"me"."name"'),
  [],
  'add_columns after no_columns starts the projection from scratch, not from the default list',
);

is_same_sql_bind(
  $rs->search({ name => 'foo' })->bare->as_query,
  $rs->as_query,
  'bare() discards a previously applied search condition entirely',
);

# --- F) one_row: search+rows(1)+next in one call, actually exhausts a row --

{
  $storage->reset_captured;
  $storage->mock(qr/SELECT.*FROM "artist"/i, [
    [ 1, 'First', 13, undef ],
    [ 2, 'Second', 5, undef ],
  ]);

  my $row = $rs->one_row;
  isa_ok($row, 'DBIO::Row', 'one_row() returns a real Row object, not a list');
  is($row->name, 'First', 'one_row() returns the first row of the cursor');

  my @q = $storage->captured_queries;
  is(scalar(@q), 1, 'one_row() issues exactly one query');
  like($q[0]{sql}, qr/LIMIT/, 'one_row() applies the rows => 1 limit');
}

{
  $storage->reset_captured;
  $storage->mock(qr/SELECT.*FROM "artist"/i, [
    [ 5, 'Filtered', 1, undef ],
  ]);

  my $row = $rs->one_row({ name => 'Filtered' });
  is($row->name, 'Filtered', 'one_row($cond) passes the condition through like search()');

  my @q = $storage->captured_queries;
  like($q[0]{sql}, qr/WHERE/, 'the condition actually reached the WHERE clause');
}

# --- G) rand: adds ORDER BY <random>, LIMIT <amount> --------------------

is_same_sql_bind(
  $rs->rand->as_query,
  artist_sql($all, 'ORDER BY RANDOM() LIMIT ?'),
  [ [ { sqlt_datatype => 'integer' } => 1 ] ],
  'rand() with no argument defaults to one row, ordered by the storage random function',
);

is_same_sql_bind(
  $rs->rand(5)->as_query,
  artist_sql($all, 'ORDER BY RANDOM() LIMIT ?'),
  [ [ { sqlt_datatype => 'integer' } => 5 ] ],
  'rand($n) asks for $n random rows',
);

throws_ok { $rs->rand(0) } 'DBIO::Exception',
  'rand(0) throws a typed exception';
throws_ok { $rs->rand(0) } qr/rand can only return a positive amount of rows/,
  'rand(0) - zero is not a positive amount';

throws_ok { $rs->rand(-1) } qr/rand can only return a positive amount of rows/,
  'rand(-1) is rejected the same way';

throws_ok { $rs->rand(1.5) } qr/rand can only return an integer amount of rows/,
  'rand(1.5) - a fractional amount is rejected too';

# --- H) page: the core variant, rebuilt via new() instead of search() --
#
# page() falls out of the search()/search_rs() pattern the rest of this
# block uses - it reconstructs the ResultSet directly via (ref $self)->new
# with the merged attrs. These characterise that the merge still behaves
# like every other chainer: an existing condition survives, and calling
# page() again replaces the page number instead of stacking offsets.

is_same_sql_bind(
  $rs->page(2)->rows(10)->as_query,
  artist_sql($all, 'LIMIT ? OFFSET ?'),
  [
    [ { sqlt_datatype => 'integer' } => 10 ],
    [ { sqlt_datatype => 'integer' } => 10 ],
  ],
  'page(2)->rows(10) - page 2 of 10 starts at offset 10',
);

is_same_sql_bind(
  $rs->rows(10)->page(2)->page(3)->as_query,
  artist_sql($all, 'LIMIT ? OFFSET ?'),
  [
    [ { sqlt_datatype => 'integer' } => 10 ],
    [ { sqlt_datatype => 'integer' } => 20 ],
  ],
  'calling page() again replaces the page number - offsets do not stack',
);

is_same_sql_bind(
  $rs->search({ name => 'foo' })->page(2)->rows(10)->as_query,
  artist_sql($all, 'WHERE ( "name" = ? ) LIMIT ? OFFSET ?'),
  [
    [ { dbic_colname => 'name', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'foo' ],
    [ { sqlt_datatype => 'integer' } => 10 ],
    [ { sqlt_datatype => 'integer' } => 10 ],
  ],
  'page() preserves an existing search condition from earlier in the chain',
);

done_testing;
