#! perl
use strict;
use warnings;

##############################################################################
#
# This is t/20_valid_drupal.t
#
# It tests the CMS::Drupal module against a real Drupal
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
# $ perl t/20_valid_drupal.t
#
#
# Alrighty then, good luck. If this seems complicated, don't worry about it.
# If the module cannot connect to your Drupal, it will tell you!
#
#############################################################################

use Cwd qw/ abs_path /;
my $me = abs_path($0);

use Test::More tests => 10;
use Test::Exception;

BEGIN {
  use_ok( 'CMS::Drupal' ) or die;
}

can_ok( 'CMS::Drupal', 'new' );

my $drupal = CMS::Drupal->new;

isa_ok( $drupal, 'CMS::Drupal' );

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
    skip "No database credentials supplied", 7, if $skip;

 ###########

 can_ok( 'CMS::Drupal', 'dbh' );
 my $dbh;
 lives_ok { $dbh = $drupal->dbh( %params ) }
   'Get a $dbh';
 isa_ok( $dbh, "DBI::db" );

 ###########

 my $sth = $dbh->column_info( undef, $dbh->{ 'Name' }, 'users', '%' );
 my @cols = map { $_->[3] } @{ $sth->fetchall_arrayref };
 my @wanted_cols = qw/ uid
                       name
                       pass
                       mail
                       theme
                       signature
                       signature_format
                       created
                       access
                       login
                       status
                       timezone
                       language
                       picture
                       init
                       data /;

 is_deeply( [ sort @cols ], [ sort @wanted_cols ],
   'Get correct column names from users table.');

 ###########

 $sth = $dbh->column_info( undef, $dbh->{ 'Name' }, 'node', '%' );
 @cols = map { $_->[3] } @{ $sth->fetchall_arrayref };
 @wanted_cols = qw/ nid
                    vid
                    type
                    language
                    title
                    uid
                    status
                    created
                    changed
                    comment
                    promote
                    sticky
                    tnid
                    translate /;

 is_deeply( [ sort @cols ], [ sort @wanted_cols ],
   'Get correct column names from node table.');

 ############

 # We know there is at least one user in a working Drupal
 #
 my $sql = qq|
   SELECT COUNT(uid) as count
   FROM users
 |;

 $sth = $dbh->prepare( $sql );

 ok( $sth->execute(), 
   'Execute a SELECT on the users table.');
 
 ok( $sth->fetchrow_hashref->{'count'} > 0,
   'SELECT COUNT(uid) from users > 0' );
 
 ##############

} # end SKIP block

__END__

