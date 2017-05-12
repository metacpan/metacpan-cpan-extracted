#! perl
use strict;
use warnings;

BEGIN {
  ## Make sure we don't connect to our real DB if we
  ## have given the credentials for it
  $ENV{'DRUPAL_IGNORE_TEST_CREDS'} = 1;
}

use Test::More tests => 1;
use Test::Group;

use CMS::Drupal;
use CMS::Drupal::Modules::MembershipEntity;
use CMS::Drupal::Modules::MembershipEntity::Test;

my $drupal = CMS::Drupal->new;
my $dbh    = build_test_db( $drupal );
my $ME     = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );

# test the object functions

subtest 'Test a Membership object', sub {
 
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
  
  my $mem = CMS::Drupal::Modules::MembershipEntity::Membership->new( %params );
  
  isa_ok( $mem, 'CMS::Drupal::Modules::MembershipEntity::Membership',
    'Created a Membership object ' );

  subtest 'Check static properties', sub {
    plan tests => 8;
    foreach my $prop (keys %params) {
      is( $mem->{ $prop }, $params{ $prop }, $prop );
    }
  };

  subtest 'can_ok methods', sub {
    plan tests => 2;
    foreach my $method ( qw/ is_active has_renewal / ) {
      can_ok( $mem, $method );
    }
  };

  subtest 'Validate methods', sub {
    plan tests => 7;

    is( $mem->is_active, 1, 'is_active when status = 1' );
    
    for (0, 2, 3) {
      $mem->{'status'} = $_;
      isnt( $mem->is_active, 1, 'not is_active when status = '. $_ );
    }

    $mem->{'terms'} = {
                       '4088' => bless( {
                                         'array_position' => 2,
                                         'status'         => 1,
                                         'tid'            => 4088,
                                         'term'           => 'import',
                                         'end'            => (time + (365*24*3600) + 60),
                                         'mid'            => 4086,
                                         'modifiers'      => 'a:0:{}',
                                         'start'          => (time + 60)
                                        }, 'CMS::Drupal::Modules::MembershipEntity::Term' ),
                       '3920' => bless( {
                                         'array_position' => 1,
                                         'status'         => 0,
                                         'tid'            => 3920,
                                         'term'           => 'import',
                                         'end'            => 1403247600,
                                         'mid'            => 4086,
                                         'modifiers'      => 'a:0:{}',
                                         'start'          => 1308639600
                                        }, 'CMS::Drupal::Modules::MembershipEntity::Term' )
                      };
    is( $mem->has_renewal, 1, 'has_renewal when term is_future and is_active' );
    
    # future term must be active to count for has_renewal
    $mem->{'terms'}->{'4088'}->{'status'} = 0;
    isnt( $mem->has_renewal, 1, '! has_renewal when term is_future but not is_active' );

    $mem->{'terms'} = { 
                       '3920' => bless( {
                                         'array_position' => 1,
                                         'status'         => 0,
                                         'tid'            => 3920,
                                         'term'           => 'import',
                                         'end'            => 1403247600,
                                         'mid'            => 4086,
                                         'modifiers'      => 'a:0:{}',
                                         'start'          => 1308639600
                                        }, 'CMS::Drupal::Modules::MembershipEntity::Term' )
                       };  
    isnt( $mem->has_renewal, 1, '! has_renewal when not term is_future' );

  };
};

__END__

