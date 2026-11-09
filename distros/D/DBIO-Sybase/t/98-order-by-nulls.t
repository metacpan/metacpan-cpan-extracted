use strict;
use warnings;

use Test::More;

use DBIO::Test ':DiffSQL';

# karr k95: ASE has no NULLS FIRST / NULLS LAST, so the SQLMaker emulates it.
# The claim: an order_by entry with -nulls renders as a leading sort on a CASE
# that is 0 for the NULLs (first) or 1 (last), followed by the column in its
# own direction -- the row order PostgreSQL gives -- and it holds through the
# limit (GenericSubQ) and prefetch-subquery paths, where the order_by is
# rendered again.

my $schema = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::Sybase::Storage::ASE',
  quote_names  => 1,
);
$schema->storage->sql_maker;

sub sql_of {
  my ($rs) = @_;
  my ($sql, @bind) = @${ $rs->as_query };
  return $sql;
}

my $rs = $schema->resultset('Artist');

for my $case (
  [ asc  => first => 'CASE WHEN [me].[rank] IS NULL THEN 0 ELSE 1 END, [me].[rank] ASC'  ],
  [ asc  => last  => 'CASE WHEN [me].[rank] IS NULL THEN 1 ELSE 0 END, [me].[rank] ASC'  ],
  [ desc => first => 'CASE WHEN [me].[rank] IS NULL THEN 0 ELSE 1 END, [me].[rank] DESC' ],
  [ desc => last  => 'CASE WHEN [me].[rank] IS NULL THEN 1 ELSE 0 END, [me].[rank] DESC' ],
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
     ORDER BY CASE WHEN [me].[rank] IS NULL THEN 1 ELSE 0 END, [me].[rank] DESC,
              CASE WHEN [me].[name] IS NULL THEN 0 ELSE 1 END, [me].[name] ASC,
              [me].[artistid])',
  'several columns, one entry without -nulls untouched',
);

# a bind inside the expression is bound twice, in order
{
  my (undef, @bind) = @${ $rs->search({}, { columns => ['artistid'],
    order_by => { -asc => \[ 'COALESCE(me.rank, ?)', 7 ], -nulls => 'first' } })->as_query };
  is scalar(@bind), 2, 'a bind in the sort expression is bound twice';
  is_deeply [ map $_->[1], @bind ], [ 7, 7 ], '... with the same value, in order';
}

# rows and offset: GenericSubQ renders the order_by again
{
  my $sql = sql_of(scalar $rs->search({}, { columns => ['artistid'], rows => 3, offset => 6,
    order_by => [ { -asc => 'me.rank', -nulls => 'last' }, 'me.artistid' ] }));
  like $sql, qr/ORDER BY CASE WHEN \[me\]\.\[rank\] IS NULL THEN 1 ELSE 0 END, \[me\]\.\[rank\] ASC, \[me\]\.\[artistid\] ASC/, 'with rows and offset: the outer order_by carries the CASE emulation';
  unlike $sql, qr/NULLS\s+(?:FIRST|LAST)/i, 'with rows and offset: no NULLS keyword leaks through';
}

# a nullable column: GenericSubQ takes the rendered chunks apart as strings,
# so the emulation must not be in the way there (it is the case that died
# "can not work with order criteria based on sources other than the main one")
{
  my $sql = sql_of(scalar $rs->search({}, { columns => ['artistid'], rows => 3, offset => 6,
    order_by => [ { -desc => 'me.charfield', -nulls => 'first' }, 'me.artistid' ] }));
  like $sql, qr/ORDER BY CASE WHEN \[me\]\.\[charfield\] IS NULL THEN 0 ELSE 1 END, \[me\]\.\[charfield\] DESC, \[me\]\.\[artistid\] ASC/,
    'nullable column with rows and offset: the outer order_by carries the CASE emulation';
  unlike $sql, qr/NULLS\s+(?:FIRST|LAST)/i, 'nullable column with rows and offset: no NULLS keyword leaks through';
}

# prefetch of a has_many with a limit
{
  my $sql = sql_of(scalar $rs->search({}, { prefetch => 'cds', rows => 2,
    order_by => [ { -asc => 'me.rank', -nulls => 'first' }, 'me.artistid' ] }));
  unlike $sql, qr/NULLS\s+(?:FIRST|LAST)/i, 'prefetch with limit: no NULLS keyword leaks through';
  like $sql, qr/CASE WHEN .*IS NULL THEN 0 ELSE 1 END/s, 'prefetch with limit: CASE emulation present';
}

done_testing;
