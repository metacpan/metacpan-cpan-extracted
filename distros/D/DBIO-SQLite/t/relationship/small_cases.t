use strict;
use warnings;

use Test::More;
use DBIO::Test::Slow;
use Test::Exception;
use DBIO::SQLite::Test;

# after_update: a relationship changed by id must not keep serving the old cached related resultset.
subtest 'after_update' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  plan tests => 2;

  my $bookmark = $schema->resultset("Bookmark")->find(1);
  my $link = $bookmark->link;
  my $link_id = $link->id;

  my $new_link = $schema->resultset("Link")->new({
      id      => 42,
      url     => "http://monstersarereal.com",
      title   => "monstersarereal.com"
  });

  # Changing a relationship by id rather than by object would cause
  # old related_resultsets to be used.
  $bookmark->link($new_link->id);
  is $bookmark->link->id, $new_link->id;

  $bookmark->update;
  is $bookmark->link->id, $new_link->id;
};

# custom_opaque: a custom (coderef) relationship whose condition is opaque still yields the expected join SQL.
subtest 'custom_opaque' => sub {
  my $schema = DBIO::SQLite::Test->init_schema(no_populate => 1, quote_names => 1 );

  $schema->resultset('CD')->create({
    title => 'Equinoxe',
    year => 1978,
    artist => { name => 'JMJ' },
    genre => { name => 'electro' },
    tracks => [
      { title => 'e1' },
      { title => 'e2' },
      { title => 'e3' },
    ],
    single_track => {
      title => 'o1',
      cd => {
        title => 'Oxygene',
        year => 1976,
        artist => { name => 'JMJ' },
      },
    },
  });

  my $cd = $schema->resultset('CD')->search({ single_track => { '!=', undef } })->first;

  $schema->is_executed_sql_bind(
    sub { is( eval{$cd->single_track_opaque->title}, 'o1', 'Found correct single track' ) },
    [
      [
        'SELECT "me"."trackid", "me"."cd", "me"."position", "me"."title", "me"."last_updated_on", "me"."last_updated_at"
            FROM cd "cd__row"
            JOIN "track" "me"
              ON me.trackid = cd__row.single_track
          WHERE "cd__row"."cdid" = ?
        ',
        [
          { dbic_colname => "cd__row.cdid", sqlt_datatype => "integer" }
            => 2
        ]
      ],
    ],
  );
};

# custom_with_null_in_cond: a custom relationship with an undef in its condition must still resolve through search_related.
subtest 'custom_with_null_in_cond' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $artist_rs = $schema->resultset('Artist');

  for my $rel_rs(
    $artist_rs->search_related_rs(
      cds_without_genre => { artist => 1 }, { order_by => 'cdid' }
    ),
    $artist_rs->find(1)->search_related_rs(
      cds_without_genre => {}, { order_by => 'cdid' }
    ),
  ) {

    is_deeply(
      $rel_rs->all_hri,
      [
        {
          artist => 1,
          cdid => 2,
          genreid => undef,
          single_track => undef,
          title => "Forkful of bees",
          year => 2001
        },
        {
          artist => 1,
          cdid => 3,
          genreid => undef,
          single_track => undef,
          title => "Caterwaulin' Blues",
          year => 1997
        },
      ]
    );
  }
};

# doesnt_exist: the belongs_to accessor must not create a row when the related row is gone.
subtest 'doesnt_exist' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  plan tests => 3;

  my $bookmark = $schema->resultset("Bookmark")->find(1);
  my $link = $bookmark->link;
  my $link_id = $link->id;
  ok $link->id;

  $link->delete;
  is $schema->resultset("Link")->search({id => $link_id})->count, 0,
      "link $link_id was deleted";

  # Get a fresh object with nothing cached
  $bookmark = $schema->resultset("Bookmark")->find($bookmark->id);

  # This would create a new link row if none existed
  $bookmark->link;

  is $schema->resultset("Link")->search({id => $link_id})->count, 0,
      'accessor did not create a link object where there was none';
};

