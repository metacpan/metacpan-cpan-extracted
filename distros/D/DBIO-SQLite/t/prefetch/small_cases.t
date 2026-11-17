use strict;
use warnings;

use Test::More;
use Test::Warn;
use Test::Deep qw(cmp_deeply);
use DBIO::SQLite::Test ':DiffSQL';

# count: counting a prefetching resultset and its related resultsets must not be skewed by joins.
subtest 'count' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $cd_rs = $schema->resultset('CD')->search (
    { 'tracks.cd' => { '!=', undef } },
    { prefetch => ['tracks', 'artist'] },
  );

  is($cd_rs->count, 5, 'CDs with tracks count');
  is($cd_rs->search_related('tracks')->count, 15, 'Tracks associated with CDs count (before SELECT()ing)');

  is($cd_rs->all, 5, 'Amount of CD objects with tracks');
  is($cd_rs->search_related('tracks')->count, 15, 'Tracks associated with CDs count (after SELECT()ing)');

  is($cd_rs->search_related ('tracks')->all, 15, 'Track objects associated with CDs (after SELECT()ing)');

  my $artist = $schema->resultset('Artist')->create({name => 'xxx'});

  my $artist_rs = $schema->resultset('Artist')->search(
    {artistid => $artist->id},
    {prefetch=>'cds', join => 'twokeys' }
  );

  is($artist_rs->count, 1, "New artist found with prefetch turned on");
  is(scalar($artist_rs->all), 1, "New artist fetched with prefetch turned on");
  is($artist_rs->related_resultset('cds')->count, 0, "No CDs counted on a brand new artist");
  is(scalar($artist_rs->related_resultset('cds')->all), 0, "No CDs fetched on a brand new artist (count == fetch)");

  # create a cd, and make sure the non-existing join does not skew the count
  $artist->create_related ('cds', { title => 'yyy', year => '1999' });
  is($artist_rs->related_resultset('cds')->count, 1, "1 CDs counted on a brand new artist");
  is(scalar($artist_rs->related_resultset('cds')->all), 1, "1 CDs prefetched on a brand new artist (count == fetch)");

  # Really fuck shit up with one more cd and some insanity
  # this doesn't quite work as there are the prefetch gets lost
  # on search_related. This however is too esoteric to fix right
  # now

  my $cd2 = $artist->create_related ('cds', {
      title => 'zzz',
      year => '1999',
      tracks => [{ title => 'ping' }, { title => 'pong' }],
  });

  my $cds = $cd2->search_related ('artist', {}, { join => 'twokeys' })
                    ->search_related ('cds');
  my $tracks = $cds->search_related ('tracks');

  is($tracks->count, 2, "2 Tracks counted on cd via artist via one of the cds");
  is(scalar($tracks->all), 2, "2 Track objects on cd via artist via one of the cds");

  is($cds->count, 2, "2 CDs counted on artist via one of the cds");
  is(scalar($cds->all), 2, "2 CD objectson artist via one of the cds");

  # make sure the join collapses all the way
  is_same_sql_bind (
    $tracks->count_rs->as_query,
    '(
      SELECT COUNT( * )
        FROM "artist" "me"
        LEFT JOIN "twokeys" "twokeys" ON "twokeys"."artist" = "me"."artistid"
        JOIN cd "cds" ON "cds"."artist" = "me"."artistid"
        JOIN "track" "tracks" ON "tracks"."cd" = "cds"."cdid"
      WHERE ( "me"."artistid" = ? )
    )',
    [ [ { sqlt_datatype => 'integer', dbic_colname => 'me.artistid' }
        => 4 ] ],
  );

  {
    local $TODO = "Chaining with prefetch is fundamentally broken";
    $schema->is_executed_querycount( sub {

      my $cds = $cd2->search_related ('artist', {}, { prefetch => { cds => 'tracks' }, join => 'twokeys' })
                    ->search_related ('cds');

      my $tracks = $cds->search_related ('tracks');

      is($tracks->count, 2, "2 Tracks counted on cd via artist via one of the cds");
      is(scalar($tracks->all), 2, "2 Tracks prefetched on cd via artist via one of the cds");
      is($tracks->count, 2, "Cached 2 Tracks counted on cd via artist via one of the cds");

      is($cds->count, 2, "2 CDs counted on artist via one of the cds");
      is(scalar($cds->all), 2, "2 CDs prefetched on artist via one of the cds");
      is($cds->count, 2, "Cached 2 CDs counted on artist via one of the cds");
    }, 3, '2 counts + 1 prefetch?' );
  }
};

