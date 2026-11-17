use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;

sub mc_diag { diag (@_) if $ENV{DBIO_MULTICREATE_DEBUG} };

# Each subtest was a file of its own; every one builds its own schema.

# WHY: a might_have style single relation must be created together with its parent row.
subtest 'cd_single' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  eval {
    my $cd = $schema->resultset('CD')->first;
    my $track = $schema->resultset('Track')->new_result({
      cd => $cd,
      title => 'Multicreate rocks',
      cd_single => {
        artist => $cd->artist,
        year => 2008,
        title => 'Disemboweling MultiCreate',
      },
    });

    isa_ok ($track, 'DBIO::Test::Track', 'Main Track object created');

    $track->insert;

    ok(1, 'created track');

    is($track->title, 'Multicreate rocks', 'Correct Track title');

    my $single = $track->cd_single;

    ok($single->cdid, 'Got cdid');
  };

  done_testing;
};

# WHY: a diamond-shaped multicreate must attach every side to the shared row.
subtest 'diamond' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  mc_diag (<<'DG');
* Try a diamond multicreate

Artist -> has_many -> Artwork_to_Artist -> belongs_to
                                               /
  belongs_to <- CD <- belongs_to <- Artwork <-/
    \
     \-> Artist2

DG

  lives_ok (sub {
    $schema->resultset ('Artist')->create ({
      name => 'The wooled wolf',
      artwork_to_artist => [{
        artwork => {
          cd => {
            title => 'Wool explosive',
            year => 1999,
            artist => { name => 'The black exploding sheep' },
          }
        }
      }],
    });

    my $art2 = $schema->resultset ('Artist')->find ({ name => 'The black exploding sheep' });
    ok ($art2, 'Second artist exists');

    my $cd = $art2->cds->single;
    is ($cd->title, 'Wool explosive', 'correctly created CD');

    is_deeply (
      [ $cd->artwork->artists->get_column ('name')->all ],
      [ 'The wooled wolf' ],
      'Artist correctly attached to artwork',
    );

  }, 'Diamond chain creation ok');

  done_testing;
};

# WHY: multicreate through a chain with an already existing member; the TODO parts document the missing behaviour.
subtest 'existing_in_chain' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  # For fully intuitive multicreate any relationships in a chain
  # that do not exist for one reason or another should be created,
  # even if the preceeding relationship already exists.
  #
  # To get this to work a minor rewrite of find() is necessary, and
  # more importantly some sort of recursive_insert() call needs to
  # be available. The way things will work then is:
  # *) while traversing the hierarchy code calls find_or_create()
  # *) this in turn calls find(%\nested_dataset)
  # *) this should return not only the existing object, but must
  #    also attach all non-existing (in fact maybe existing) related
  #    bits of data to it, with in_storage => 0
  # *) then before returning the result of the succesful find(), we
  #    simply call $obj->recursive_insert and all is dandy
  #
  # Since this will not be a very clean solution, todoifying for the
  # time being until an actual need arises
  #
  # ribasushi

  my $TODO_msg = "See comment at top of @{[ __FILE__ ]} for discussion of the TODO";

  {
    my $counts;
    $counts->{$_} = $schema->resultset($_)->count for qw/Track CD Genre/;

    my $existing_nogen_cd = $schema->resultset('CD')->search (
      { 'genre.genreid' => undef },
      { join => 'genre' },
    )->first;

    $schema->resultset('Track')->create ({
      title => 'Sugar-coated',
      cd => {
        artist => $existing_nogen_cd->get_column('artist'),
        title => $existing_nogen_cd->title,
        genre => {
          name => 'sugar genre',
        }
      }
    });

    is ($schema->resultset('Track')->count, $counts->{Track} + 1, '1 new track');
    is ($schema->resultset('CD')->count, $counts->{CD}, 'No new cds');

    TODO: {
      todo_skip $TODO_msg, 1;
      is ($schema->resultset('Genre')->count, $counts->{Genre} + 1, '1 new genre');
      is ($existing_nogen_cd->genre->title,  'sugar genre', 'Correct genre assigned to CD');
    }
  }

  {
    my $counts;
    $counts->{$_} = $schema->resultset($_)->count for qw/Artist CD Producer/;

    lives_ok (sub {
      my $artist = $schema->resultset('Artist')->first;
      my $producer = $schema->resultset('Producer')->create ({ name => 'the queen of england' });

      $schema->resultset('CD')->create ({
        artist => $artist,
        title => 'queen1',
        year => 2007,
        cd_to_producer => [
          {
            producer => {
            name => $producer->name,
              producer_to_cd => [
                {
                  cd => {
                    title => 'queen2',
                    year => 2008,
                    artist => $artist,
                  },
                },
              ],
            },
          },
        ],
      });

      is ($schema->resultset('Artist')->count, $counts->{Artist}, 'No new artists');
      is ($schema->resultset('Producer')->count, $counts->{Producer} + 1, '1 new producers');

      local $TODO = $TODO_msg;
      is ($schema->resultset('CD')->count, $counts->{CD} + 2, '2 new cds');

      is ($producer->cds->count, 2, 'CDs assigned to correct producer');
      is_deeply (
        [ $producer->cds->search ({}, { order_by => 'title' })->get_column('title')->all],
        [ qw/queen1 queen2/ ],
        'Correct cd names',
      );
    }, 'create() did not throw');
  }

  done_testing;
};

