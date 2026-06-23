use strict;
use warnings;

use Test::More;

use DBIO::Test ':DiffSQL';

my ($ROWS, $OFFSET) = (
   DBIO::SQLMaker::ClassicExtensions->__rows_bindtype,
   DBIO::SQLMaker::ClassicExtensions->__offset_bindtype,
);

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# non-collapsing prefetch (no multi prefetches)
{
  my $rs = $schema->resultset("CD")
            ->search_related('tracks',
                { position => [1,2] },
                { prefetch => [qw/disc lyrics/], rows => 3, offset => 8 },
            );

  my $crs = $rs->count_rs;

  is_same_sql_bind (
    $crs->as_query,
    '(SELECT COUNT( * )
       FROM (
        SELECT tracks.trackid
          FROM cd me
          JOIN track tracks ON tracks.cd = me.cdid
          JOIN cd disc ON disc.cdid = tracks.cd
        WHERE ( ( position = ? OR position = ? ) )
        LIMIT ? OFFSET ?
       ) tracks
    )',
    [
      [ { sqlt_datatype => 'int', dbic_colname => 'position' } => 1 ],
      [ { sqlt_datatype => 'int', dbic_colname => 'position' } => 2 ],
      [$ROWS => 3], [$OFFSET => 8],
    ],
    'count_rs db-side limit applied',
  );
}

# has_many prefetch with limit
{
  my $rs = $schema->resultset("Artist")
            ->search_related('cds',
                { 'tracks.position' => [1,2] },
                { prefetch => [qw/tracks artist/], rows => 3, offset => 4 },
            );

  my $crs = $rs->count_rs;

  is_same_sql_bind (
    $crs->as_query,
    '(SELECT COUNT( * )
      FROM (
        SELECT cds.cdid
          FROM artist me
          JOIN cd cds ON cds.artist = me.artistid
          LEFT JOIN track tracks ON tracks.cd = cds.cdid
          JOIN artist artist ON artist.artistid = cds.artist
        WHERE tracks.position = ? OR tracks.position = ?
        GROUP BY cds.cdid
        LIMIT ? OFFSET ?
      ) cds
    )',
    [
      [ { sqlt_datatype => 'int', dbic_colname => 'tracks.position' } => 1 ],
      [ { sqlt_datatype => 'int', dbic_colname => 'tracks.position' } => 2 ],
      [$ROWS => 3], [$OFFSET => 4],
    ],
    'count_rs db-side limit applied',
  );
}

# count with a having clause
{
  my $rs = $schema->resultset("Artist")->search(
    {},
    {
      join      => 'cds',
      group_by  => 'me.artistid',
      '+select' => [ { max => 'cds.year', -as => 'newest_cd_year' } ],
      '+as'     => ['newest_cd_year'],
      having    => { 'newest_cd_year' => '2001' }
    }
  );

  my $crs = $rs->count_rs;

  is_same_sql_bind (
    $crs->as_query,
    '(SELECT COUNT( * )
      FROM (
        SELECT me.artistid, MAX( cds.year ) AS newest_cd_year
          FROM artist me
          LEFT JOIN cd cds ON cds.artist = me.artistid
        GROUP BY me.artistid
        HAVING newest_cd_year = ?
      ) me
    )',
    [ [ { dbic_colname => 'newest_cd_year' }
          => '2001' ] ],
    'count with having clause keeps sql as alias',
  );
}

# count with two having clauses
{
  my $rs = $schema->resultset("Artist")->search(
    {},
    {
      join      => 'cds',
      group_by  => 'me.artistid',
      '+select' => [ { max => 'cds.year', -as => 'newest_cd_year' } ],
      '+as'     => ['newest_cd_year'],
      having    => { 'newest_cd_year' => [ '1998', '2001' ] }
    }
  );

  my $crs = $rs->count_rs;

  is_same_sql_bind (
    $crs->as_query,
    '(SELECT COUNT( * )
      FROM (
        SELECT me.artistid, MAX( cds.year ) AS newest_cd_year
          FROM artist me
          LEFT JOIN cd cds ON cds.artist = me.artistid
        GROUP BY me.artistid
        HAVING newest_cd_year = ? OR newest_cd_year = ?
      ) me
    )',
    [
      [ { dbic_colname => 'newest_cd_year' }
          => '1998' ],
      [ { dbic_colname => 'newest_cd_year' }
          => '2001' ],
    ],
    'count with having clause keeps sql as alias',
  );
}

done_testing;
