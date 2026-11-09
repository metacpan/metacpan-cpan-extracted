use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util 'refaddr';

use DBIO::Test ':DiffSQL';

# ADR 0042: the ResultSet chaining contract.
#
# 1. where()/having() are condition-only chainers: flat key/value list OR a
#    single ref. No attributes. An odd flat list throws. where() with no args
#    is a no-op clone. Repeated calls stack (AND semantics).
# 2. having/offset/join/select/as are the other new chainers; every chaining
#    helper always returns a ResultSet, in every context.
# 3. No public DBIO method changes its return type via wantarray: search,
#    search_related, search_literal, search_like, slice, the has_many and
#    many_to_many accessors and ResultSetColumn::func all THROW in list
#    context. Fetch rows explicitly with ->all.
#
# Fake storage only.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

my $cd_rs     = $schema->resultset('CD');
my $artist_rs = $schema->resultset('Artist');

my $cd_select = '"me"."cdid", "me"."artist", "me"."title", "me"."year", "me"."genreid", "me"."single_track"';
my $cd_from   = 'FROM cd "me"';

my $title_bind =
  [ { dbic_colname => 'title', sqlt_datatype => 'varchar', sqlt_size => 100 } => 'Fireworks' ];

# --- A) the canonical chain from the ticket ------------------------------
# $rs->where(col1 => 'value')->order_by(-desc => 'col1')->group_by('col1')
#    ->having(cnt => { '>' => 3 })->join('artist')->offset(20)->rows(10);
# (real CD columns stand in for the ticket's generic col1/cnt)

is_same_sql_bind(
  $cd_rs->where(title => 'Fireworks')
    ->order_by(-desc => 'year')
    ->group_by('year')
    ->having(artist => { '>' => 3 })
    ->join('artist')
    ->offset(20)
    ->rows(10)
    ->as_query,
  '(SELECT ' . $cd_select . ' ' . $cd_from
    . ' JOIN "artist" "artist" ON "artist"."artistid" = "me"."artist"'
    . ' WHERE ( "title" = ? )'
    . ' GROUP BY "year" HAVING "artist" > ?'
    . ' ORDER BY "me"."year" DESC'
    . ' LIMIT ? OFFSET ?)',
  [
    $title_bind,
    [ { dbic_colname => 'artist', sqlt_datatype => 'integer' } => 3 ],
    [ { sqlt_datatype => 'integer' } => 10 ],
    [ { sqlt_datatype => 'integer' } => 20 ],
  ],
  'the ticket chain composes in one expression and yields one query',
);

# --- B) where() signature -------------------------------------------------

is_same_sql_bind(
  $cd_rs->where(title => 'Fireworks')->as_query,
  '(SELECT ' . $cd_select . ' ' . $cd_from . ' WHERE ( "title" = ? ))',
  [ $title_bind ],
  'where(flat list) collapses the list into a condition hashref',
);

is_same_sql_bind(
  $cd_rs->where({ title => 'Fireworks' })->as_query,
  $cd_rs->where(title => 'Fireworks')->as_query,
  [],
  'where(single hashref) is identical to the flat-list form',
);

is_same_sql_bind(
  $cd_rs->where([ { year => 2001 }, { year => 2002 } ])->as_query,
  '(SELECT ' . $cd_select . ' ' . $cd_from
    . ' WHERE ( ( "year" = ? ) OR ( "year" = ? ) ))',
  [
    [ { dbic_colname => 'year', sqlt_datatype => 'varchar', sqlt_size => 100 } => 2001 ],
    [ { dbic_colname => 'year', sqlt_datatype => 'varchar', sqlt_size => 100 } => 2002 ],
  ],
  'where(arrayref) is passed through verbatim as an OR condition',
);

is_same_sql_bind(
  $cd_rs->where(\'artist = 1')->as_query,
  '(SELECT ' . $cd_select . ' ' . $cd_from . ' WHERE artist = 1)',
  [],
  'where(literal scalarref) is passed through verbatim',
);

{
  my $clone = $cd_rs->where;
  isnt Scalar::Util::refaddr($clone), Scalar::Util::refaddr($cd_rs),
    'where() with no args returns a new ResultSet';
  is_same_sql_bind($clone->as_query, $cd_rs->as_query, [],
    '... with the same SQL as the unmodified resultset');
}

throws_ok { $cd_rs->where('a') } 'DBIO::Exception',
  'where(single scalar) throws';
throws_ok { $cd_rs->where('a') } qr/Odd number of elements/,
  '... naming the odd-number-of-elements mistake';
throws_ok { $cd_rs->where(a => 1, 'b') } 'DBIO::Exception',
  'where(odd flat list) throws';

throws_ok { $cd_rs->where({ a => 1 }, { b => 2 }) } qr/plain scalars/,
  'where(two refs) throws instead of building a stringified-refaddr condition';
throws_ok { $cd_rs->where({ a => 1 }, { b => 2 }) } 'DBIO::Exception',
  '... and the exception class is DBIO::Exception';

