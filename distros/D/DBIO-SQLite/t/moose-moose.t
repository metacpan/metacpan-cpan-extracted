use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  eval { require Moose; require MooseX::NonMoose; 1 }
    or plan skip_all => 'Moose and MooseX::NonMoose not installed';
}

use DBIO::Test::Schema::Moose;

# -----------------------------------------------------------------------
# Connect to in-memory SQLite and deploy
# -----------------------------------------------------------------------
my $schema = DBIO::Test::Schema::Moose->connect('dbi:SQLite::memory:', '', '', {
  quote_names => 0,
});
$schema->deploy;

my $artist_rs = $schema->resultset('Result::Artist');
my $cd_rs     = $schema->resultset('Result::CD');

# -----------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------

subtest 'create + columns' => sub {
  my $artist = $artist_rs->create({ name => 'Sugar Rush' });
  is( $artist->name, 'Sugar Rush', 'column works after create' );
  ok( $artist->id,   'auto_increment column populated' );
};

subtest 'lazy Moose attr from created row' => sub {
  my $artist = $artist_rs->create({ name => 'Mooseling' });
  is( $artist->display_name, 'Artist: Mooseling', 'lazy attr built from column' );
};

subtest 'Moose type constraint' => sub {
  my $artist = $artist_rs->create({ name => 'Scorer' });
  is( $artist->score, 0, 'Moose default is 0' );
  $artist->score(99);
  is( $artist->score, 99, 'Moose rw attr updated' );

  throws_ok { $artist->score('not an int') }
    qr/Validation failed|isa check/i,
    'Moose type constraint enforced';
};

subtest 'inflate_result (fetch from DB)' => sub {
  my $artist = $artist_rs->create({ name => 'Fetched' });
  my $id = $artist->id;

  my $fetched = $artist_rs->find($id);
  is( $fetched->name,         'Fetched',         'column works on fetched row' );
  is( $fetched->display_name, 'Artist: Fetched', 'lazy Moose attr on fetched row' );
  is( $fetched->score,        0,                 'Moose default on fetched row' );
};

subtest 'Moose attr does NOT leak into DB columns' => sub {
  my $artist = $artist_rs->create({ name => 'Clean' });
  $artist->score(7);

  lives_ok { $artist->update({ name => 'Clean Updated' }) }
    'update with Moose attr set does not crash';
  is( $artist->name,  'Clean Updated', 'column updated correctly' );
  is( $artist->score, 7,               'Moose attr preserved after update' );
};

subtest 'make_immutable is safe' => sub {
  ok(
    DBIO::Test::Schema::Moose::Result::Artist->meta->is_immutable,
    'Artist class is immutable'
  );
  ok(
    DBIO::Test::Schema::Moose::Result::CD->meta->is_immutable,
    'CD class is immutable'
  );
};

subtest 'CD: create with has_many relationship' => sub {
  my $artist = $artist_rs->create({ name => 'Band' });
  my $cd = $cd_rs->create({ artist_id => $artist->id, title => 'First Album', year => 2024 });

  is( $cd->title,      'First Album',        'CD column set' );
  is( $cd->full_title, 'First Album (2024)', 'CD lazy builder works' );
  is( $cd->rating,     0,                    'CD lazy default' );

  my @cds = $artist->cds->all;
  is( scalar @cds, 1, 'has_many returns one CD' );
  is( $cds[0]->title, 'First Album', 'CD from relationship correct' );
};

done_testing;
