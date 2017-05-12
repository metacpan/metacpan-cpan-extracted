#! perl
use strict;
use warnings;

use Test::More tests => 18;
use Test::Exception;

BEGIN {
  $ENV{'DRUPAL_IGNORE_TEST_CREDS'} = 1;
  use_ok( 'CMS::Drupal' ) or die;
}

can_ok( 'CMS::Drupal', 'new' );

my $drupal;
lives_ok { $drupal = CMS::Drupal->new }
  'Instantiate $drupal';

isa_ok( $drupal, 'CMS::Drupal' );

can_ok( 'CMS::Drupal', 'dbh' );

dies_ok { $drupal->dbh(driver => 'bar') }
  'Correctly fail to connect with missing database param.';

dies_ok { $drupal->dbh(database => '', driver => 'bar') }
  'Correctly fail to connect with empty string for database param.';

dies_ok { $drupal->dbh(database => 'foo') }
  'Correctly fail to connect with missing driver param.';

dies_ok { $drupal->dbh(database => 'foo', driver => '') }
  'Correctly fail to connect with empty driver param.';

dies_ok { $drupal->dbh(database => 'foo', driver => []) }
  'Correctly fail to connect with non-string for driver [array].';

dies_ok { $drupal->dbh(database => 'foo', driver => 'bar') }
  'Correctly fail to connect with unknown driver param.';

dies_ok { $drupal->dbh(database => 'foo', driver => 'Pg', username => []) }
  'Correctly fail to connect with non-string for username [array].';

dies_ok { $drupal->dbh(database => 'foo', driver => 'Pg', password => []) }
  'Correctly fail to connect with non-string for password [array].';

dies_ok { $drupal->dbh(database => 'foo', driver => 'Pg', host => []) }
  'Correctly fail to connect with non-string for host [array].';

dies_ok { $drupal->dbh(database => 'foo', driver => 'Pg', port => []) }
  'Correctly fail to connect with non-string for port [array].';

dies_ok { $drupal->dbh(database => 'foo', driver => 'Pg', port => 'baz') }
  'Correctly fail to connect with non-integer for port [string].';

dies_ok { $drupal->dbh(database => 'foo', driver => 'Pg', prefix  => '') }
  'Correctly fail to connect with empty string for prefix.';

dies_ok { $drupal->dbh(database => 'foo', driver => 'Pg', prefix  => []) }
  'Correctly fail to connect with non-string for prefix [array].';

__END__