is_same_sql_bind(
  $cd_rs->where(title => 'Fireworks')->where(year => 2001)->as_query,
  '(SELECT ' . $cd_select . ' ' . $cd_from
    . ' WHERE ( "title" = ? AND "year" = ? ))',
  [
    $title_bind,
    [ { dbic_colname => 'year', sqlt_datatype => 'varchar', sqlt_size => 100 } => 2001 ],
  ],
  'repeated where() stacks the conditions with AND semantics',
);

# --- C) having() ----------------------------------------------------------

is_same_sql_bind(
  $cd_rs->group_by('artist')->having(artist => { '>' => 3 })->as_query,
  '(SELECT ' . $cd_select . ' ' . $cd_from
    . ' GROUP BY "artist" HAVING "artist" > ?)',
  [ [ { dbic_colname => 'artist', sqlt_datatype => 'integer' } => 3 ] ],
  'having(flat list) sets the HAVING clause',
);

is_same_sql_bind(
  $cd_rs->group_by('artist')->having({ artist => { '>' => 3 } })->as_query,
  $cd_rs->group_by('artist')->having(artist => { '>' => 3 })->as_query,
  [],
  'having(single hashref) is identical to the flat-list form',
);

throws_ok { $cd_rs->having(artist => 3, 'genreid') } 'DBIO::Exception',
  'having(odd flat list) throws';

throws_ok { $cd_rs->having({ a => 1 }, { b => 2 }) } qr/plain scalars/,
  'having(two refs) throws instead of building a stringified-refaddr condition';

is_same_sql_bind(
  $cd_rs->group_by('artist')
    ->having(artist => { '>' => 3 })
    ->having(genreid => { '>' => 1 })
    ->as_query,
  '(SELECT ' . $cd_select . ' ' . $cd_from
    . ' GROUP BY "artist" HAVING ( "artist" > ? AND "genreid" > ? ))',
  [
    [ { dbic_colname => 'artist', sqlt_datatype => 'integer' } => 3 ],
    [ { dbic_colname => 'genreid', sqlt_datatype => 'integer' } => 1 ],
  ],
  'repeated having() stacks the conditions with AND semantics',
);

# --- D) offset() / rows() -------------------------------------------------

is_same_sql_bind(
  $cd_rs->offset(20)->rows(10)->as_query,
  '(SELECT ' . $cd_select . ' ' . $cd_from . ' LIMIT ? OFFSET ?)',
  [
    [ { sqlt_datatype => 'integer' } => 10 ],
    [ { sqlt_datatype => 'integer' } => 20 ],
  ],
  'offset()/rows() set the LIMIT/OFFSET pair',
);

is_same_sql_bind(
  $cd_rs->offset(20)->as_query,
  '(SELECT ' . $cd_select . ' ' . $cd_from . ' LIMIT ? OFFSET ?)',
  [
    [ { sqlt_datatype => 'integer' } => 2147483647 ],
    [ { sqlt_datatype => 'integer' } => 20 ],
  ],
  'offset() alone falls back to the max-rows LIMIT, like any plain offset search',
);

# --- E) join() ------------------------------------------------------------

is_same_sql_bind(
  $cd_rs->join('tracks')->as_query,
  '(SELECT ' . $cd_select . ' ' . $cd_from
    . ' LEFT JOIN "track" "tracks" ON "tracks"."cd" = "me"."cdid")',
  [],
  'join(has_many rel) produces a LEFT JOIN (the relationship default)',
);

is_same_sql_bind(
  $cd_rs->join('artist')->as_query,
  '(SELECT ' . $cd_select . ' ' . $cd_from
    . ' JOIN "artist" "artist" ON "artist"."artistid" = "me"."artist")',
  [],
  'join(belongs_to rel) produces an INNER JOIN - the relationship join_type decides, not the helper',
);

is_same_sql_bind(
  $cd_rs->join('artist')->as_query,
  $cd_rs->search(undef, { join => 'artist' })->as_query,
  [],
  'join($rel) is exactly search(undef, { join => $rel })',
);

# --- F) select() / as() ---------------------------------------------------

my $projection = '(SELECT "me"."cdid", "me"."title" ' . $cd_from . ')';

is_same_sql_bind(
  $cd_rs->select([ 'me.cdid', 'me.title' ])->as_query,
  $projection,
  [],
  'select(\@cols) narrows the projection',
);

is_same_sql_bind(
  $cd_rs->select([ 'me.cdid', 'me.title' ], [ 'cdid', 'title' ])->as_query,
  $projection,
  [],
  'select(\@cols, \@as) - the pair given together in one call',
);

is_same_sql_bind(
  $cd_rs->select([ 'me.cdid', 'me.title' ])->as([ 'cdid', 'title' ])->as_query,
  $cd_rs->select([ 'me.cdid', 'me.title' ], [ 'cdid', 'title' ])->as_query,
  [],
  'select(\@cols)->as(\@aliases) produces the same SQL as the two-arg form',
);

throws_ok { $cd_rs->as([ 'cdid' ]) } 'DBIO::Exception',
  'as() without a preceding select() throws';