# empty_cache: an empty prefetched resultset must give an empty cache on the related resultset without another query.
subtest 'empty_cache' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $queries;
  my $debugcb = sub { $queries++; };
  my $orig_debug = $schema->storage->debug;

  {
    $queries = 0;
    $schema->storage->debugcb($debugcb);
    $schema->storage->debug(1);

    my $cds_rs = $schema->resultset('CD')
      ->search(\'0 = 1', { prefetch => 'tracks', cache => 1 });

    my @cds = $cds_rs->all;
    is( $queries, 1, '->all on empty original resultset hit db' );
    is_deeply( $cds_rs->get_cache, [], 'empty cache on original resultset' );
    is( 0+@cds, 0, 'empty original resultset' );

    my $tracks_rs = $cds_rs->related_resultset('tracks');
    is_deeply( $tracks_rs->get_cache, [], 'empty cache on related resultset' );

    my @tracks = $tracks_rs->all;
    is( $queries, 1, "->all on empty related resultset didn't hit db" );
    is( 0+@tracks, 0, 'empty related resultset' );

    $schema->storage->debugcb(undef);
    $schema->storage->debug($orig_debug);
  }
};

# false_colvalues: false column values (0, empty string) must survive prefetch.
subtest 'false_colvalues' => sub {
  my $schema = DBIO::SQLite::Test->init_schema(no_populate => 1 );

  $schema->resultset('CD')->create({
    cdid => 0, title => '', year => 0, genreid => 0, single_track => 0, artist => {
      artistid => 0, name => '', rank => 0, charfield => 0,
    },
  });

  $schema->is_executed_querycount( sub {
    my $cd = $schema->resultset('CD')->search( {}, { prefetch => 'artist' })->next;

    cmp_deeply
      { $cd->get_columns },
      { artist => 0, cdid => 0, genreid => 0, single_track => 0, title => '', year => 0 },
      'Expected CD columns present',
    ;

    cmp_deeply
      { $cd->artist->get_columns },
      { artistid => 0, charfield => 0, name => "", rank => 0 },
      'Expected Artist columns present',
    ;
  }, 1, 'Only one query fired - prefetch worked' );
};

# lazy_cursor: a collapsing resultset reads its cursor lazily when ordered by its own key, and warns when it has to slurp.
# A collapsing (prefetching) resultset ordered by its own primary key reads
# the cursor lazily: ->next pulls rows only until the main row changes and
# keeps the one row it read too far. Everything behind that row stays on the
# cursor. Without a stable order of the main source it has to slurp the
# whole cursor at once, and says so.
subtest 'lazy_cursor' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $rs = $schema->resultset('Artist')->search({}, {
    select => 'artistid',
    prefetch => { cds => 'tracks' },
  });

  my @initial_artist_ids = $schema->resultset('Artist')
    ->search({}, { order_by => 'artistid' })
    ->get_column('artistid')
    ->all;
  my $initial_artists_cnt = @initial_artist_ids;

  # create one extra artist with just one cd with just one track
  # and then an artist with nothing at all
  # the implicit order by me.artistid will get them back in correct order
  my $foo_row = $rs->create({
    name => 'foo',
    cds => [{
      year => 2012,
      title => 'foocd',
      tracks => [{
        title => 'footrack',
      }]
    }],
  });
  my $bar_row = $rs->create({ name => 'bar' });
  my $baz_row = $rs->create({ name => 'baz' });

  # make sure we are reentrant, and also check with explicit order_by
  for (undef, undef, 'me.artistid') {
    $rs = $rs->search({}, { order_by => $_ }) if $_;

    for my $artist_id (@initial_artist_ids) {
      my $row = $rs->next;
      ok($row, 'Default fixture artist row available') || exit;
      is ($row->artistid, $artist_id, 'Default fixture artists in order') || exit;
    }

    # the foo artist has to come off this very resultset: reading it is what
    # makes the resultset look one row ahead, at bar, and leaves baz behind
    my $foo_artist = $rs->next;
    is (
      ($foo_artist ? $foo_artist->artistid : undef),
      $foo_row->artistid,
      'Foo artist follows the fixture artists',
    ) || exit;
    my $foo_cd = $foo_artist->cds->next;
    my $foo_track = $foo_cd && $foo_cd->tracks->next;
    is(($foo_track ? $foo_track->title : undef), 'footrack', 'Right track');

    is (
      [$rs->cursor->next]->[0],
      $baz_row->artistid,
      'Very last artist still on the cursor'
    );

    is_deeply ([$rs->cursor->next], [], 'Nothing else left');

    is ($rs->next->artistid, $bar_row->artistid, 'Row stashed in resultset still accessible');
    is ($rs->next, undef, 'Nothing left in resultset either');

    $rs->reset;
  }

  $rs->next;

  my @objs = $rs->all;
  is (@objs, $initial_artists_cnt + 3, '->all resets everything correctly');
  is ( ($rs->cursor->next)[0], 1, 'Cursor auto-rewound after all()');
  is ($rs->{_stashed_rows}, undef, 'Nothing else left in $rs stash');

  my $unordered_rs = $rs->search({}, { order_by => 'cds.title' });

  warnings_exist {
    ok ($unordered_rs->next, 'got row 1');
  } qr/performed an eager cursor slurp underneath/, 'Warned on auto-eager cursor';

  is_deeply ([$unordered_rs->cursor->next], [], 'Nothing left on cursor, eager slurp');
  ok ($unordered_rs->next, "got row $_")  for (2 .. $initial_artists_cnt + 3);
  is ($unordered_rs->next, undef, 'End of RS reached');
  is ($unordered_rs->next, undef, 'End of RS not lost');

  {
    my $non_uniquely_ordered_constrained = $schema->resultset('CD')->search(
      { artist => 1 },
      { order_by => [qw( me.genreid me.title me.year )], prefetch => 'tracks' },
    );

    isa_ok ($non_uniquely_ordered_constrained->next, 'DBIO::Test::CD' );

    ok( defined $non_uniquely_ordered_constrained->cursor->next, 'Cursor not exhausted' );
  }
};

