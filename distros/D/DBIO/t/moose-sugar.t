use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  eval { require Moose; require MooseX::NonMoose; 1 }
    or plan skip_all => 'Moose and MooseX::NonMoose not installed';
}

use DBIO::Test::Schema::MooseSugar;

# Connect with fake storage — no real database needed
my $schema = DBIO::Test::Schema::MooseSugar->connect('DBIO::Test::Storage', '');

my $artist_rs = $schema->resultset('Artist');
my $cd_rs     = $schema->resultset('CD');

# -----------------------------------------------------------------------
# Cake DDL: columns declared correctly via Cake keywords
# -----------------------------------------------------------------------

subtest 'Cake DDL: Artist columns present' => sub {
  my $rsrc = $schema->source('Artist');
  ok( $rsrc->has_column('id'),   'id column exists' );
  ok( $rsrc->has_column('name'), 'name column exists' );
  ok( $rsrc->column_info('id')->{is_auto_increment}, 'id is auto_increment' );
};

subtest 'Cake DDL: CD columns present' => sub {
  my $rsrc = $schema->source('CD');
  ok( $rsrc->has_column('id'),        'id column exists' );
  ok( $rsrc->has_column('artist_id'), 'artist_id column exists' );
  ok( $rsrc->has_column('title'),     'title column exists' );
  ok( $rsrc->has_column('year'),      'year column exists' );
};

# -----------------------------------------------------------------------
# FOREIGNBUILDARGS: Moose attrs filtered from DBIO::Row::new
# -----------------------------------------------------------------------

subtest 'new_result: DBIO column + Moose attr both accepted' => sub {
  my $row;
  lives_ok {
    $row = $artist_rs->new_result({ name => 'Sugar Artist', score => 7 });
  } 'new_result with Moose attr does not die';
  is( $row->name,  'Sugar Artist', 'DBIO column set' );
  is( $row->score, 7,              'Moose attr set' );
};

subtest 'new_result: Moose type constraint enforced' => sub {
  throws_ok {
    $artist_rs->new_result({ name => 'X', score => 'not-an-int' });
  } qr/Validation failed|isa check/i,
    'isa Int constraint fires on bad value';
};

subtest 'new_result: Moose attr NOT stored as DB column' => sub {
  my $row = $artist_rs->new_result({ name => 'Clean', score => 9 });
  my %cols = $row->get_columns;
  ok( !exists $cols{score}, 'score not in get_columns' );
  ok(  exists $cols{name},  'name is in get_columns' );
};

# -----------------------------------------------------------------------
# inflate_result: lazy attrs work without new()
# -----------------------------------------------------------------------

subtest 'inflate_result: lazy builder works' => sub {
  my $rsrc = $schema->source('Artist');
  my $row  = DBIO::Test::Schema::MooseSugar::Result::Artist->inflate_result(
    $rsrc, { id => 1, name => 'Sugary' }
  );
  is( $row->display_name, 'Artist: Sugary', 'lazy builder on inflate_result row' );
  is( $row->score,        0,                'lazy default on inflate_result row' );
};

subtest 'inflate_result: type constraint on lazy attr mutation' => sub {
  my $rsrc = $schema->source('Artist');
  my $row  = DBIO::Test::Schema::MooseSugar::Result::Artist->inflate_result(
    $rsrc, { id => 2, name => 'TypeTest' }
  );
  throws_ok { $row->score('bad') }
    qr/Validation failed|isa check/i,
    'type constraint on inflate_result row';
};

subtest 'inflate_result: CD lazy full_title' => sub {
  my $rsrc = $schema->source('CD');
  my $cd   = DBIO::Test::Schema::MooseSugar::Result::CD->inflate_result(
    $rsrc, { id => 1, artist_id => 1, title => 'Sweet', year => 2001 }
  );
  is( $cd->full_title, 'Sweet (2001)', 'CD lazy builder on inflate_result' );
  is( $cd->rating,     0,              'CD lazy default' );
};

# -----------------------------------------------------------------------
# Custom ResultSet on Artist; default on CD
# -----------------------------------------------------------------------

subtest 'Artist has custom ResultSet' => sub {
  isa_ok( $artist_rs, 'DBIO::Test::Schema::MooseSugar::ResultSet::Artist',
    'artist resultset is custom class' );
  can_ok( $artist_rs, 'by_name' );
  can_ok( $artist_rs, 'order_by_name' );
  is( $artist_rs->default_limit, 100, "Moose attr on custom ResultSet" );
};

subtest 'CD uses default ResultSet' => sub {
  isa_ok( $cd_rs, 'DBIO::ResultSet', 'cd resultset is base class' );
  ok( !$cd_rs->isa('DBIO::Test::Schema::MooseSugar::ResultSet::CD'),
    'no custom CD ResultSet' );
};

# -----------------------------------------------------------------------
# make_immutable
# -----------------------------------------------------------------------

subtest 'Result classes are immutable' => sub {
  ok( DBIO::Test::Schema::MooseSugar::Result::Artist->meta->is_immutable,
    'Artist is immutable' );
  ok( DBIO::Test::Schema::MooseSugar::Result::CD->meta->is_immutable,
    'CD is immutable' );
};

subtest 'schema class is immutable' => sub {
  ok( DBIO::Test::Schema::MooseSugar->meta->is_immutable,
    'schema class itself is immutable' );
};

# -----------------------------------------------------------------------
# Schema class itself is a Moose class
# -----------------------------------------------------------------------

subtest 'schema is a Moose class with verbose attr' => sub {
  is( $schema->verbose, 0, 'verbose defaults to 0' );
  $schema->verbose(1);
  is( $schema->verbose, 1, 'verbose rw writable' );
};

done_testing;
