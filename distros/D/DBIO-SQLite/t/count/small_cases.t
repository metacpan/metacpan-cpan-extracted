use strict;
use warnings;

use Test::More;
use DBIO::Test::Slow;
use Test::Exception;
use DBIO::SQLite::Test ':DiffSQL';

# Each subtest was a file of its own; every one builds its own schema.

# WHY: grouping by a function alias must count the groups, not the rows.
subtest 'group_by_func' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $rs = $schema->resultset ('CD')->search ({}, {
    select => [
      { substr => [ 'title', 1, 1 ], -as => 'initial' },
      { count => '*' },
    ],
    as => [qw/title_initial cnt/],
    group_by => ['initial'],
    order_by => { -desc => 'initial' },
    result_class => 'DBIO::ResultClass::HashRefInflator',
  });

  is_deeply (
    [$rs->all],
    [
      { title_initial => 'S', cnt => '1' },
      { title_initial => 'G', cnt => '1' },
      { title_initial => 'F', cnt => '1' },
      { title_initial => 'C', cnt => '2' },
    ],
    'Correct result',
  );

  is ($rs->count, 4, 'Correct count');

  done_testing;
};

# WHY: a pager over a grouped resultset must count groups.
subtest 'grouped_pager' => sub {
  plan tests => 7;

  my $schema = DBIO::SQLite::Test->init_schema();

  # add 2 extra artists
  $schema->populate ('Artist', [
      [qw/name/],
      [qw/ar_1/],
      [qw/ar_2/],
  ]);

  # add 3 extra cds to every artist
  for my $ar ($schema->resultset ('Artist')->all) {
    for my $cdnum (1 .. 3) {
      $ar->create_related ('cds', {
        title => "bogon $cdnum",
        year => 2000 + $cdnum,
      });
    }
  }

  my $cds = $schema->resultset ('CD')->search ({}, { group_by => 'artist' } );
  is ($cds->count, 5, 'Resultset collapses to 5 groups');

  my ($pg1, $pg2, $pg3) = map { $cds->search_rs ({}, {rows => 2, page => $_}) } (1..3);

  for ($pg1, $pg2, $pg3) {
    is ($_->pager->total_entries, 5, 'Total count via pager correct');
  }

  is ($pg1->count, 2, 'First page has 2 groups');
  is ($pg2->count, 2, 'Second page has 2 groups');
  is ($pg3->count, 1, 'Third page has one group remaining');
};

# WHY: a subselect on the primary key must match the row count of its source resultset.
subtest 'in_subquery' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  {
      my $rs = $schema->resultset("CD")->search(
          { 'artist.name' => 'Caterwauler McCrae' },
          { join => [qw/artist/]}
      );
      my $squery = $rs->get_column('cdid')->as_query;
      my $subsel_rs = $schema->resultset("CD")->search( { cdid => { IN => $squery } } );
      is($subsel_rs->count, $rs->count, 'Subselect on PK got the same row count');
  }

  done_testing;
};

# WHY: count and fetched object count must agree for joins that multiply rows.
subtest 'joined' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $cds = $schema->resultset("CD")->search({ cdid => 1 }, { join => { cd_to_producer => 'producer' } });
  cmp_ok($cds->count, '>', 1, "extra joins explode entity count");

  for my $arg (
    [ 'prefetch-collapsed has_many' => { prefetch => 'cd_to_producer' } ],
    [ 'distict-collapsed result' => { distinct => 1 } ],
    [ 'explicit collapse request' => { collapse => 1 } ],
  ) {
    for my $hri (0,1) {
      my $diag = $arg->[0] . ($hri ? ' with HRI' : '');

      my $rs = $cds->search({}, {
        %{$arg->[1]},
        $hri ? ( result_class => 'DBIO::ResultClass::HashRefInflator' ) : (),
      });

      is
        $rs->count,
        1,
        "Count correct on $diag",
      ;

      is
        scalar $rs->all,
        1,
        "Amount of constructed objects matches count on $diag",
      ;
    }
  }

  # JOIN and LEFT JOIN issues mean that we've seen problems where counted rows and fetched rows are sometimes 1 higher than they should
  # be in the related resultset.
  my $artist=$schema->resultset('Artist')->create({name => 'xxx'});
  is($artist->related_resultset('cds')->count(), 0, "No CDs found for a shiny new artist");
  is(scalar($artist->related_resultset('cds')->all()), 0, "No CDs fetched for a shiny new artist");

  my $artist_rs = $schema->resultset('Artist')->search({artistid => $artist->id});
  is($artist_rs->related_resultset('cds')->count(), 0, "No CDs counted for a shiny new artist using a resultset search");
  is(scalar($artist_rs->related_resultset('cds')->all), 0, "No CDs fetched for a shiny new artist using a resultset search");

  done_testing;
};

