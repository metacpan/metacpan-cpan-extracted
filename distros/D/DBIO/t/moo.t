use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  eval { require Moo; 1 }
    or plan skip_all => 'Moo not installed';
}

use DBIO::Test::Schema::Moo;

# Connect with fake storage — no real database needed
my $schema = DBIO::Test::Schema::Moo->connect('DBIO::Test::Storage', '');

my $artist_rs = $schema->resultset('Result::Artist');
my $cd_rs     = $schema->resultset('Result::CD');

# -----------------------------------------------------------------------
# new_result: FOREIGNBUILDARGS must filter Moo attrs from DBIO::Row::new
# -----------------------------------------------------------------------

subtest 'new_result: DBIO column + Moo attr both accepted' => sub {
  my $row;
  lives_ok {
    $row = $artist_rs->new_result({ name => 'Test Artist', score => 42 });
  } 'new_result with Moo attr does not die';

  is( $row->name,  'Test Artist', 'DBIO column set correctly' );
  is( $row->score, 42,            'Moo attr set correctly' );
};

subtest 'new_result: unknown key silently dropped' => sub {
  # FOREIGNBUILDARGS cannot distinguish a Moo attr from a typo —
  # any key not known to DBIO is filtered out before store_column sees it.
  my $row;
  lives_ok {
    $row = $artist_rs->new_result({ name => 'X', no_such_column => 1 });
  } 'unrecognised key silently dropped by FOREIGNBUILDARGS';
  is( $row->name, 'X', 'column was set normally' );
  ok( !$row->can('no_such_column'), 'dropped key has no accessor' );
};

subtest 'new_result: Moo attr NOT stored as DB column' => sub {
  my $row = $artist_rs->new_result({ name => 'Clean', score => 7 });
  my %cols = $row->get_columns;
  ok( !exists $cols{score}, 'score not in get_columns — not a DB column' );
  ok(  exists $cols{name},  'name is in get_columns — is a DB column' );
};

# -----------------------------------------------------------------------
# inflate_result: Moo lazy attrs must work when new() is bypassed
# -----------------------------------------------------------------------

subtest 'inflate_result: lazy builder works without new()' => sub {
  my $rsrc = $schema->source('Result::Artist');
  my $row  = DBIO::Test::Schema::Moo::Result::Artist->inflate_result(
    $rsrc, { id => 1, name => 'Inflated' }
  );

  is( $row->name,         'Inflated',         'column readable' );
  is( $row->display_name, 'Artist: Inflated', 'lazy builder fires on access' );
};

subtest 'inflate_result: lazy default works without new()' => sub {
  my $rsrc = $schema->source('Result::Artist');
  my $row  = DBIO::Test::Schema::Moo::Result::Artist->inflate_result(
    $rsrc, { id => 2, name => 'Scored' }
  );

  is( $row->score, 0, 'lazy default is 0 on inflate_result row' );
  $row->score(99);
  is( $row->score, 99, 'rw attr writable after inflate_result' );
};

# -----------------------------------------------------------------------
# CD result class
# -----------------------------------------------------------------------

subtest 'CD: new_result with Moo attr' => sub {
  my $cd;
  lives_ok {
    $cd = $cd_rs->new_result({ artist_id => 1, title => 'Test CD', year => 2024, rating => 5 });
  } 'new_result with Moo rating attr does not die';

  is( $cd->title,  'Test CD', 'DBIO column set' );
  is( $cd->rating, 5,         'Moo attr set' );
};

subtest 'CD: inflate_result lazy full_title' => sub {
  my $rsrc = $schema->source('Result::CD');
  my $cd   = DBIO::Test::Schema::Moo::Result::CD->inflate_result(
    $rsrc, { id => 1, artist_id => 1, title => 'Alive', year => 1999 }
  );

  is( $cd->full_title, 'Alive (1999)', 'lazy builder builds full_title' );
  is( $cd->rating,     0,              'lazy default on CD inflate_result' );
};

# -----------------------------------------------------------------------
# Custom ResultSet — Artist has one, CD uses the default
# -----------------------------------------------------------------------

subtest 'custom ResultSet class on Artist' => sub {
  isa_ok( $artist_rs, 'DBIO::Test::Schema::Moo::ResultSet::Artist',
    'resultset() returns custom class' );
  can_ok( $artist_rs, 'by_name' );
  can_ok( $artist_rs, 'order_by_name' );
  is( $artist_rs->default_limit, 100, "Moo attr on custom ResultSet" );
};

subtest 'CD uses default ResultSet (no custom class)' => sub {
  isa_ok( $cd_rs, 'DBIO::ResultSet', 'CD resultset is a DBIO::ResultSet' );
  ok( !$cd_rs->isa('DBIO::Test::Schema::Moo::ResultSet::CD'),
    'CD has no custom ResultSet class' );
};

subtest 'schema verbose Moo attr' => sub {
  is( $schema->verbose, 0, 'verbose defaults to 0' );
  $schema->verbose(1);
  is( $schema->verbose, 1, 'verbose rw attr writable' );
};

done_testing;
