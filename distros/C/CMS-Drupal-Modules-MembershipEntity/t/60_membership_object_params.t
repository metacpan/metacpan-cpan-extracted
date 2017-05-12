#! perl
use strict;
use warnings;

BEGIN {
  ## Make sure we don't connect to our real DB if we
  ## have given the credentials for it
  $ENV{'DRUPAL_IGNORE_TEST_CREDS'} = 1;
}

use Test::More tests => 2;
use Test::Group;
use Test::Exception;

use CMS::Drupal;
use CMS::Drupal::Modules::MembershipEntity;
use CMS::Drupal::Modules::MembershipEntity::Test;

my $drupal = CMS::Drupal->new;
my $dbh    = build_test_db( $drupal );
my $ME     = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );

# test the object, parameters

subtest 'fetch_memberships() returns ::Membership objects', sub {
  plan tests => 3;
  for ([3694], [3694, 2966], []) {
    my $array = $_;
    my $hashref = $ME->fetch_memberships( @{ $array } );
    test 'isa valid object for '. @$array .' mids', sub {
      if (@$array == 1) {
        # we don't have a hashref but an object
        my $mem = $hashref;
        isa_ok( $mem, 'CMS::Drupal::Modules::MembershipEntity::Membership' );
      } else {
        foreach my $mem ( values %{ $hashref } ) {
          isa_ok( $mem, 'CMS::Drupal::Modules::MembershipEntity::Membership' );
        }
      }
    }; 
  }
};

subtest 'Manually create a ::Membership object', sub {
  plan tests => 11;
 
  my %params = (
    'mid'       => 666,
    'member_id' => 999,
    'type'      => 'membership',
    'status'    => 1,
    'uid'       => 6996,
    'created'   => 1379916000,
    'changed'   => 1379987654,
    'terms'     => { 23456 => bless( {}, 'CMS::Drupal::Modules::MembershipEntity::Term' ) },
  );  
  
  dies_ok { my $mem = CMS::Drupal::Modules::MembershipEntity::Membership->new }
      'Correctly fail to create an object with no parameters provided.';

  foreach my $param (keys %params) {
    my %args = %params;
    delete $args{ $param };
    dies_ok { my $mem = CMS::Drupal::Modules::MembershipEntity::Membership->new( \%args ) }
      "Correctly fail to create object with missing parameter: $param";
  }

  my $mem;
  lives_ok { $mem = CMS::Drupal::Modules::MembershipEntity::Membership->new( %params ) }
    'Created Membership object ';
  isa_ok( $mem, 'CMS::Drupal::Modules::MembershipEntity::Membership' );

};

__END__

