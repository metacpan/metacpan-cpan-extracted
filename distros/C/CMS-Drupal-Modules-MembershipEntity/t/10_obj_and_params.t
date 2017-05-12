#! perl
use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;
use DBI;
use DBD::SQLite;

BEGIN {
  use_ok( 'CMS::Drupal::Modules::MembershipEntity' ) or die;
}

subtest 'Parameter validation and object instantiation', sub {
  plan tests => 16;

  my $dbh = DBI->connect('DBI:SQLite:dbname=:memory:', '', '', { RaiseError => 1 }); 

  can_ok( 'CMS::Drupal::Modules::MembershipEntity', 'new' );

  dies_ok { my $ME = CMS::Drupal::Modules::MembershipEntity->new() }
    'Correctly fail to instantiate an object with no parameters.';

  dies_ok { my $ME = CMS::Drupal::Modules::MembershipEntity->new( prefix => '' ) }
    'Correctly fail to instantiate an object with missing dbh parameter and empty string prefix parameter.';

  dies_ok { my $ME = CMS::Drupal::Modules::MembershipEntity->new( prefix => undef ) }
    'Correctly fail to instantiate an object with missing dbh parameter and undef prefix parameter.';

  dies_ok { my $ME = CMS::Drupal::Modules::MembershipEntity->new( prefix => $dbh ) }
    'Correctly fail to instantiate an object with missing dbh parameter and invalid prefix parameter.';

  dies_ok { my $ME = CMS::Drupal::Modules::MembershipEntity->new( prefix => 'foo' ) }
    'Correctly fail to instantiate an object with missing dbh parameter and valid prefix parameter.';

  dies_ok { my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => '' ) } 
    'Correctly fail to instantiate an object with empty string dbh parameter.';

  dies_ok { my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => undef ) } 
    'Correctly fail to instantiate an object with undef dbh parameter.';

  dies_ok { my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => 'foo' ) } 
    'Correctly fail to instantiate an object with invalid dbh parameter.';

  dies_ok { my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => 'foo', prefix => 'bar_' ) } 
    'Correctly fail to instantiate an object with invalid dbh parameter and valid prefix parameter.';

  dies_ok { my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh, prefix => '' ) }
    'Correctly fail to instantiate an object with valid $dbh and empty string prefix parameter.';

  dies_ok { my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh, prefix => $dbh ) }
    'Correctly fail to instantiate an object with valid $dbh and invalid prefix parameter.';

  my $ME;
  lives_ok { $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh ) }
    'Instantiate an object with valid $dbh and no prefix parameter.';

  isa_ok( $ME, 'CMS::Drupal::Modules::MembershipEntity' );

  my $ME2;
  lives_ok { $ME2 = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh, prefix => 'foo_' ) }
    'Instantiate an object with valid $dbh and valid prefix parameter.';

  isa_ok( $ME2, 'CMS::Drupal::Modules::MembershipEntity' );

};

__END__

