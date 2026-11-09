use strict;
use warnings;

use Test::More;
use Test::Exception;

# ClickHouse SELECT dialect extensions: final, prewhere, limit_by.
#
# Separate from t/10-sqlmaker.t on purpose: that file pins the *base*
# guarantees of the maker (backtick quoting, no FOR UPDATE) by poking the class
# directly, while everything here is about resultset attributes and is only
# meaningful through the full ResultSet -> Storage -> SQLMaker path. The
# attributes reach the maker because core passes unknown attribute keys through
# untouched; a direct ->select() call would never prove that.
#
# Still offline: DBIO::Test->init_schema with no_deploy => 1 builds the schema
# against the ClickHouse storage without connecting to anything, and
# ->as_query only generates SQL.

use DBIO::Test ':DiffSQL';

my $ROWS   = DBIO::SQLMaker::ClassicExtensions->__rows_bindtype;
my $OFFSET = DBIO::SQLMaker::ClassicExtensions->__offset_bindtype;

my $NAME      = { dbic_colname => 'name',      sqlt_datatype => 'varchar', sqlt_size => 100 };
my $RANK      = { dbic_colname => 'rank',      sqlt_datatype => 'integer' };
my $CHARFIELD = { dbic_colname => 'charfield', sqlt_datatype => 'char',    sqlt_size => 10 };

my $schema = DBIO::Test->init_schema(
  storage_type => 'DBIO::ClickHouse::Storage',
  no_deploy    => 1,
);

my $artist = $schema->resultset('Artist');

my $SEL = 'SELECT `me`.`artistid`, `me`.`name`, `me`.`rank`, `me`.`charfield`';

# Without any of the dialect attributes nothing changes: the overridden
# select/_table/_gen_from_blocks/_parse_rs_attrs must be completely inert.
{
  is_same_sql_bind(
    $artist->search({ name => 'foo' })->as_query,
    "( $SEL FROM `artist` `me` WHERE ( `name` = ? ) )",
    [ [ $NAME => 'foo' ] ],
    'plain search is untouched by the dialect hooks',
  );

  my ($sql) = @{ ${ $artist->search({ name => 'foo' })->as_query } };
  unlike $sql, qr/\bFINAL\b/,    'no stray FINAL';
  unlike $sql, qr/\bPREWHERE\b/, 'no stray PREWHERE';
  unlike $sql, qr/\bLIMIT\b/,    'no stray LIMIT';
}

# final => 1 puts FINAL on the table reference, after the alias.
{
  is_same_sql_bind(
    $artist->search({ name => 'foo' }, { final => 1 })->as_query,
    "( $SEL FROM `artist` `me` FINAL WHERE ( `name` = ? ) )",
    [ [ $NAME => 'foo' ] ],
    'final => 1 emits FINAL after the table alias',
  );
}

# FINAL is a per-table-reference modifier: with a join it belongs to the
# primary table only, and must not leak onto the join target.
{
  my $rs = $artist->search({ 'cds.title' => 't' }, { join => 'cds', final => 1 });

  is_same_sql_bind(
    $rs->as_query,
    "( $SEL FROM `artist` `me` FINAL
         LEFT JOIN cd `cds` ON `cds`.`artist` = `me`.`artistid`
       WHERE ( `cds`.`title` = ? ) )",
    [ [ { dbic_colname => 'cds.title', sqlt_datatype => 'varchar', sqlt_size => 100 } => 't' ] ],
    'final => 1 with a join marks the primary table only',
  );

  my ($sql) = @{ ${ $rs->as_query } };
  is scalar(() = $sql =~ /\bFINAL\b/g), 1, 'exactly one FINAL emitted';
}

