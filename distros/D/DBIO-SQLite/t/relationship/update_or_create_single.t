use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::SQLite::Test;
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
