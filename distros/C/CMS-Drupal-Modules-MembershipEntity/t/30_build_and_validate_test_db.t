#! perl
use strict;
use warnings;

use Test::More tests => 4;
use Test::Group;
use DBI;
use FindBin;
use Time::Local;

BEGIN {
  ## Make sure we don't connect to our real DB if we
  ## have given the credentials for it
  $ENV{'DRUPAL_IGNORE_TEST_CREDS'} = 1;
}

subtest 'We have all our parts' => sub {
  plan tests => 4;
  
  use_ok( 'CMS::Drupal' ) or die;
  use_ok( 'CMS::Drupal::Modules::MembershipEntity' ) or die;
  use_ok( 'CMS::Drupal::Modules::MembershipEntity::Test' );
  subtest 'All the data files exist.' => sub {
    plan tests => 4;

    for (qw/ test_db.sql test_types.dat test_memberships.dat test_terms.dat /) { 
      ok( -e "$FindBin::Bin/data/$_", "(we have $_)" );
    }
  };
};

my $drupal = CMS::Drupal->new;
my $dbh    = build_and_validate_test_db( $drupal );

##########

my $ME;

subtest "Create a ::MembershipEntity object and check its methods" => sub {
  plan tests => 3;
  
  can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'new' );
  $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );
  isa_ok( $ME, 'CMS::Drupal::Modules::MembershipEntity' );
  can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'fetch_memberships' );
};

subtest 'Validate data integrity', => sub {
  plan tests => 1;

  ## Make a structure from the data files and compare to what the 
  ## module's function returns
  my $wanted_memberships = build_test_data();
  my $got_memberships = $ME->fetch_memberships;

  is_deeply( $got_memberships, $wanted_memberships, '$ME->fetch_memberships is_deeply the content of the test data files.' );
};

__END__