# prewhere is a normal SQL::Abstract condition, rendered between FROM and
# WHERE, with its binds in that same position.
{
  is_same_sql_bind(
    $artist->search({ name => 'foo' }, { prewhere => { rank => 1 } })->as_query,
    "( $SEL FROM `artist` `me` PREWHERE `rank` = ? WHERE ( `name` = ? ) )",
    [ [ $RANK => 1 ], [ $NAME => 'foo' ] ],
    'prewhere renders before WHERE, its bind before the WHERE bind',
  );

  is_same_sql_bind(
    $artist->search(
      { name => 'foo' },
      { prewhere => { rank => 1, charfield => 'c' } },
    )->as_query,
    "( $SEL FROM `artist` `me`
       PREWHERE ( `charfield` = ? AND `rank` = ? )
       WHERE ( `name` = ? ) )",
    [ [ $CHARFIELD => 'c' ], [ $RANK => 1 ], [ $NAME => 'foo' ] ],
    'multi-column prewhere keeps SQL::Abstract bind semantics',
  );
}

# final and prewhere combine, in the grammar's order: table, FINAL, PREWHERE.
{
  is_same_sql_bind(
    $artist->search(
      { name => 'foo' },
      { final => 1, prewhere => { rank => 1 } },
    )->as_query,
    "( $SEL FROM `artist` `me` FINAL PREWHERE `rank` = ? WHERE ( `name` = ? ) )",
    [ [ $RANK => 1 ], [ $NAME => 'foo' ] ],
    'FINAL precedes PREWHERE',
  );
}

# limit_by lands after ORDER BY and before the ordinary LIMIT/OFFSET. The
# per-group count is inlined (see the POD), so it contributes no bind and the
# only binds are core's LIMIT/OFFSET ones.
{
  is_same_sql_bind(
    $artist->search(undef, {
      order_by => 'me.artistid',
      limit_by => { rows => 3, by => 'me.rank' },
      rows     => 10,
    })->as_query,
    "( $SEL FROM `artist` `me`
       ORDER BY `me`.`artistid`
       LIMIT 3 BY `me`.`rank`
       LIMIT ? )",
    [ [ $ROWS => 10 ] ],
    'limit_by sits between ORDER BY and LIMIT',
  );

  is_same_sql_bind(
    $artist->search(undef, {
      order_by => 'me.artistid',
      limit_by => { rows => 2, by => [qw( me.rank me.name )] },
      rows     => 10,
      offset   => 5,
    })->as_query,
    "( $SEL FROM `artist` `me`
       ORDER BY `me`.`artistid`
       LIMIT 2 BY `me`.`rank`, `me`.`name`
       LIMIT ? OFFSET ? )",
    [ [ $ROWS => 10 ], [ $OFFSET => 5 ] ],
    'limit_by takes a column list and coexists with LIMIT/OFFSET',
  );

  is_same_sql_bind(
    $artist->search(undef, {
      limit_by => { rows => 1, by => \'toStartOfHour(ts)' },
    })->as_query,
    "( $SEL FROM `artist` `me` LIMIT 1 BY toStartOfHour(ts) )",
    [],
    'limit_by accepts a literal-SQL column expression',
  );
}

# A malformed limit_by must fail loudly rather than emit broken SQL.
{
  for my $case (
    [ 'not a hashref'        => [ 3, 'me.rank' ] ],
    [ 'missing rows'         => { by => 'me.rank' } ],
    [ 'zero rows'            => { rows => 0, by => 'me.rank' } ],
    [ 'non-integer rows'     => { rows => '3x', by => 'me.rank' } ],
    [ 'missing by'           => { rows => 3 } ],
    [ 'empty by'             => { rows => 3, by => [] } ],
  ) {
    my ($desc, $spec) = @$case;
    throws_ok {
      $artist->search(undef, { limit_by => $spec })->as_query
    } qr/limit_by/, "limit_by throws on $desc";
  }
}

# The dialect state is per-statement: a resultset built afterwards from the
# same schema (and therefore the same sql_maker) must not inherit anything.
{
  $artist->search(undef, { final => 1, prewhere => { rank => 1 } })->as_query;

  is_same_sql_bind(
    $artist->search({ name => 'foo' })->as_query,
    "( $SEL FROM `artist` `me` WHERE ( `name` = ? ) )",
    [ [ $NAME => 'foo' ] ],
    'no dialect state leaks into the next statement',
  );
}

done_testing;
