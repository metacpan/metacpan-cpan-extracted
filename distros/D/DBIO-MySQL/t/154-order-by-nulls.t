use strict;
use warnings;

use Test::More;

use DBIO::Test ':DiffSQL';

# karr k119: MySQL and MariaDB have no NULLS FIRST / NULLS LAST, so the
# SQLMaker emulates it. The claim: an order_by entry with -nulls renders as a
# leading sort on `col` IS NULL (DESC puts the NULLs first, ASC last) followed
# by the column in its own direction -- the same row order PostgreSQL gives --
# and it holds through the limit and prefetch-subquery paths, where the
# order_by is rendered again.

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::MySQL::Storage',
);

sub sql_of {
  my ($rs) = @_;
  my ($sql, @bind) = @${ $rs->as_query };
  return $sql;
}

my $rs = $schema->resultset('Artist');

for my $case (
  [ asc  => first => '`me`.`rank` IS NULL DESC, `me`.`rank` ASC'  ],
  [ asc  => last  => '`me`.`rank` IS NULL ASC, `me`.`rank` ASC'   ],
  [ desc => first => '`me`.`rank` IS NULL DESC, `me`.`rank` DESC' ],
  [ desc => last  => '`me`.`rank` IS NULL ASC, `me`.`rank` DESC'  ],
) {
  my ($dir, $nulls, $expect) = @$case;
  is_same_sql(
    sql_of(scalar $rs->search({}, { columns => ['artistid'], order_by => { "-$dir" => 'me.rank', -nulls => $nulls } })),
    "(SELECT `me`.`artistid` FROM `artist` `me` ORDER BY $expect)",
    "$dir nulls $nulls",
  );
}

is_same_sql(
  sql_of(scalar $rs->search({}, { columns => ['artistid'], order_by => [
    { -desc => 'me.rank', -nulls => 'last' },
    { -asc  => 'me.name', -nulls => 'first' },
    'me.artistid',
  ] })),
  '(SELECT `me`.`artistid` FROM `artist` `me`
     ORDER BY `me`.`rank` IS NULL ASC, `me`.`rank` DESC,
              `me`.`name` IS NULL DESC, `me`.`name` ASC,
              `me`.`artistid`)',
  'several columns, one entry without -nulls untouched',
);

is_same_sql(
  sql_of(scalar $rs->search({}, { columns => ['artistid'], rows => 3, offset => 6,
    order_by => { -asc => 'me.rank', -nulls => 'last' } })),
  '(SELECT `me`.`artistid` FROM `artist` `me`
     ORDER BY `me`.`rank` IS NULL ASC, `me`.`rank` ASC LIMIT ?, ?)',
  'with rows and offset',
);

# prefetch of a has_many with a limit: the order_by is used by the inner
# subquery and again by the outer select
{
  my $sql = sql_of(scalar $rs->search({}, { prefetch => 'cds', rows => 2,
    order_by => { -asc => 'me.rank', -nulls => 'first' } }));
  my @o = $sql =~ m{ORDER BY `me`\.`rank` IS NULL DESC, `me`\.`rank` ASC}g;
  is scalar(@o), 2, q{prefetch subquery: the emulation is in the inner and the outer order_by};
  unlike $sql, qr/NULLS\s+(?:FIRST|LAST)/i, 'no NULLS keyword leaks through';
}

done_testing;