# proxy: proxied relationship accessors must return the related values, and invalid proxy specs must be refused.
subtest 'proxy' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $cd = $schema->resultset('CD')->find(2);
  is($cd->notes, $cd->liner_notes->notes, 'notes proxy ok');
  is($cd->artist_name, $cd->artist->name, 'artist_name proxy ok');

  my $track = $cd->tracks->first;
  is($track->cd_title, $track->cd->title, 'cd_title proxy ok');
  is($track->cd_title, $cd->title, 'cd_title proxy II ok');
  is($track->year, $cd->year, 'year proxy ok');

  my $tag = $schema->resultset('Tag')->first;
  is($tag->year, $tag->cd->year, 'year proxy II ok');
  is($tag->cd_title, $tag->cd->title, 'cd_title proxy III ok');

  my $bookmark = $schema->resultset('Bookmark')->create ({
    link => { url => 'http://cpan.org', title => 'CPAN' },
  });
  my $link = $bookmark->link;
  ok($bookmark->link_id == $link->id, 'link_id proxy ok');
  is($bookmark->link_url, $link->url, 'link_url proxy ok');
  is($bookmark->link_title, $link->title, 'link_title proxy ok');

  my $cd_source_class = $schema->class('CD');
  throws_ok {
      $cd_source_class->add_relationship('artist_regex',
          'DBIO::Test::Schema::Artist', {
              'foreign.artistid' => 'self.artist'
          }, { proxy => qr/\w+/ }
      ) } qr/unable \s to \s process \s the \s \'proxy\' \s argument/ix,
      'proxy attr with a regex ok';
  throws_ok {
      $cd_source_class->add_relationship('artist_sub',
          'DBIO::Test::Schema::Artist', {
              'foreign.artistid' => 'self.artist'
          }, { proxy => sub {} }
      ) } qr/unable \s to \s process \s the \s \'proxy\' \s argument/ix,
      'proxy attr with a sub ok';
};

# set_column_on_fk: setting a foreign key column or the relationship must re-select the right related object, for relname == colname and !=.
subtest 'set_column_on_fk' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();


  # test with relname == colname
  my $bookmark = $schema->resultset("Bookmark")->find(1);
  ok( $bookmark->has_column ('link'), 'Right column name' );
  ok( $bookmark->has_relationship ('link'), 'Right rel name' );

  my $link = $bookmark->link;

  my $new_link = $schema->resultset("Link")->create({
    url     => "http://bugsarereal.com",
    title   => "bugsarereal.com",
    id      => 9,
  });

  is( $bookmark->link->id, 1, 'Initial relation id' );

  $bookmark->set_column( 'link', 9 );
  is( $bookmark->link->id, 9, 'Correct object re-selected after belongs_to set' );

  $bookmark->discard_changes;
  is( $bookmark->link->id, 1, 'Pulled the correct old object after belongs_to reset' );


  $bookmark->link($new_link);
  is( $bookmark->get_column('link'), 9, 'Correct column set from related' );

  $bookmark->discard_changes;
  is( $bookmark->link->id, 1, 'Pulled the correct old object after belongs_to reset' );


  $bookmark->link(9);
  is( $bookmark->link->id, 9, 'Correct object selected on deflated accessor set');

  $bookmark->discard_changes;
  is( $bookmark->link->id, 1, 'Pulled the correct old object after belongs_to reset' );


  $bookmark->update({ link => 9 });
  is( $bookmark->link->id, 9, 'Correct relationship after update' );
  is( $bookmark->get_from_storage->link->id, 9, 'Correct relationship after re-select' );


  # test with relname != colname
  my $lyric = $schema->resultset('Lyrics')->create({ track_id => 5 });
  is( $lyric->track->id, 5, 'Initial relation id');

  $lyric->track_id(6);
  my $track6 = $lyric->track;
  is( $track6->trackid, 6, 'Correct object re-selected after belongs_to set');

  $lyric->discard_changes;
  is( $lyric->track->trackid, 5, 'Pulled the correct old rel object after belongs_to reset');

  $lyric->track($track6);
  is( $lyric->track_id, 6, 'Correct column set from related');

  $lyric->discard_changes;
  is( $lyric->track->trackid, 5, 'Pulled the correct old rel object after belongs_to reset');

  $lyric->update({ track => $track6 });
  is( $lyric->track->trackid, 6, 'Correct relationship obj after update' );
  is( $lyric->get_from_storage->track->trackid, 6, 'Correct relationship after re-select' );
};

# unresolvable: a relationship that needs a column not loaded from storage must fail loudly.
subtest 'unresolvable' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $cd = $schema->resultset('CD')->search ({}, { columns => ['year'], rows => 1 })->single;


  throws_ok (
    sub { $cd->tracks },
    qr/Unable to resolve relationship .+ column .+ not loaded from storage/,
    'Correct exception on nonresolvable object-based condition'
  );
};