throws_ok { $cd_rs->as([ 'cdid' ]) } qr/as\(\) needs a preceding select/,
  '... with a message pointing at the select()/as() pair';

is_same_sql_bind(
  $cd_rs->select('me.cdid')->as_query,
  '(SELECT "me"."cdid" ' . $cd_from . ')',
  [],
  'select(single scalar) also works as a bare select',
);

{
  my $clone = $cd_rs->select;
  isnt Scalar::Util::refaddr($clone), Scalar::Util::refaddr($cd_rs),
    'select() with no args returns a new ResultSet';
  is_same_sql_bind($clone->as_query, $cd_rs->as_query, [],
    '... with the same SQL as the unmodified resultset -- no reset to default columns');
}

is_same_sql_bind(
  $cd_rs->select([ 'me.cdid', 'me.title' ])->select->as_query,
  $projection,
  [],
  'select()->select() is a no-op: the second call does not silently reset the projection',
);

# --- G) list-context regression: every former wantarray-dependent entry point

{
  throws_ok { my @rows = $cd_rs->search({ year => 2001 }) } 'DBIO::Exception',
    'search() in list context throws (ADR 0042)';
  throws_ok { my @rows = $cd_rs->search({ year => 2001 }) } qr/list context/,
    '... the exception names list context';
  isa_ok $cd_rs->search({ year => 2001 }), 'DBIO::ResultSet',
    'search() in scalar context still returns a ResultSet';

  throws_ok { my @rows = $cd_rs->search_related('tracks') } 'DBIO::Exception',
    'search_related() in list context throws';
  throws_ok { my @rows = $cd_rs->search_literal('year = ?', 2001) } 'DBIO::Exception',
    'search_literal() in list context throws';
  throws_ok { my @rows = $cd_rs->search_like({ title => 'Fire%' }) } 'DBIO::Exception',
    'search_like() in list context throws';
  throws_ok { my @rows = $cd_rs->slice(0, 10) } 'DBIO::Exception',
    'slice() in list context throws';
}

# relationship accessors need a Row object; find() against the mock storage
{
  $storage->mock_persistent(qr/FROM "artist"/i, [ [ 1, 'Miles Davis', 13, undef ] ]);
  my $artist = $artist_rs->find(1);

  throws_ok { my @cds = $artist->cds } 'DBIO::Exception',
    'has_many accessor in list context throws (use ->cds->all)';
  throws_ok { my @cds = $artist->cds } qr/list context/,
    '... the exception names list context';
  isa_ok $artist->cds, 'DBIO::ResultSet',
    'has_many accessor in scalar context still returns a ResultSet';
}

{
  $storage->mock_persistent(qr/FROM cd\b/i, [ [ 10, 1, 'Bitches Brew', '1970', undef, undef ] ]);
  my $cd = $cd_rs->find(10);

  throws_ok { my @producers = $cd->producers } 'DBIO::Exception',
    'many_to_many accessor in list context throws (use ->producers->all)';
  isa_ok $cd->producers, 'DBIO::ResultSet',
    'many_to_many accessor in scalar context still returns a ResultSet';
}

{
  $storage->mock_persistent(qr/FROM cd\b/i, [ [ 9 ] ]);
  my $rscol = $cd_rs->search({ artist => 1 })->get_column('title');

  is $rscol->func('LENGTH'), 9,
    'func() in scalar context returns the single aggregate value';
  throws_ok { my @v = $rscol->func('LENGTH') } 'DBIO::Exception',
    'ResultSetColumn::func() in list context throws (use func_rs($fn)->all)';
}

# --- H) a method that merely derives a ResultSet returns it in every context
# (karr k285), and a refusal names its own method

{
  my $op = $cd_rs->search(undef, { columns => ['title'] });

  my @sub = $cd_rs->as_subselect_rs;
  ok @sub == 1 && $sub[0]->isa('DBIO::ResultSet'),
    'as_subselect_rs in list context returns one ResultSet';

  for my $m (qw(union union_all intersect intersect_all except except_all)) {
    my @r = eval { $op->$m($op) };
    ok !$@ && @r == 1 && $r[0]->isa('DBIO::ResultSet'),
      "$m in list context returns one ResultSet" or diag $@;
  }

  my $with_cl = $schema->resultset('Artist')->new_result({ artistid => 1, name => 'x' });
  throws_ok { my @r = $with_cl->search_related('cds') }
    qr/->search_related was called in list context/,
    'Row::search_related in list context throws under its own name';

  throws_ok { my @r = $cd_rs->search_like({ title => 'Fire%' }) } qr/->search_like was called/,
    'search_like in list context names itself';
}

# search_like's deprecation text carries no removal version
{
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  my $rs = $cd_rs->search_like({ title => 'Fire%' });
  my ($msg) = grep { /search_like\(\) is deprecated/ } @w;
  ok $msg, 'search_like warns that it is deprecated';
  unlike $msg // '', qr/will be removed|version 0\.\d+/,
    '... without promising a removal version';
}

done_testing;
