#! perl
use strict;
use warnings;

##############################################################################
#
# This is t/40_admin_maintenance_mode.t
#
# It tests the CMS::Drupal::Admin::MaintenanceMode  module against a real Drupal
# database. It looks in your environment to see if you have provided
# connection information.
#
# So if you want to test against your Drupal DB, you must set the variable
#
# DRUPAL_TEST_CREDS
#
# in your environment, exactly as follows:
#
# required fields are 
#   database - name of your DB
#   driver   - your dbi:driver ... mysql, Pg or SQLite
#
# optional fields are
#   user     - your DB user name
#   password - your DB password
#   host     - your DB server hostname
#   port     - which port to connect on
#   prefix   - your database table schema prefix, if any
#
# All these fields and values must be joined together in one string with no
# spaces, and separated with commas.
#
# Examples:
#
# database,foo,driver,SQLite
# database,foo,driver,Pg
# database,foo,driver,mysql,user,bar,password,baz,host,localhost,port,3306,prefix,My_
#
# You can set an environment variable in many ways. To make it semi permanent,
# put it in your .bashrc or .bash_profile or whatever you have.
#
# If you just want to run this test once, you can just do this from your
# command prompt:
#
# $ DRUPAL_TEST_CREDS=database,foo,driver,SQLite;
# $ perl t/40_admin_maintenance_mode.t
#
#
# Alrighty then, good luck. If this seems complicated, don't worry about it.
# If the module cannot connect to your Drupal, it will tell you!
#
#############################################################################

use Cwd qw/ abs_path /;
my $me = abs_path($0);

use Test::More tests => 22;
use Test::Exception;

use CMS::Drupal;

BEGIN {
  use_ok( 'CMS::Drupal::Admin::MaintenanceMode', '-all' ) or die;
}

can_ok( 'CMS::Drupal::Admin::MaintenanceMode', 'maintenance_mode_on' );
can_ok( 'CMS::Drupal::Admin::MaintenanceMode', 'maintenance_mode_off' );
can_ok( 'CMS::Drupal::Admin::MaintenanceMode', 'maintenance_mode_check' );

my $drupal = CMS::Drupal->new;

my %params;
my $skip = 0;

if ( exists $ENV{'DRUPAL_TEST_CREDS'} ) {
  %params = ( split ',', $ENV{'DRUPAL_TEST_CREDS'} );
} else {
  print <<EOT;

  No database credentials found in ENV. 
  Skipping Drupal database tests.

  If you want to run these tests in the future,
  set the value of DRUPAL_TEST_CREDS in your ENV as
  documented in the source of this file,
  $me

EOT

  $skip++;
}

SKIP: {
  skip "No database credentials supplied", 18, if $skip;

  ###########

  my $dbh;
  lives_ok { $dbh = $drupal->dbh( %params ) } 'Get a $dbh';
  isa_ok( $dbh, "DBI::db" );

  my $rv1;
  lives_ok {
    $rv1 = $dbh->do( qq/
      UPDATE variable
      SET value = 'i:1;'
      WHERE name = 'maintenance_mode'
    /)
  } 'Manually set maintenance mode in the DB';

  my $rv2;
  lives_ok {
    $rv2 = $dbh->do( qq/
      DELETE FROM cache_bootstrap
      WHERE cid = 'variables'
    /)
  } 'Manually clear the cache in the DB';

  cmp_ok( $rv1, '>=', 0, 'Maintenance mode set to on for testing' );
  cmp_ok( $rv2, '>=', 0, 'cache_bootstrap.cid.maintenance_mode deleted for testing' );
  is( maintenance_mode_check( $dbh ), 1, 'maintenance_mode_check for on' );

  my $rv3;
  lives_ok {
    $rv3 = $dbh->do( qq/ 
      UPDATE variable
      SET value = 'i:0;'
      WHERE name = 'maintenance_mode'
    /)
  } 'Manually unset maintenance mode in the DB';

  my $rv4;
  lives_ok { 
    $rv4 = $dbh->do( qq/
      DELETE FROM cache_bootstrap
      WHERE cid = 'variables'
    /)
  } 'Manually clear the cache in the DB';

  cmp_ok( $rv3, '>=', 0, 'Maintenance mode set to off for testing' );
  cmp_ok( $rv4, '>=', 0, 'cache_bootstrap.cid.maintenance_mode deleted for testing' );
  is( maintenance_mode_check( $dbh ), 0, 'maintenance_mode_check for off' );
  
  my $db_lookup = qq/ SELECT value FROM variable WHERE name = 'maintenance_mode' /;

  is( maintenance_mode_on( $dbh ),        1,      'maintenance_mode_on' );
  is( maintenance_mode_check( $dbh ),     1,      'maintenance_mode_check agrees' );
  is( $dbh->selectrow_array( $db_lookup), 'i:1;', 'DB lookup agrees' );
  
  is( maintenance_mode_off( $dbh ),       1,      'maintenance_mode_off' );
  is( maintenance_mode_check( $dbh ),     0,      'maintenance_mode_check agrees' );
  is( $dbh->selectrow_array( $db_lookup), 'i:0;', 'DB lookup agrees' );
 
} # end SKIP block

__END__

