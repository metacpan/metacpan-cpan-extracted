use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;
use DBIO::SQLite::Test;
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

done_testing;