# WHY: repeated find_or_create with nested data must reuse already created related rows.
subtest 'find_or_multicreate' => sub {
  my $schema = DBIO::SQLite::Test->init_schema(no_populate => 1 );

  my $t11 = $schema->resultset('Track')->find_or_create({
    trackid => 1,
    title => 'Track one cd one',
    cd => {
      year => 1,
      title => 'CD one',
      very_long_artist_relationship => {
        name => 'Artist one',
      }
    }
  });

  my $t12 = $schema->resultset('Track')->find_or_create({
    trackid => 2,
    title => 'Track two cd one',
    cd => {
      title => 'CD one',
      very_long_artist_relationship => {
        name => 'Artist one',
      }
    }
  });

  # FIXME - MC should be smart enough to infer this on its own...
  $schema->resultset('Artist')->create({ name => 'Artist two' });

  my $t2 = $schema->resultset('Track')->find_or_create({
    trackid => 3,
    title => 'Track one cd one',
    cd => {
      year => 1,
      title => 'CD one',
      very_long_artist_relationship => {
        name => 'Artist two',
      }
    }
  });

  is_deeply(
    $schema->resultset('Artist')->search({}, {
      prefetch => { cds => 'tracks' },
      order_by => 'tracks.title',
    })->all_hri,
    [
      { artistid => 1, charfield => undef, name => "Artist one", rank => 13, cds => [
        { artist => 1, cdid => 1, genreid => undef, single_track => undef, title => "CD one", year => 1, tracks => [
          { cd => 1, last_updated_at => undef, last_updated_on => undef, position => 1, title => "Track one cd one", trackid => 1 },
          { cd => 1, last_updated_at => undef, last_updated_on => undef, position => 2, title => "Track two cd one", trackid => 2 },
        ]},
      ]},
      { artistid => 2, charfield => undef, name => "Artist two", rank => 13, cds => [
        { artist => 2, cdid => 2, genreid => undef, single_track => undef, title => "CD one", year => 1, tracks => [
          { cd => 2, last_updated_at => undef, last_updated_on => undef, position => 1, title => "Track one cd one", trackid => 3 },
        ]},
      ]},
    ],
    'Expected state of database after several find_or_create rounds'
  );


  done_testing;
};

# WHY: several identical default-insert has_many children must all be created.
subtest 'has_many' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  my $link = $schema->resultset ('Link')->create ({
    url => 'loldogs!',
    bookmarks => [
      { link => 'Mein Hund ist schwul'},
      { link => 'Mein Hund ist schwul'},
    ]
  });
  is ($link->bookmarks->count, 2, "Two identical default-insert has_many's created");


  $link = $schema->resultset ('Link')->create ({
    url => 'lolcats!',
    bookmarks => [
      {},
      {},
    ]
  });
  is ($link->bookmarks->count, 2, "Two identical default-insert has_many's created");

  done_testing;
};

