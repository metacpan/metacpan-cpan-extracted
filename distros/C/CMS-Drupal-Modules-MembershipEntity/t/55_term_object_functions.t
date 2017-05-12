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

subtest 'Test a Term object', sub {

  my %params = ( 
    tid            => 666,
    mid            => 999,
    status         => 1,
    term           => '1 year',
    modifiers      => 'a:0:{}',
    start          => time - (180 * 24 * 3600), # functions are relative to "now"
    end            => time + (180 * 24 * 3600), # so test data must be, too.
    array_position => 1
  );  
 
  my $term = CMS::Drupal::Modules::MembershipEntity::Term->new( %params );
  
  isa_ok( $term, 'CMS::Drupal::Modules::MembershipEntity::Term',
    'Created a Term object ' );

  subtest 'Check static properties', sub {
    plan tests => 8;
    foreach my $prop (keys %params) {
      is( $term->{ $prop }, $params{ $prop }, $prop );
    }
  };

  subtest 'can_ok methods', sub {
    plan tests => 4;
    foreach my $method ( qw/ is_active is_current is_future was_renewal / ) {
      can_ok( $term, $method );
    }
  };

  subtest 'Validate methods', sub {
    plan tests => 16;

    is( $term->is_active, 1, 'is_active when status = 1' );
    
    for (0, 2, 3) {
      $term->{'status'} = $_;
      isnt( $term->is_active, 1, '! is_active when status = '. $_ );
    }

    my @periods = (
      [ (time - (180 * 24 * 3600)), (time + (180 * 24 * 3600)) ],
        # six months ago to six months from now 
        # is_current, ! is_future
     
      [ (time + 60), (time + ((365*24*3600)+60)) ],
        # a minute from now to a year from now
        # ! is_current, is_future

      [ (time - ((365*24*3600)+60)), (time - 60) ],
        # a year ago to a minute ago
        # ! is_current ! is_future

      [ (time + 60), (time - ((365*24*3600)+60)) ],
        # backwards, not possible
        # ! is_current, ! is_future

      [ (time + (180 * 24 * 3600)), (time - (180 * 24 * 3600)) ]
        # six months from now to six months ago, spans "now" but
        # ! is_current, ! is_future
    );

    my $count = 0;
    for ( @periods ) {
      $count++; 
      ( $term->{'start'}, $term->{'end'} ) = ( $_->[0], $_->[1] );
      
      if ($count == 1) {
        is( $term->is_current, 1, '"Six months ago" to "six months from now" is_current' );
        isnt( $term->is_future,  1, ' . . . but not is_future' );
      } elsif ($count == 2) {
        is( $term->is_current, 0, '"A minute from now" to "a year from now" ! is_current' );
        is( $term->is_future,  1, ' . . . but is_future' );
      } else {
        is( $term->is_current, 0, 'start '. $term->{start} .' & end '. $term->{end} .' is not possible' );
        is( $term->is_future,  0, 'start '. $term->{start} .' & end '. $term->{end} .' is not possible' );
      }
    }

    
    $term->{'array_position'} = 1;
    is( $term->was_renewal, 0, '! was_renewal for array_position 1' );
    
    subtest 'Various array_position values', sub {
      test 'was_renewal for array_position > 1', sub { 
        for( 2, 3, 4, 5, 42, 665, 667) {
          $term->{'array_position'} = $_;
          is( $term->was_renewal, 1, 'was_renewal for array_position '. $_ );
        }
      };
    }; 
  };
};

__END__