# update_or_create_multi: update_or_create_related on a has_many needs a complete unique constraint and issues the expected SQL.
subtest 'update_or_create_multi' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $artist = $schema->resultset ('Artist')->find(1);

  my $genre = $schema->resultset ('Genre')
              ->create ({ name => 'par excellence' });
  my $genre_cds = $genre->cds;

  is ($genre_cds->count, 0, 'No cds yet');

  # expect a create
  $genre->update_or_create_related ('cds', {
    artist => $artist,
    year => 2009,
    title => 'the best thing since sliced bread',
  });

  # verify cd was inserted ok
  is ($genre_cds->count, 1, 'One cd');
  my $cd = $genre_cds->first;
  is_deeply (
    { map { $_, $cd->get_column ($_) } qw/artist year title/ },
    {
      artist => $artist->id,
      year => 2009,
      title => 'the best thing since sliced bread',
    },
    'CD created correctly',
  );

  # expect a year update on the only related row
  # (non-qunique column + unique column set as disambiguator)
  $genre->update_or_create_related ('cds', {
    year => 2010,
    title => 'the best thing since sliced bread',
    artist => 1,
  });

  # re-fetch the cd, verify update
  is ($genre->search_related( 'cds' )->count, 1, 'Still one cd');
  $cd = $genre_cds->first;
  is_deeply (
    { map { $_, $cd->get_column ($_) } qw/artist year title/ },
    {
      artist => $artist->id,
      year => 2010,
      title => 'the best thing since sliced bread',
    },
    'CD year column updated correctly',
  );

  # expect a refusal:
  # the unique constraint is not complete (the artist is missing) and a
  # year is no identity, so there is no row to look up and none is created
  # (ADR 0070)
  throws_ok {
    $genre->update_or_create_related ('cds', {
      year => 2020,
      title => 'the best thing since sliced bread',
    })
  } qr/update_or_create\(\) needs a condition that gives every column of one unique constraint of source 'CD' a concrete value/,
    'ambiguous find + create refused'
  ;
  is ($genre->search_related( 'cds' )->count, 1, 'Nothing was created by the refused call');

  # expect a create, after a failed search using *only* the
  # *current* relationship and the unique column constraints
  # (so no year)
  $schema->is_executed_sql_bind( sub {
    $genre->update_or_create_related ('cds', {
      title => 'the best thing since vertical toasters',
      artist => $artist,
      year => 2012,
    });
  }, [
    [
      'SELECT "me"."cdid", "me"."artist", "me"."title", "me"."year", "me"."genreid", "me"."single_track"
          FROM cd "me"
        WHERE ( "me"."artist" = ? AND "me"."genreid" = ? AND "me"."title" = ? )
      ',
      1,
      2,
      "the best thing since vertical toasters",
    ],
    [
      # on libsqlite 3.35+ the driver declares insert_returning, so the autoinc PK
      # comes back on the INSERT itself instead of via a later last_insert_id
      'INSERT INTO cd ( "artist", "genreid", "title", "year") VALUES ( ?, ?, ?, ? )'
        . ( $schema->storage->_use_insert_returning ? ' RETURNING "cdid"' : '' ),
      1,
      2,
      "the best thing since vertical toasters",
      2012,
    ],
  ], 'expected select issued' );

  # a has_many search without a unique constraint makes no sense
  # but I am not sure what to test for - leaving open
};

# update_or_create_single: update_or_create_related on a might_have/single relationship refuses partial identities.
subtest 'update_or_create_single' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  plan tests => 11;

  my $artist = $schema->resultset ('Artist')->first;

  my $genre = $schema->resultset ('Genre')
              ->create ({ name => 'par excellence' });

  is ($genre->search_related( 'model_cd' )->count, 0, 'No cds yet');

  # expect a create
  $genre->update_or_create_related ('model_cd', {
    artist => $artist,
    year => 2009,
    title => 'the best thing since sliced bread',
  });

  # verify cd was inserted ok
  is ($genre->search_related( 'model_cd' )->count, 1, 'One cd');
  my $cd = $genre->search_related ('model_cd')->single;
  is_deeply (
    { map { $_, $cd->get_column ($_) } qw/artist year title/ },
    {
      artist => $artist->id,
      year => 2009,
      title => 'the best thing since sliced bread',
    },
    'CD created correctly',
  );

  # expect a year update on the only related row
  # (non-qunique column + the complete unique constraint as identity)
  $genre->update_or_create_related ('model_cd', {
    year => 2010,
    title => 'the best thing since sliced bread',
    artist => $artist,
  });

  # re-fetch the cd, verify update
  is ($genre->search_related( 'model_cd' )->count, 1, 'Still one cd');
  $cd = $genre->search_related ('model_cd')->single;
  is_deeply (
    { map { $_, $cd->get_column ($_) } qw/artist year title/ },
    {
      artist => $artist->id,
      year => 2010,
      title => 'the best thing since sliced bread',
    },
    'CD year column updated correctly',
  );


  # the only related row is no identity (ADR 0070): a unique column that is
  # only part of a constraint cannot look the row up, so nothing is updated
  throws_ok {
    $genre->update_or_create_related ('model_cd', {
      title => 'the best thing since vertical toasters',
    });
  } qr/update_or_create\(\) needs a condition that gives every column of one unique constraint of source 'CD' a concrete value/,
    'update of a unique column without the complete constraint is refused';

  is ($genre->search_related( 'model_cd' )->count, 1, 'Still one cd');
  $cd = $genre->search_related ('model_cd')->single;
  is_deeply (
    { map { $_, $cd->get_column ($_) } qw/artist year title/ },
    {
      artist => $artist->id,
      year => 2010,
      title => 'the best thing since sliced bread',
    },
    'CD untouched by the refused title update',
  );


  # a non-unique column alone is no identity either (ADR 0070)
  throws_ok {
    $genre->update_or_create_related ('model_cd', {
      year => 2011,
    });
  } qr/update_or_create\(\) needs a condition that gives every column of one unique constraint of source 'CD' a concrete value/,
    'update by a non-unique column only is refused';

  is ($genre->search_related( 'model_cd' )->count, 1, 'Still one cd');
  $cd = $genre->search_related ('model_cd')->single;
  is_deeply (
    { map { $_, $cd->get_column ($_) } qw/artist year title/ },
    {
      artist => $artist->id,
      year => 2010,
      title => 'the best thing since sliced bread',
    },
    'CD untouched by the refused year update',
  );
};