# multiple_hasmany: prefetching several has_many on one level must run one query and warn nothing.
subtest 'multiple_hasmany' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  #( 1 -> M + M )
  my $cd_rs = $schema->resultset('CD')->search( { 'me.title' => 'Forkful of bees' } );
  my $pr_cd_rs = $cd_rs->search( {}, { prefetch => [qw/tracks tags/], } );

  my $tracks_rs    = $cd_rs->first->tracks;
  my $tracks_count = $tracks_rs->count;

  $schema->is_executed_querycount( sub {
    my $pcr = $pr_cd_rs;
    my $pr_tracks_rs;

    warnings_exist {
      $pr_tracks_rs = $pcr->first->tracks;
    } [], 'no warning on attempt to prefetch several same level has_many\'s (1 -> M + M)' ;

    is( $pr_tracks_rs->count, $tracks_count,
      'equal count of prefetched relations over several same level has_many\'s (1 -> M + M)'
    );

    is( $pr_tracks_rs->all, $tracks_count,
      'equal amount of objects returned with and without prefetch over several same level has_many\'s (1 -> M + M)'
    );

  }, 1, 'prefetch one->(has_many,has_many) ran exactly 1 query' );


  #( M -> 1 -> M + M )
  my $note_rs =
    $schema->resultset('LinerNotes')->search( { notes => 'Buy Whiskey!' } );
  my $pr_note_rs =
    $note_rs->search( {}, { prefetch => { cd => [qw/tracks tags/] }, } );

  my $tags_rs    = $note_rs->first->cd->tags;
  my $tags_count = $tags_rs->count;

  $schema->is_executed_querycount( sub {
    my $pnr = $pr_note_rs;
    my $pr_tags_rs;

    warnings_exist {
      $pr_tags_rs = $pnr->first->cd->tags;
    } [], 'no warning on attempt to prefetch several same level has_many\'s (M -> 1 -> M + M)';

    is( $pr_tags_rs->count, $tags_count,
      'equal count of prefetched relations over several same level has_many\'s (M -> 1 -> M + M)'
    );
    is( $pr_tags_rs->all, $tags_count,
      'equal amount of objects with and without prefetch over several same level has_many\'s (M -> 1 -> M + M)'
    );

  }, 1, 'prefetch one->(has_many,has_many) ran exactly 1 query' );
};

