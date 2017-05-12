use strict;
use warnings;

use Test::More;

eval "use Cache::MemoryCache";
plan skip_all => 'Cache::Cache required' if $@;

eval "use DBD::SQLite";
plan skip_all => 'needs DBD::SQLite for testing' if $@;

plan tests => 31;

use lib 't/lib';

use_ok('SweetTest');

SweetTest->cache(Cache::MemoryCache->new(
    { namespace => 'SweetTest', default_expires_in => 60 } ) );

SweetTest->default_search_attributes(
    { use_resultset_cache => 1,
      profile_cache => 1 });

SweetTest::Artist->profiling_data({ });

my ($artist) = SweetTest::Artist->search({ name => 'Caterwauler McCrae' });

is($artist->name, 'Caterwauler McCrae', 'Object ok');

is(SweetTest::Artist->profiling_data->{resultset_cache}[0][0],
  'MISS', 'Resultset cache miss');

is(SweetTest::Artist->profiling_data->{object_cache}[0][0],
  'MISS', 'Object cache miss');

SweetTest::Artist->profiling_data({ });

($artist) = SweetTest::Artist->search({ name => 'Caterwauler McCrae' });

is($artist->name, 'Caterwauler McCrae', 'Object ok');

is(SweetTest::Artist->profiling_data->{resultset_cache}[0][0],
  'HIT', 'Resultset cache hit');

is(SweetTest::Artist->profiling_data->{object_cache}[0][0],
  'HIT', 'Object cache hit');

SweetTest::Artist->profiling_data({ });

($artist) = SweetTest::Artist->retrieve($artist->artistid);

is($artist->name, 'Caterwauler McCrae', 'Object ok');

is(SweetTest::Artist->profiling_data->{object_cache}[0][0],
  'HIT', 'Object cache hit for retrieve');

SweetTest::Artist->profiling_data({ });

$artist->name('Caterwauler McCrae (RIP)');
$artist->update;

sleep 2;

($artist) = SweetTest::Artist->retrieve($artist->artistid);

is($artist->name, 'Caterwauler McCrae (RIP)', 'Object ok');

is(SweetTest::Artist->profiling_data->{object_cache}[0][0],
  'MISS', 'Object cache miss after update');

SweetTest::Artist->profiling_data({ });

my @res = SweetTest::Artist->search({ name => 'Caterwauler McCrae' });

cmp_ok(scalar @res, '==', 0, 'Nothing returned');

is(SweetTest::Artist->profiling_data->{resultset_cache}[0][0],
  'MISS', 'Resultset cache miss after update');

SweetTest::Artist->profiling_data({ });

($artist) = SweetTest::Artist->search({ 'cds.title' => 'Spoonful of bees' });

is($artist->name, 'Caterwauler McCrae (RIP)', 'Object ok');

is(SweetTest::Artist->profiling_data->{resultset_cache}[0][0],
  'MISS', 'Resultset cache miss');

SweetTest::Artist->profiling_data({ });

($artist) = SweetTest::Artist->search({ 'cds.title' => 'Spoonful of bees' });

is($artist->name, 'Caterwauler McCrae (RIP)', 'Object ok');

is(SweetTest::Artist->profiling_data->{resultset_cache}[0][0],
  'HIT', 'Resultset cache hit (cross-table)');

SweetTest::CD->create({ artist => $artist, title => 'Foo', year => 2048 });

sleep 2;

SweetTest::Artist->profiling_data({ });

($artist) = SweetTest::Artist->search({ 'cds.title' => 'Spoonful of bees' });

is($artist->name, 'Caterwauler McCrae (RIP)', 'Object ok');

is(SweetTest::Artist->profiling_data->{resultset_cache}[0][0],
  'MISS', 'Resultset cache miss (expired cross-table search)');

eval { SweetTest::Artist->search({ }, { prefetch => [ 'cds' ] }) };

like($@, qr/is not a has_a or might_have rel/, 'prefetch errors ok');

my @all = SweetTest::Artist->retrieve_all;

cmp_ok(scalar @all, '==', 3, 'All records retrieved successfully');

SweetTest::CD->profiling_data({ });

my ( $pager, $it ) = SweetTest::CD->pager(
    {},
    { rows => 3,
      page => 1,
      disable_sql_paging => 1 } );
      
is( SweetTest::CD->profiling_data->{resultset_cache}[0][0],
    'MISS', 'disable_sql_paging cache miss ok' );

SweetTest::CD->profiling_data({ });

( $pager, $it ) = SweetTest::CD->pager(
    {},
    { rows => 3,
      page => 2,
      disable_sql_paging => 1 } );
      
is( SweetTest::CD->profiling_data->{resultset_cache}[0][0],
    'HIT', 'disable_sql_paging second page cache hit ok' );
    
SweetTest::CD->profiling_data({ });

( $pager, $it ) = SweetTest::CD->pager(
    {},
    { rows => 3,
      page => 2 } );

is( SweetTest::CD->profiling_data->{resultset_cache}[0][0],
    'MISS', 'normal paging second page cache miss ok' );
    
# Cache test for delete().  Add a new artist, get cached, then delete it
SweetTest::Artist->create( { name => 'One Hit Wonder' } );

my ( $new_artist ) = SweetTest::Artist->search( name => 'One Hit Wonder' );

SweetTest::Artist->profiling_data({ });

( $new_artist ) = SweetTest::Artist->search( name => 'One Hit Wonder' );

is( SweetTest::Artist->profiling_data->{resultset_cache}[0][0],
    'HIT', 'new artist cache hit ok' );
    
$new_artist->delete;

SweetTest::Artist->profiling_data({ });

( $new_artist ) = SweetTest::Artist->search( name => 'One Hit Wonder' );

is( SweetTest::Artist->profiling_data->{resultset_cache}[0][0],
    'MISS', 'new artist after delete cache miss ok' );   

# New object inflation test.  Add new CD for an artist.  It will be
# cached during create(). Test that foreign data can be accessed.
my ( $new_cd ) = SweetTest::CD->create( {
    artist => 2,
    title => "Really Awful Music",
    year => 2005,
} );

is( $new_cd->artist->name, 'Random Boy Band', 'cache create inflation ok' );

SKIP: {
  skip "Requires a patch to Class::DBI", 2;

  # Same test as above but with a double primary key table.
  # This will fail without Perrin's primary key inflation patch
  my ( $new_2pk ) = SweetTest::TwoKeys->create( {
      artist => 2,
      cd => 3,
  } );
  eval {
      is( $new_2pk->artist->name, 'Random Boy Band', 'cached double primary key inflation ok' );
  };
  warn $@ if $@;
  
  # Access through the new TwoKeys record via a has_many
  ( $artist ) = SweetTest::Artist->retrieve(2);
  
  eval {
      is( ($artist->twokeys)[1]->cd->artist->name, 'Caterwauler McCrae (RIP)', 'cached double primary key has_many inflation ok' );
  };
  warn $@ if $@;

}

# Repeat the above 2 tests using a workaround table with a single primary key 
my ( $new_1pk ) = SweetTest::OneKey->create( {
    artist => 2,
    cd => 3,
} );
is( $new_1pk->artist->name, 'Random Boy Band', 'cached single primary key inflation ok' );

# Access through the new OneKey record via a has_many
( $artist ) = SweetTest::Artist->retrieve(2);

eval {
    is( ($artist->onekeys)[1]->cd->artist->name, 'Caterwauler McCrae (RIP)', 'cached single primary key has_many inflation ok' );
};
warn $@ if $@;