# WHY: add_to_producers over many_to_many must create or attach the far end.
subtest 'm2m' => sub {
  plan tests => 4;

  my $schema = DBIO::SQLite::Test->init_schema();

  lives_ok ( sub {

    my $prod_rs = $schema->resultset ('Producer');
    my $prod_count = $prod_rs->count;

    my $cd = $schema->resultset('CD')->first;
    $cd->add_to_producers ({name => 'new m2m producer'});

    is ($prod_rs->count, $prod_count + 1, 'New producer created');
    ok ($cd->producers->find ({name => 'new m2m producer'}), 'Producer created with correct name');

    my $cd2 = $schema->resultset('CD')->search ( { cdid => { '!=', $cd->cdid } }, {rows => 1} )->single;  # retrieve a cd different from the first
    $cd2->add_to_producers ({name => 'new m2m producer'});                                                # attach to an existing producer
    ok ($cd2->producers->find ({name => 'new m2m producer'}), 'Existing producer attached to existing cd');

  }, 'Test far-end find_or_create over many_to_many');

  1;
};

# WHY: multilevel has_one/might_have where the middle table's PK is also its FK must be created through.
subtest 'multilev_single_PKeqFK' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();

  mc_diag (<<'DG');
* Test a multilevel might-have/has_one with a PK == FK in the mid-table

CD -> might have -> Artwork
    \- has_one -/     \
                       \
                        \-> has_many \
                                      --> Artwork_to_Artist
                        /-> has_many /
                       /
                     Artist
DG

  my $rels = {
    has_one => 'mandatory_artwork',
    might_have => 'artwork',
  };

  for my $type (qw/has_one might_have/) {

    lives_ok (sub {

      my $rel = $rels->{$type};
      my $cd_title = "Simple test $type cd";

      my $cd = $schema->resultset('CD')->create ({
        artist => 1,
        title => $cd_title,
        year => 2008,
        $rel => {},
      });

      isa_ok ($cd, 'DBIO::Test::CD', 'Main CD object created');
      is ($cd->title, $cd_title, 'Correct CD title');

      isa_ok ($cd->$rel, 'DBIO::Test::Artwork', 'Related artwork present');
      ok ($cd->$rel->in_storage, 'And in storage');

    }, "Simple $type creation");
  }

  my $artist_rs = $schema->resultset('Artist');
  for my $type (qw/has_one might_have/) {

    my $rel = $rels->{$type};

    my $cd_title = "Test $type cd";
    my $artist_names = [ map { "Artist via $type $_" } (1, 2) ];

    my $someartist = $artist_rs->next;

    lives_ok (sub {
      my $cd = $schema->resultset('CD')->create ({
        artist => $someartist,
        title => $cd_title,
        year => 2008,
        $rel => {
        artwork_to_artist => [ map {
              { artist => { name => $_ } }
            } (@$artist_names)
          ]
        },
      });


      isa_ok ($cd, 'DBIO::Test::CD', 'Main CD object created');
      is ($cd->title, $cd_title, 'Correct CD title');

      my $art_obj = $cd->$rel;
      ok ($art_obj->has_column_loaded ('cd_id'), 'PK/FK present on artwork object');
      is ($art_obj->artists->count, 2, 'Correct artwork creator count via the new object');
      is_deeply (
        [ sort $art_obj->artists->get_column ('name')->all ],
        $artist_names,
        'Artists named correctly when queried via object',
      );

      my $artwork = $schema->resultset('Artwork')->search (
        { 'cd.title' => $cd_title },
        { join => 'cd' },
      )->single;
      is ($artwork->artists->count, 2, 'Correct artwork creator count via a new search');
      is_deeply (
          [ sort $artwork->artists->get_column ('name')->all ],
        $artist_names,
        'Artists named correctly queried via a new search',
      );
    }, "multilevel $type with a PK == FK in the $type/has_many table ok");
  }

  done_testing;
};

done_testing;
