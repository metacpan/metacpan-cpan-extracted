use strict;
use warnings;

use Test::More;

use DBIO::Test ':DiffSQL';

my ($TOTAL, $OFFSET, $ROWS) = (
   DBIO::SQLMaker::ClassicExtensions->__total_bindtype,
   DBIO::SQLMaker::ClassicExtensions->__offset_bindtype,
   DBIO::SQLMaker::ClassicExtensions->__rows_bindtype,
);

# Core dropped the runtime sql_maker->limit_dialect('RowNum') setter; the RowNum
# wrapping now lives in DBIO::Oracle::SQLMaker::apply_limit. Drive that path by
# pointing the (fake, no-deploy) storage at DBIO::Oracle::Storage, exactly as the
# sibling Oracle SQLMaker tests do.
my $s = DBIO::Test->init_schema(
  storage_type => 'DBIO::Oracle::Storage',
  no_deploy => 1,
  # The ported assertions below carry unquoted identifiers (as the original
  # generic-maker test did); '' = no quoting on the Oracle maker.
  quote_char => '',
);

my $rs = $s->resultset ('CD')->search({ id => 1 });

# important for a test below, never traversed
$rs->result_source->add_relationship(
  ends_with_me => 'DBIO::Test::Schema::Artist', sub {}
);


my $where_bind = [ { dbic_colname => 'id' }, 1 ];

for my $test_set (
  {
    name => 'Rownum subsel aliasing works correctly',
    rs => $rs->search_rs(undef, {
      rows => 1,
      offset => 3,
      columns => [
        { id => 'foo.id' },
        { 'artist.id' => 'bar.id' },
        { bleh => \'TO_CHAR (foo.womble, "blah")' },
      ]
    }),
    sql => '(
      SELECT id, artist__id, bleh
      FROM (
        SELECT id, artist__id, bleh, ROWNUM AS rownum__index
        FROM (
          SELECT foo.id AS id, bar.id AS artist__id, TO_CHAR (foo.womble, "blah") AS bleh
            FROM cd me
          WHERE id = ?
        ) me
      ) me WHERE rownum__index BETWEEN ? AND ?
    )',
    binds => [
      $where_bind,
      [ $OFFSET => 4 ],
      [ $TOTAL => 4 ],
    ],
  }, {
    name => 'Rownum subsel aliasing works correctly with unique order_by',
    rs => $rs->search_rs(undef, {
      rows => 1,
      offset => 3,
      columns => [
        { id => 'foo.id' },
        { 'artist.id' => 'bar.id' },
        { bleh => \'TO_CHAR (foo.womble, "blah")' },
      ],
      order_by => [qw( artist title )],
    }),
    sql => '(
      SELECT id, artist__id, bleh
      FROM (
        SELECT id, artist__id, bleh, ROWNUM AS rownum__index
        FROM (
          SELECT foo.id AS id, bar.id AS artist__id, TO_CHAR(foo.womble, "blah") AS bleh
            FROM cd me
          WHERE id = ?
          ORDER BY artist, title
        ) me
        WHERE ROWNUM <= ?
      ) me
      WHERE rownum__index >= ?
    )',
    binds => [
      $where_bind,
      [ $TOTAL => 4 ],
      [ $OFFSET => 4 ],
    ],
  },
 {
    name => 'Rownum subsel aliasing works correctly with non-unique order_by',
    rs => $rs->search_rs(undef, {
      rows => 1,
      offset => 3,
      columns => [
        { id => 'foo.id' },
        { 'artist.id' => 'bar.id' },
        { bleh => \'TO_CHAR (foo.womble, "blah")' },
      ],
      order_by => 'artist',
    }),
    sql => '(
      SELECT id, artist__id, bleh
      FROM (
        SELECT id, artist__id, bleh, ROWNUM AS rownum__index
        FROM (
          SELECT foo.id AS id, bar.id AS artist__id, TO_CHAR(foo.womble, "blah") AS bleh
            FROM cd me
          WHERE id = ?
          ORDER BY artist
        ) me
      ) me
      WHERE rownum__index BETWEEN ? and ?
    )',
    binds => [
      $where_bind,
      [ $OFFSET => 4 ],
      [ $TOTAL => 4 ],
    ],
  }, {
    name => 'Rownum subsel aliasing #2 works correctly',
    rs => $rs->search_rs(undef, {
      rows => 2,
      offset => 3,
      columns => [
        { id => 'foo.id' },
        { 'ends_with_me.id' => 'ends_with_me.id' },
      ]
    }),
    sql => '(
      SELECT id, ends_with_me__id
      FROM (
        SELECT id, ends_with_me__id, ROWNUM AS rownum__index
        FROM (
          SELECT foo.id AS id, ends_with_me.id AS ends_with_me__id
            FROM cd me
          WHERE id = ?
        ) me
      ) me WHERE rownum__index BETWEEN ? AND ?
    )',
    binds => [
      $where_bind,
      [ $OFFSET => 4 ],
      [ $TOTAL => 5 ],
    ],
  }, {
    name => 'Rownum subsel aliasing #2 works correctly with unique order_by',
    rs => $rs->search_rs(undef, {
      rows => 2,
      offset => 3,
      columns => [
        { id => 'foo.id' },
        { 'ends_with_me.id' => 'ends_with_me.id' },
      ],
      order_by => [qw( year artist title )],
    }),
    sql => '(
      SELECT id, ends_with_me__id
      FROM (
        SELECT id, ends_with_me__id, ROWNUM AS rownum__index
        FROM (
          SELECT foo.id AS id, ends_with_me.id AS ends_with_me__id
            FROM cd me
          WHERE id = ?
          ORDER BY year, artist, title
        ) me
        WHERE ROWNUM <= ?
      ) me
      WHERE rownum__index >= ?
    )',
    binds => [
      $where_bind,
      [ $TOTAL => 5 ],
      [ $OFFSET => 4 ],
    ],
  }
) {
  is_same_sql_bind(
    $test_set->{rs}->as_query,
    $test_set->{sql},
    $test_set->{binds},
    $test_set->{name});
}

