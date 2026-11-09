use strict;
use warnings;

use Test::More;

use DBIO::Test ':DiffSQL';

# karr k78: SQL Server has no NULLS FIRST / NULLS LAST, so the SQLMaker
# emulates it. The claim: an order_by entry with -nulls renders as a leading
# sort key CASE WHEN <expr> IS NULL THEN 0 ELSE 1 END (NULLS FIRST) or
# ... THEN 1 ELSE 0 END (NULLS LAST), always ASC, followed by the expression
# in its own direction -- the row order PostgreSQL gives -- and it holds where
# the order_by is rendered again: OVER (ORDER BY ...) of the ROW_NUMBER()
# limit, and the prefetch subquery. (The ROW_NUMBER dialect builds no reversed
# outer order; the TOP-style dialects that do are not part of this driver.)
# Without the emulation the keyword NULLS reaches the server (a syntax error).

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::MSSQL::Storage',
);

sub sql_of {
  my ($rs) = @_;
  # an ordered subselect is only legal with TOP: unsafe_subselect_ok lets the
  # storage add it (SELECT TOP 2147483647), which is not what is under test
  my ($sql, @bind) = @${ $rs->search({}, { unsafe_subselect_ok => 1 })->as_query };
  $sql =~ s/\bTOP 2147483647 //g;
  return $sql;
}

my $rs = $schema->resultset('Artist');

my $first = sub { "CASE WHEN $_[0] IS NULL THEN 0 ELSE 1 END ASC" };
my $last  = sub { "CASE WHEN $_[0] IS NULL THEN 1 ELSE 0 END ASC" };
my $rank  = '[me].[rank]';

for my $case (
  [ asc  => first => $first->($rank) . ", $rank ASC"  ],
  [ asc  => last  => $last->($rank)  . ", $rank ASC"  ],
  [ desc => first => $first->($rank) . ", $rank DESC" ],
  [ desc => last  => $last->($rank)  . ", $rank DESC" ],
) {
  my ($dir, $nulls, $expect) = @$case;
  is_same_sql(
    sql_of(scalar $rs->search({}, { columns => ['artistid'], order_by => { "-$dir" => 'me.rank', -nulls => $nulls } })),
    "(SELECT [me].[artistid] FROM [artist] [me] ORDER BY $expect)",
    "$dir nulls $nulls",
  );
}

is_same_sql(
  sql_of(scalar $rs->search({}, { columns => ['artistid'], order_by => [
    { -desc => 'me.rank', -nulls => 'last' },
    { -asc  => 'me.name', -nulls => 'first' },
    'me.artistid',
  ] })),
  '(SELECT [me].[artistid] FROM [artist] [me]
     ORDER BY ' . $last->($rank) . ", $rank DESC, "
              . $first->('[me].[name]') . ', [me].[name] ASC, [me].[artistid])',
  'several columns, one entry without -nulls untouched',
);

# rows + offset: ROW_NUMBER() OVER (ORDER BY ...) carries the emulation (as two
# sort keys: the dialect selects every sort key into the inner query). This
# dialect has no reversed middle/outer order, so there is nothing to mirror.
{
  my $sql = sql_of(scalar $rs->search({}, { columns => ['artistid'], rows => 3, offset => 6,
    order_by => { -asc => 'me.rank', -nulls => 'last' } }));
  unlike $sql, qr/NULLS\s+(?:FIRST|LAST)/i, 'rows+offset: no NULLS keyword';
  # the order criteria are selected into the inner query and ordered by alias:
  # the NULL key first (ASC), the column in its own direction
  like $sql, qr/CASE WHEN \[me\]\.\[rank\] IS NULL THEN 1 ELSE 0 END AS \[ORDER__BY__001\], \[me\]\.\[rank\] AS \[ORDER__BY__002\]/,
    'rows+offset: both sort keys are selected into the inner query' or diag $sql;
  like $sql, qr/OVER\s*\(\s*ORDER BY \[ORDER__BY__001\] ASC, \[ORDER__BY__002\] ASC\s*\)/i,
    'rows+offset: inside OVER (ORDER BY ...)' or diag $sql;
  diag $sql if $ENV{DBIO_TEST_SHOW_SQL};
}

# a limit without offset
{
  my $sql = sql_of(scalar $rs->search({}, { columns => ['artistid'], rows => 3,
    order_by => { -desc => 'me.rank', -nulls => 'first' } }));
  like $sql, qr/CASE WHEN \[me\]\.\[rank\] IS NULL THEN 0 ELSE 1 END AS \[ORDER__BY__001\], \[me\]\.\[rank\] AS \[ORDER__BY__002\]/,
    'rows only: both sort keys are selected into the inner query' or diag $sql;
  like $sql, qr/OVER\s*\(\s*ORDER BY \[ORDER__BY__001\] ASC, \[ORDER__BY__002\] DESC\s*\)/i,
    'rows only: inside OVER (ORDER BY ...)' or diag $sql;
  unlike $sql, qr/NULLS\s+(?:FIRST|LAST)/i, 'rows only: no NULLS keyword';
}

# prefetch of a has_many with a limit: inner subquery and outer select
{
  my $sql = sql_of(scalar $rs->search({}, { prefetch => 'cds', rows => 2,
    order_by => { -asc => 'me.rank', -nulls => 'first' } }));
  unlike $sql, qr/NULLS\s+(?:FIRST|LAST)/i, 'prefetch: no NULLS keyword leaks through';
  like $sql, qr/CASE WHEN \[me\]\.\[rank\] IS NULL THEN 0 ELSE 1 END AS \[ORDER__BY__001\]/,
    'prefetch subquery: the emulation is in the inner (limited) query';
  like $sql, qr/OVER\s*\(\s*ORDER BY \[ORDER__BY__001\] ASC, \[me\]\.\[rank\] ASC\s*\)/i,
    'prefetch subquery: ordered by the NULL key, then the (already selected) column, inside OVER';
  like $sql, qr/\) \[me\] LEFT JOIN .* ORDER BY CASE WHEN \[me\]\.\[rank\] IS NULL THEN 0 ELSE 1 END ASC, \[me\]\.\[rank\] ASC\)\z/s,
    'prefetch: the outer order_by carries the emulation too' or diag $sql;
}

done_testing;
