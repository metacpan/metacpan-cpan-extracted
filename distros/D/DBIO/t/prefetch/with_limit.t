# Test SQL generation for prefetch with LIMIT.
use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test ':DiffSQL';

my $ROWS = DBIO::SQLMaker::ClassicExtensions->__rows_bindtype;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my $no_prefetch = $schema->resultset('Artist')->search(
  [   # search deliberately contrived
    { 'artwork.cd_id' => undef },
    { 'tracks.title' => { '!=' => 'blah-blah-1234568' }}
  ],
  { rows => 3, join => { cds => [qw/artwork tracks/] },
 }
);

my $use_prefetch = $no_prefetch->search(
  {},
  {
    select => ['me.artistid', 'me.name'],
    as => ['artistid', 'name'],
    prefetch => 'cds',
    order_by => { -desc => 'name' },
  }
);

# add an extra +select to make sure it does not throw things off
$use_prefetch = $use_prefetch->search({}, {
  '+columns' => { monkeywrench => \[ 'me.artistid + ?', [ \ 'inTEger' => 1 ] ] },
});

my $bind_int_resolved = sub { [ { sqlt_datatype => 'inTEger' } => 1 ] };
my $bind_vc_resolved = sub { [
  { sqlt_datatype => 'varchar', sqlt_size => 100, dbic_colname => 'tracks.title' }
    => 'blah-blah-1234568'
] };
is_same_sql_bind (
  $use_prefetch->as_query,
  '(
    SELECT  me.artistid + ?,
            me.artistid, me.name,
            cds.cdid, cds.artist, cds.title, cds.year, cds.genreid, cds.single_track
      FROM (
        SELECT me.artistid + ?,
               me.artistid, me.name
          FROM artist me
          LEFT JOIN cd cds
            ON cds.artist = me.artistid
          LEFT JOIN cd_artwork artwork
            ON artwork.cd_id = cds.cdid
          LEFT JOIN track tracks
            ON tracks.cd = cds.cdid
        WHERE   artwork.cd_id IS NULL
             OR tracks.title != ?
        GROUP BY me.artistid + ?, me.artistid, me.name
        ORDER BY name DESC LIMIT ?
      ) me
      LEFT JOIN cd cds
        ON cds.artist = me.artistid
      LEFT JOIN cd_artwork artwork
        ON artwork.cd_id = cds.cdid
      LEFT JOIN track tracks
        ON tracks.cd = cds.cdid
    WHERE artwork.cd_id IS NULL
       OR tracks.title != ?
    ORDER BY name DESC
  )',
  [
    $bind_int_resolved->(),  # outer select
    $bind_int_resolved->(),  # inner select
    $bind_vc_resolved->(), # inner where
    $bind_int_resolved->(),  # inner group_by
    [ $ROWS => 3 ],
    $bind_vc_resolved->(), # outer where
  ],
  'Expected SQL on complex limited prefetch'
);

lives_ok (
  sub {
    $use_prefetch->search(
      {'tracks.title' => { '!=' => 'foo' }},
      { order_by => \ 'some oddball literal sql', join => { cds => 'tracks' } }
    )->next
  }, 'Literal SQL order_by no longer throws while deriving required group_by',
);

# make sure 1:1 joins do not force a subquery (no point to exercise the optimizer, if at all available)
my $single_prefetch_rs = $schema->resultset ('CD')->search (
  { 'me.year' => 2010, 'artist.name' => 'foo' },
  { prefetch => ['tracks', 'artist'], rows => 15 },
);
is_same_sql_bind (
  $single_prefetch_rs->as_query,
  '(
    SELECT
        me.cdid, me.artist, me.title, me.year, me.genreid, me.single_track,
        tracks.trackid, tracks.cd, tracks.position, tracks.title, tracks.last_updated_on, tracks.last_updated_at,
        artist.artistid, artist.name, artist.rank, artist.charfield
      FROM (
        SELECT
            me.cdid, me.artist, me.title, me.year, me.genreid, me.single_track
          FROM cd me
          JOIN artist artist ON artist.artistid = me.artist
        WHERE ( ( artist.name = ? AND me.year = ? ) )
        LIMIT ?
      ) me
      LEFT JOIN track tracks
        ON tracks.cd = me.cdid
      JOIN artist artist
        ON artist.artistid = me.artist
    WHERE ( ( artist.name = ? AND me.year = ? ) )
  )',
  [
    [ { sqlt_datatype => 'varchar', sqlt_size => 100, dbic_colname => 'artist.name' } => 'foo' ],
    [ { sqlt_datatype => 'varchar', sqlt_size => 100, dbic_colname => 'me.year' } => 2010 ],
    [ $ROWS         => 15    ],
    [ { sqlt_datatype => 'varchar', sqlt_size => 100, dbic_colname => 'artist.name' } => 'foo' ],
    [ { sqlt_datatype => 'varchar', sqlt_size => 100, dbic_colname => 'me.year' } => 2010 ],
  ],
  'No grouping of non-multiplying resultsets',
);