{
my $subq = $s->resultset('Owners')->search({
   'count.id' => { -ident => 'owner.id' },
}, { alias => 'owner' })->count_rs;

my $rs_selectas_rel = $s->resultset('BooksInLibrary')->search ({}, {
  columns => [
     { owner_name => 'owner.name' },
     { owner_books => $subq->as_query },
  ],
  join => 'owner',
  rows => 2,
  offset => 3,
});

is_same_sql_bind(
  $rs_selectas_rel->as_query,
  '(
    SELECT owner_name, owner_books
      FROM (
        SELECT owner_name, owner_books, ROWNUM AS rownum__index
          FROM (
            SELECT  owner.name AS owner_name,
              ( SELECT COUNT( * ) FROM owners owner WHERE (count.id = owner.id)) AS owner_books
              FROM books me
              JOIN owners owner ON owner.id = me.owner
            WHERE ( source = ? )
          ) me
      ) me
    WHERE rownum__index BETWEEN ? AND ?
  )',
  [
    [ { sqlt_datatype => 'varchar', sqlt_size => 100, dbic_colname => 'source' }
      => 'Library' ],
    [ $OFFSET => 4 ],
    [ $TOTAL => 5 ],
  ],

  'pagination with subquery works'
);

}

{
  $rs = $s->resultset('Artist')->search({}, {
    columns => 'name',
    offset => 1,
    order_by => 'name',
  });
  # Kept short (< 30 chars): the Oracle maker would otherwise rewrite an
  # over-long table name via identifier shortening (covered separately in
  # t/30-sqlmaker-oracle.t), which is orthogonal to what this asserts -- that
  # the RowNum wrapping passes embedded newlines/tabs/spaces through untouched.
  local $rs->result_source->{name} = "weird \n nl/m \t \t sp \n tbl";

  like (
    ${$rs->as_query}->[0],
    qr| weird \s \n \s nl/m \s \t \s \t \s sp \s \n \s tbl|x,
    'Newlines/spaces preserved in final sql',
  );
}

{
my $subq = $s->resultset('Owners')->search({
   'books.owner' => { -ident => 'owner.id' },
}, { alias => 'owner', select => ['id'] } )->count_rs;

my $rs_selectas_rel = $s->resultset('BooksInLibrary')->search( { -exists => $subq->as_query }, { select => ['id','owner'], rows => 1 } );

# The EXISTS subquery body (EXISTS((...))) is core DBIO behavior -- identical on
# the default storage, not an Oracle artifact. Note: the EXISTS now correlates
# directly to the outer "books me" via books.owner; the previously expected auto
# "LEFT JOIN books books ON books.owner = owner.id" was a core correlation bug --
# it shadowed the outer "books me" by SQL lexical scoping and silently
# de-correlated the EXISTS. Fixed in core karr #25, so the join is gone here.
# What this test owns is the Oracle rows-only wrap: ... ) me WHERE ROWNUM <= ?.
is_same_sql_bind(
  $rs_selectas_rel->as_query,
  '(
    SELECT me.id, me.owner FROM (
      SELECT me.id, me.owner  FROM books me WHERE ( ( EXISTS((SELECT COUNT( * ) FROM owners owner WHERE ( books.owner = owner.id ))) AND source = ? ) )
    ) me
    WHERE ROWNUM <= ?
  )',
  [
    [ { sqlt_datatype => 'varchar', sqlt_size => 100, dbic_colname => 'source' } => 'Library' ],
    [ $ROWS => 1 ],
  ],
  'Pagination with sub-query in WHERE works'
);

}

done_testing;
