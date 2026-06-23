use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  eval { require Moo; 1 }
    or plan skip_all => 'Moo not installed';
}

use DBIO::Test::Schema::MooCake;

# -----------------------------------------------------------------------
# Connect to in-memory SQLite and deploy
# -----------------------------------------------------------------------
my $schema = DBIO::Test::Schema::MooCake->connect('dbi:SQLite::memory:', '', '', {
  quote_names => 0,
});
$schema->deploy;

my $artist_rs = $schema->resultset('Artist');
my $cd_rs     = $schema->resultset('CD');

# -----------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------

subtest 'create + columns' => sub {
  my $artist = $artist_rs->create({ name => 'Cake Baker' });
  is( $artist->name, 'Cake Baker', 'column works after create' );
  ok( $artist->id,   'auto_increment column populated' );
};

subtest 'lazy Moo attr from created row' => sub {
  my $artist = $artist_rs->create({ name => 'Lazybird' });
  is( $artist->display_name, 'Artist: Lazybird', 'lazy builder on created row' );
};

subtest 'Moo default attr' => sub {
  my $artist = $artist_rs->create({ name => 'Scorer' });
  is( $artist->score, 0, 'lazy default is 0' );
  $artist->score(42);
  is( $artist->score, 42, 'rw attr updated' );
};

subtest 'inflate_result (fetch from DB)' => sub {
  my $artist = $artist_rs->create({ name => 'Fetched' });
  my $fetched = $artist_rs->find( $artist->id );
  is( $fetched->name,         'Fetched',          'column works on fetched row' );
  is( $fetched->display_name, 'Artist: Fetched',  'lazy attr on fetched row' );
  is( $fetched->score,        0,                  'Moo default on fetched row' );
};

subtest 'Moo attr does NOT leak into DB columns' => sub {
  my $artist = $artist_rs->create({ name => 'Clean' });
  $artist->score(99);
  lives_ok { $artist->update({ name => 'Clean Updated' }) }
    'update with Moo attr set does not crash';
  is( $artist->name,  'Clean Updated', 'column updated correctly' );
  is( $artist->score, 99,              'Moo attr preserved after update' );
};

subtest 'custom ResultSet: by_name' => sub {
  $artist_rs->create({ name => 'Needle' });
  my @found = $artist_rs->by_name('Needle')->all;
  is( scalar @found, 1, 'by_name finds one artist' );
  is( $found[0]->name, 'Needle', 'correct artist returned' );
};

subtest 'custom ResultSet: order_by_name' => sub {
  $artist_rs->create({ name => 'Zebra' });
  $artist_rs->create({ name => 'Aardvark' });
  my @names = map { $_->name } $artist_rs->order_by_name->all;
  is( $names[0], 'Aardvark', 'first result is alphabetically first' );
};

subtest 'CD: create with has_many relationship' => sub {
  my $artist = $artist_rs->create({ name => 'Band' });
  my $cd = $cd_rs->create({ artist_id => $artist->id, title => 'First Album', year => 2024 });
  is( $cd->title,      'First Album',        'CD column set' );
  is( $cd->full_title, 'First Album (2024)', 'CD lazy builder works' );
  is( $cd->rating,     0,                    'CD lazy default' );

  my @cds = $artist->cds->all;
  is( scalar @cds, 1, 'has_many returns one CD' );
};

subtest 'CD uses default ResultSet' => sub {
  isa_ok( $cd_rs, 'DBIO::ResultSet' );
  ok( !$cd_rs->isa('DBIO::Test::Schema::MooCake::ResultSet::CD'),
    'no custom CD ResultSet' );
};

subtest 'schema verbose Moo attr' => sub {
  is( $schema->verbose, 0, 'verbose defaults to 0' );
  $schema->verbose(1);
  is( $schema->verbose, 1, 'verbose rw writable' );
};

done_testing;