my $many_one_many_rs = $schema->resultset('CD')->search({}, {
  prefetch => { tracks => { lyrics => 'lyric_versions' } },
  rows => 2,
  order_by => ['lyrics.track_id'],
});

is_same_sql_bind(
  $many_one_many_rs->as_query,
  '(
    SELECT  me.cdid, me.artist, me.title, me.year, me.genreid, me.single_track,
            tracks.trackid, tracks.cd, tracks.position, tracks.title, tracks.last_updated_on, tracks.last_updated_at,
            lyrics.lyric_id, lyrics.track_id, lyric_versions.id, lyric_versions.lyric_id, lyric_versions.text
      FROM (
        SELECT me.cdid, me.artist, me.title, me.year, me.genreid, me.single_track
          FROM cd me
          LEFT JOIN track tracks
            ON tracks.cd = me.cdid
          LEFT JOIN lyrics lyrics
            ON lyrics.track_id = tracks.trackid
        GROUP BY me.cdid, me.artist, me.title, me.year, me.genreid, me.single_track
        ORDER BY MIN(lyrics.track_id)
        LIMIT ?
      ) me
      LEFT JOIN track tracks
        ON tracks.cd = me.cdid
      LEFT JOIN lyrics lyrics
        ON lyrics.track_id = tracks.trackid
      LEFT JOIN lyric_versions lyric_versions
        ON lyric_versions.lyric_id = lyrics.lyric_id
    ORDER BY lyrics.track_id
  )',
  [
    [ { sqlt_datatype => 'integer' } => 2 ]
  ],
  'Correct SQL on indirectly multiplied orderer',
);

my $cond_on_multi_ord_by_single = $schema->resultset('CD')->search(
  {
    'tracks.position' => { '!=', 1 },
  },
  {
    prefetch => [qw( tracks artist )],
    order_by => 'artist.name',
    rows => 1,
  },
);

is_same_sql_bind(
  $cond_on_multi_ord_by_single->as_query,
  '(
    SELECT  me.cdid, me.artist, me.title, me.year, me.genreid, me.single_track,
            tracks.trackid, tracks.cd, tracks.position, tracks.title, tracks.last_updated_on, tracks.last_updated_at,
            artist.artistid, artist.name, artist.rank, artist.charfield
      FROM (
        SELECT me.cdid, me.artist, me.title, me.year, me.genreid, me.single_track
          FROM cd me
          LEFT JOIN track tracks
            ON tracks.cd = me.cdid
          JOIN artist artist
            ON artist.artistid = me.artist
        WHERE tracks.position != ?
        GROUP BY me.cdid, me.artist, me.title, me.year, me.genreid, me.single_track, artist.name
        ORDER BY artist.name
        LIMIT ?
      ) me
      LEFT JOIN track tracks
        ON tracks.cd = me.cdid
      JOIN artist artist
        ON artist.artistid = me.artist
    WHERE tracks.position != ?
    ORDER BY artist.name
  )',
  [
    [ { dbic_colname => "tracks.position", sqlt_datatype => "int" }
      => 1
    ],
    [ { sqlt_datatype => "integer" }
      => 1
    ],
    [ { dbic_colname => "tracks.position", sqlt_datatype => "int" }
      => 1
    ],
  ],
  'Correct SQl on prefetch with limit of restricting multi ordered by a single'
);

done_testing;