# virtual_columns: extra (virtual) columns on an object must be filtered when resolving relationship conditions.
# Test for virtual columns fix: when a result object has extra columns
# (e.g. from +select/+as), resolve_relationship_condition should filter
# them out and not pass garbage to downstream code.
# Backported from Perl5/DBIx-Class PR #115.
subtest 'virtual_columns' => sub {
  my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

  # Get a CD with an extra virtual column via +select/+as
  my $cd_with_extra = $schema->resultset('CD')->search(
    { 'me.cdid' => 1 },
    {
      join     => 'tracks',
      distinct => 1,
      '+select' => { count => 'tracks.trackid' },
      '+as'     => 'track_count',
    },
  )->single;

  ok( $cd_with_extra, 'Got a CD result object' );

  # Verify the virtual column is present in get_columns
  my %cols = $cd_with_extra->get_columns;
  ok( exists $cols{track_count}, 'Virtual column track_count exists in get_columns' );

  # Test set_from_related with this object that has extra columns.
  # The fix filters get_columns output to only actual source columns
  # when resolving relationship conditions.
  my $track = $schema->resultset('Track')->create({
    cd       => 1,
    position => 99,
    title    => 'Virtual Column Test Track',
  });

  lives_ok {
    $track->set_from_related( cd => $cd_with_extra );
  } 'set_from_related works with an object that has virtual columns';

  is( $track->get_column('cd'), $cd_with_extra->cdid,
    'FK column was correctly set from related object with virtual columns' );

  # Test the internal _resolve_relationship_condition directly: passing
  # a hashref with extra keys as foreign_values should be rejected by
  # the validation. This is the path that the fix protects against when
  # callers convert objects to hashrefs before calling r_r_c.
  my $rsrc = $schema->source('Track');
  throws_ok {
    $rsrc->_resolve_relationship_condition(
      rel_name       => 'cd',
      foreign_alias  => 'cd',
      self_alias     => 'me',
      foreign_values => {
        cdid   => 1,
        artist => 1,
        title  => 'Spoonful of bees',
        year   => 1999,
        genreid => 1,
        single_track => undef,
        # This is the virtual column that should not be here
        track_count  => 3,
      },
    );
  } qr/is not a column on related source/,
    'Passing a hashref with extra keys as foreign_values is correctly rejected';

  # But when passing a blessed object (which the fix handles by filtering),
  # the virtual columns are silently stripped
  lives_ok {
    $rsrc->_resolve_relationship_condition(
      rel_name       => 'cd',
      foreign_alias  => 'cd',
      self_alias     => 'me',
      foreign_values => $cd_with_extra,
    );
  } '_resolve_relationship_condition correctly filters virtual columns from objects';

  # Also test that find() works when passing an object with virtual columns
  # through a relationship
  my $artist_with_extra = $schema->resultset('Artist')->search(
    { 'me.artistid' => 1 },
    {
      '+select' => [ \'42' ],
      '+as'     => [ 'the_answer' ],
    },
  )->single;

  ok( $artist_with_extra, 'Got an Artist with virtual column' );
  ok( exists +{ $artist_with_extra->get_columns }->{the_answer},
    'Virtual column the_answer exists on Artist object' );

  lives_ok {
    $schema->resultset('CD')->find({ artist => $artist_with_extra, title => 'Spoonful of bees' });
  } 'find() with foreign object containing virtual columns works';
};

done_testing;