# WHY: count_rs of a prefetching resultset must collapse to the right SQL and number.
subtest 'prefetch' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  # collapsing prefetch
  {
    my $rs = $schema->resultset("Artist")
              ->search_related('cds',
                  { 'tracks.position' => [1,2] },
                  { prefetch => [qw/tracks artist/] },
              );
    is ($rs->all, 5, 'Correct number of objects');
    is ($rs->count, 5, 'Correct count');

    is_same_sql_bind (
      $rs->count_rs->as_query,
      '(
        SELECT COUNT( * )
          FROM (
            SELECT "cds"."cdid"
              FROM "artist" "me"
              JOIN cd "cds" ON "cds"."artist" = "me"."artistid"
              LEFT JOIN "track" "tracks" ON "tracks"."cd" = "cds"."cdid"
              JOIN "artist" "artist" ON "artist"."artistid" = "cds"."artist"
            WHERE "tracks"."position" = ? OR "tracks"."position" = ?
            GROUP BY "cds"."cdid"
          ) "cds"
      )',
      [ map { [ { sqlt_datatype => 'int', dbic_colname => 'tracks.position' } => $_ ] } (1, 2) ],
    );
  }

  # collapsing prefetch with distinct
  {
    my $rs = $schema->resultset("Artist")->search(undef, {distinct => 1})
              ->search_related('cds')->search_related('genre',
                  { 'genre.name' => 'emo' },
                  { prefetch => q(cds) },
              );
    is ($rs->all, 1, 'Correct number of objects');
    is ($rs->count, 1, 'Correct count');

    is_same_sql_bind (
      $rs->count_rs->as_query,
      '(
        SELECT COUNT( * )
          FROM (
            SELECT "genre"."genreid"
              FROM (
                SELECT "me"."artistid", "me"."name", "me"."rank", "me"."charfield"
                  FROM "artist" "me"
                GROUP BY "me"."artistid", "me"."name", "me"."rank", "me"."charfield"
              ) "me"
              JOIN cd "cds" ON "cds"."artist" = "me"."artistid"
              JOIN "genre" "genre" ON "genre"."genreid" = "cds"."genreid"
            WHERE ( "genre"."name" = ? )
            GROUP BY "genre"."genreid"
          )
        "genre"
      )',
      [ [ { sqlt_datatype => 'varchar', sqlt_size => 100, dbic_colname =>  'genre.name' }
          => 'emo' ]
      ],
    );
  }

  # non-collapsing prefetch (no multi prefetches)
  {
    my $rs = $schema->resultset("CD")
              ->search_related('tracks',
                  { position => [1,2], 'lyrics.lyric_id' => undef },
                  { prefetch => [qw/disc lyrics/] },
              );
    is ($rs->all, 10, 'Correct number of objects');


    is ($rs->count, 10, 'Correct count');

    is_same_sql_bind (
      $rs->count_rs->as_query,
      '(
        SELECT COUNT( * )
          FROM cd "me"
          JOIN "track" "tracks" ON "tracks"."cd" = "me"."cdid"
          JOIN cd "disc" ON "disc"."cdid" = "tracks"."cd"
          LEFT JOIN "lyrics" "lyrics" ON "lyrics"."track_id" = "tracks"."trackid"
        WHERE "lyrics"."lyric_id" IS NULL AND ("position" = ? OR "position" = ?)
      )',
      [ map { [ { sqlt_datatype => 'int', dbic_colname => 'position' } => $_ ] } (1, 2) ],
    );
  }

  done_testing;
};

# WHY: counts chained off a limited or grouped resultset must match fetched objects.
subtest 'search_related' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();
  my $cd_rs = $schema->resultset('CD')->search ({}, { rows => 1, order_by => 'cdid' });

  my $track_count = $cd_rs->first->tracks->count;

  cmp_ok ($track_count, '>', 1, 'First CD has several tracks');

  is ($cd_rs->search_related ('tracks')->count, $track_count, 'related->count returns correct number chained off a limited rs');
  is (scalar ($cd_rs->search_related ('tracks')->all), $track_count, 'related->all returns correct number of objects chained off a limited rs');


  my $joined_cd_rs = $cd_rs->search ({}, {
    join => 'tracks', rows => 2, distinct => 1, having => \ 'count(tracks.trackid) > 2',
  });

  my $multiple_track_count = $schema->resultset('Track')->search ({
    cd => { -in => $joined_cd_rs->get_column ('cdid')->as_query }
  })->count;


  is (
    $joined_cd_rs->search_related ('tracks')->count,
    $multiple_track_count,
    'related->count returns correct number chained off a grouped rs',
  );
  is (
    scalar ($joined_cd_rs->search_related ('tracks')->all),
    $multiple_track_count,
    'related->all returns correct number of objects chained off a grouped rs',
  );

  done_testing;
};

done_testing;