# one_to_many_to_one: prefetching a one-to-many-to-one chain must happen within one query.
subtest 'one_to_many_to_one' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $artist = $schema->resultset ('Artist')->find ({artistid => 1});
  is ($artist->cds->count, 3, 'Correct number of CDs');
  is ($artist->cds->search_related ('genre')->count, 1, 'Only one of the cds has a genre');

  $schema->is_executed_querycount( sub {
    my $pref = $schema->resultset ('Artist')
                       ->search ({ 'me.artistid' => $artist->id }, { prefetch => { cds => 'genre' } })
                        ->next;

    is ($pref->cds->count, 3, 'Correct number of CDs prefetched');
    is ($pref->cds->search_related ('genre')->count, 1, 'Only one of the prefetched cds has a prefetched genre');

  }, 1, 'All happened within one query only');
};

# refined_search_on_relation: a refined search on a prefetched relation queries, the unrefined access does not.
subtest 'refined_search_on_relation' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $art = $schema->resultset('Artist')->find(
    { 'me.artistid' => 1 },
    { prefetch => 'cds', order_by => { -desc => 'cds.year' } }
  );

  is (
    $art->cds->search({ year => 1999 })->next->year,
    1999,
    'Found expected CD with year 1999 after refined search',
  );

  is (
    $art->cds->count({ year => 1999 }),
    1,
    'Correct refined count',
  );

  # this still should emit no queries:
  $schema->is_executed_querycount( sub {

    my $cds = $art->cds;
    is (
      $cds->count,
      3,
      'Correct prefetched count',
    );

    my @years = qw(2001 1999 1997);
    while (my $cd = $cds->next) {
      is (
        $cd->year,
        (shift @years),
        'Correct prefetched cd year',
      );
    }

  }, 0, 'No queries on prefetched operations');
};

# restricted_children_set: prefetch under a restricting condition must return only the matching children.
subtest 'restricted_children_set' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $cds_rs = $schema->resultset('CD')->search(
    [
      {
        'me.title' => "Caterwaulin' Blues",
        'cds.title' => { '!=' => 'Forkful of bees' }
      },
      {
        'me.title' => { '!=', => "Caterwaulin' Blues" },
        'cds.title' => 'Forkful of bees'
      },
    ],
    {
      order_by => [qw(me.cdid cds.title)],
      prefetch => { artist => 'cds' },
      result_class => 'DBIO::ResultClass::HashRefInflator',
    },
  );

  is_deeply [ $cds_rs->all ], [
    {
      'single_track' => undef,
      'cdid' => '1',
      'artist' => {
        'cds' => [
          {
            'single_track' => undef,
            'artist' => '1',
            'cdid' => '2',
            'title' => 'Forkful of bees',
            'genreid' => undef,
            'year' => '2001'
          },
        ],
        'artistid' => '1',
        'charfield' => undef,
        'name' => 'Caterwauler McCrae',
        'rank' => '13'
      },
      'title' => 'Spoonful of bees',
      'year' => '1999',
      'genreid' => '1'
    },
    {
      'single_track' => undef,
      'cdid' => '2',
      'artist' => {
        'cds' => [
          {
            'single_track' => undef,
            'artist' => '1',
            'cdid' => '2',
            'title' => 'Forkful of bees',
            'genreid' => undef,
            'year' => '2001'
          },
        ],
        'artistid' => '1',
        'charfield' => undef,
        'name' => 'Caterwauler McCrae',
        'rank' => '13'
      },
      'title' => 'Forkful of bees',
      'year' => '2001',
      'genreid' => undef
    },
    {
      'single_track' => undef,
      'cdid' => '3',
      'artist' => {
        'cds' => [
          {
            'single_track' => undef,
            'artist' => '1',
            'cdid' => '3',
            'title' => 'Caterwaulin\' Blues',
            'genreid' => undef,
            'year' => '1997'
          },
          {
            'single_track' => undef,
            'artist' => '1',
            'cdid' => '1',
            'title' => 'Spoonful of bees',
            'genreid' => '1',
            'year' => '1999'
          }
        ],
        'artistid' => '1',
        'charfield' => undef,
        'name' => 'Caterwauler McCrae',
        'rank' => '13'
      },
      'title' => 'Caterwaulin\' Blues',
      'year' => '1997',
      'genreid' => undef
    }
  ], 'multi-level prefetch with restrictions ok';
};

done_testing;
