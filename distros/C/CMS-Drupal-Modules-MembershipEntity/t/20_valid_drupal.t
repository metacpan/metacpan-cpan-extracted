#! perl
use strict;
use warnings;

##############################################################################
#
# This is t/20_valid_drupal.t It tests the 
# CMS::Drupal::Modules::MembershipEntity module against a real Drupal
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
# $ DRUPAL_TEST_CREDS=database,foo,driver,SQLite
# $ perl t/20_valid_drupal.t
#
# If you report a bug or ask for support for this module, the first thing I 
# will ask for is the output from these tests, so make sure and do this, 'k?
#
# You really should want to know if your setup is working, anyway.
#
#############################################################################

use Cwd qw/ abs_path /;
my $me = abs_path($0);

use Test::More tests => 3;
use Test::Exception;

use CMS::Drupal;
use CMS::Drupal::Modules::MembershipEntity;

my %params;
my $skip = 0;

if ( exists $ENV{'DRUPAL_TEST_CREDS'} ) { 
  %params = ( split ',', $ENV{'DRUPAL_TEST_CREDS'} );
} else {
  print  <<EOT;

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
  skip 'No database credentials supplied', 3, if $skip;

  my $drupal;
  my $dbh;

  subtest 'Object instantiation', sub {
    plan tests => 3;

    can_ok( 'CMS::Drupal', 'new' );
    lives_ok { $drupal = CMS::Drupal->new };
    isa_ok( $drupal, 'CMS::Drupal');
  };

  subtest 'Connect to the Drupal', sub {
    plan tests => 3;

    can_ok( 'CMS::Drupal', 'dbh' );
    lives_ok { $dbh = $drupal->dbh( %params ) };
    isa_ok( $dbh, 'DBI::db');
  };

  subtest 'Test membership_entity* tables', sub {
    plan tests => 6;

    my $sth1 = $dbh->column_info( undef, $dbh->{ 'Name' }, 'membership_entity', '%' );
    my @cols1 = map { $_->[3] } @{ $sth1->fetchall_arrayref };
    my @wanted_cols1 = qw/ mid
                           member_id
                           type
                           uid
                           status
                           created
                           changed /;

    is_deeply( [ sort @cols1 ], [ sort @wanted_cols1 ],
      'Get correct column names from membership_entity table.');

    ###########

    my $sth2 = $dbh->column_info( undef, $dbh->{ 'Name' }, 'membership_entity_term', '%' );
    my @cols2 = map { $_->[3] } @{ $sth2->fetchall_arrayref };
    my @wanted_cols2 = qw/ id
                           mid
                           status
                           term
                           modifiers
                           start
                           end /; ## new cols qw/ start end timezone / ignored for now
    my %cols2 = map { $_ => 1 } @cols2;
    my $count = 0;
    for (@wanted_cols2) {
      $count++ if $cols2{ $_ };
    }

    is( $count, scalar @wanted_cols2,
      'Get correct column names from membership_entity_terms table.');

    #is_deeply( [ sort @cols2 ], [ sort @wanted_cols2 ],
    #  'Get correct column names from membership_entity_terms table.');

    ############
 
    my $sth3 = $dbh->column_info( undef, $dbh->{ 'Name' }, 'membership_entity_type', '%' );
    my @cols3 = map { $_->[3] } @{ $sth3->fetchall_arrayref };
    my @wanted_cols3 = qw/ id
                          type
                          label
                          weight
                          description
                          data
                          status
                          module /;

    is_deeply( [ sort @cols3 ], [ sort @wanted_cols3 ],
      'Get correct column names from membership_entity_type table.');

    ############

    my $sth4 = $dbh->column_info( undef, $dbh->{ 'Name' }, 'membership_entity_secondary_member', '%' );
    my @cols4 = map { $_->[3] } @{ $sth4->fetchall_arrayref };
    my @wanted_cols4 = qw/ mid
                           uid
                           weight /;
  
    is_deeply( [ sort @cols4 ], [ sort @wanted_cols4 ],
      'Get correct column names from membership_entity_secondary_member table.' );
  
    ############
  
    # We know there is at least one Membership type in a working installation
    
    my $sql56 = qq|
      SELECT COUNT(id) AS count
      FROM membership_entity_type
    |;
  
    my $sth56 = $dbh->prepare( $sql56 );
  
    ok( $sth56->execute(),
      'Execute a SELECT on the membership_entity_type table.' );
  
    ok( $sth56->fetchrow_hashref->{'count'} > 0,
      'SELECT COUNT(id) FROM membership_entity_type > 0' );
    
    # But we can't assume anything else, even that there is a single row in the
    # membership_entity or membership_entity_term tables, so we can't really 
    # test anything else ...
    #
    # We'll test the functionality with a test DB in the next test
    
  };

} # end SKIP block

__END__

