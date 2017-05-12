#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 53;
use Test::Exception;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::User' ); }
BEGIN { use_ok( 'Apache::Sling::Group' ); }

# test group name:
my $test_group1 = "g-group_test_group_1_$$";
my $test_group2 = "g-group_test_group_2_$$";
my $test_group3 = "g-group_test_group_3_$$";
# test properties:
my @test_properties;

# test user name:
my $test_user = "group_test_user_$$";
# test user pass:
my $test_pass = "pass";
# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;
$sling->{'Verbose'} = $verbose;
$sling->{'Log'}     = $log;
# authn object:
my $authn = Apache::Sling::Authn->new( \$sling);
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
ok( $authn->login_user(), "log in successful" );
# user object:
my $user = Apache::Sling::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Apache::Sling::User', 'user';
# group object:
my $group = Apache::Sling::Group->new( \$authn, $verbose, $log );
isa_ok $group, 'Apache::Sling::Group', 'group';

# Run tests:
ok( defined $group,
    "Group Test: Sling Group Object successfully created." );
ok( defined $user,
    "Group Test: Sling User Object successfully created." );
# Check viewing non-existent group:
ok( ! $group->view( "non-existent-$test_group1" ),
    "Group Test: check viewing non-existent group fails." );
# create groups:
ok( $group->add( $test_group1, \@test_properties ),
    "Group Test: Group \"$test_group1\" added successfully." );
ok( $group->check_exists( $test_group1 ),
    "Group Test: Group \"$test_group1\" exists." );
ok( $group->add( $test_group2, \@test_properties ),
    "Group Test: Group \"$test_group2\" added successfully." );
ok( $group->check_exists( $test_group2 ),
    "Group Test: Group \"$test_group2\" exists." );
ok( $group->add( $test_group3, \@test_properties ),
    "Group Test: Group \"$test_group3\" added successfully." );
ok( $group->check_exists( $test_group3 ),
    "Group Test: Group \"$test_group3\" exists." );

# Test creating group that already exists:
ok( ! $group->add( $test_group1, \@test_properties ),
    "Group Test: adding group that already exists fails." );

# Add test user:
ok( $user->add( $test_user, $test_pass, \@test_properties ),
    "Group Test: User \"$test_user\" added successfully." );
ok( $user->check_exists( $test_user ),
    "Group Test: User \"$test_user\" exists." );
    
# Testing group addition from file
# test group name:
my $test_upload_group1 = "group_test_upload_group_1_$$";
my $test_upload_group2 = "group_test_upload_group_2_$$";
my $test_upload_group3 = "group_test_upload_group_3_$$";
my $test_upload_group4 = "group_test_upload_group_4_$$";

my $upload = "group\n$test_upload_group1";
ok( $group->add_from_file(\$upload,0,1), 'Check add_from_file function' );
$upload = "group\n$test_upload_group2\n$test_upload_group3\n$test_upload_group4";
ok( $group->add_from_file(\$upload,0,3), 'Check add_from_file function with three forks' );
$upload = "bad_heading\n$test_upload_group1";
throws_ok{ $group->add_from_file(\$upload,0,1); } qr%First CSV column must be the group ID, column heading must be "group". Found: "bad_heading".%, 'Check add_from_file function with bad heading';
$upload = "group\n$test_upload_group1,bad_extra_column";
throws_ok{ $group->add_from_file(\$upload,0,1); } qr%Found "2" columns. There should have been "1".%, 'Check add_from_file function with heading / data count mismatch';
$upload = "group,property\n$test_upload_group2,test";
ok( $group->add_from_file(\$upload,0,1), 'Check add_from_file function with extra property specified' );

# Cleanup Users:
ok( $user->del( $test_user ),
    "Group Test: User \"$test_user\" deleted successfully." );
ok( ! $user->check_exists( $test_user ),
    "Group Test: User \"$test_user\" no longer exists." );

# Cleanup Groups:
ok( $group->del( $test_group1 ),
    "Group Test: Group \"$test_group1\" deleted successfully." );
ok( $group->del( $test_group2 ),
    "Group Test: Group \"$test_group2\" deleted successfully." );
ok( $group->del( $test_group3 ),
    "Group Test: Group \"$test_group3\" deleted successfully." );
ok( $group->del( $test_upload_group1 ),
    "User Test: User \"$test_upload_group1\" deleted successfully." );
ok( $group->del( $test_upload_group2 ),
    "User Test: User \"$test_upload_group2\" deleted successfully." );
ok( ! $group->del( $test_upload_group3 ),
    "User Test: Deleting non-existent group fails." );
ok( $group->del( $test_upload_group4 ),
    "User Test: User \"$test_upload_group4\" deleted successfully." );
ok( ! $group->check_exists( $test_group1 ),
    "Group Test: Group \"$test_group1\" should no longer exist." );
ok( ! $group->check_exists( $test_group2 ),
    "Group Test: Group \"$test_group2\" should no longer exist." );
ok( ! $group->check_exists( $test_group3 ),
    "Group Test: Group \"$test_group3\" should no longer exist." );
ok( ! $group->check_exists( $test_upload_group1 ),
    "User Test: User \"$test_upload_group1\" should no longer exist." );
ok( ! $group->check_exists( $test_upload_group2 ),
    "User Test: User \"$test_upload_group2\" should no longer exist." );
ok( ! $group->check_exists( $test_upload_group4 ),
    "User Test: User \"$test_upload_group4\" should no longer exist." );

# group object:
$group = Apache::Sling::Group->new( \$authn, $verbose, $log );
isa_ok $group, 'Apache::Sling::Group', 'group';

# add group:
ok( my $group_config = Apache::Sling::Group->config($sling), 'check group_config function' );
$group_config->{'add'} = \$test_group1;
ok( Apache::Sling::Group->run($sling,$group_config), q{check group_run function add for $test_group1} );

# Test group additions from file:
my ( $tmp_group_additions_handle, $tmp_group_additions_name ) = File::Temp::tempfile();
ok( $group_config = Apache::Sling::Group->config($sling), 'check group_config function' );
$group_config->{'additions'} = \$tmp_group_additions_name;
ok( Apache::Sling::Group->run($sling,$group_config), q{check group_run function additions} );
unlink( $tmp_group_additions_name ); 

# view and check group exists:
ok( $group_config = Apache::Sling::Group->config($sling), 'check group_config function' );
$group_config->{'view'} = \$test_group1;
ok( Apache::Sling::Group->run($sling,$group_config), q{check group_run function view for $test_group1} );

ok( $group_config = Apache::Sling::Group->config($sling), 'check group_config function' );
$group_config->{'exists'} = \$test_group1;
ok( Apache::Sling::Group->run($sling,$group_config), q{check group_run function check exists for $test_group1} );

# Cleanup group:
ok( $group_config = Apache::Sling::Group->config($sling), 'check group_config function' );
$group_config->{'delete'} = \$test_group1;
ok( Apache::Sling::Group->run($sling,$group_config), q{check group_run function delete for $test_group1} );

ok( ! $group->check_exists( $test_group1 ),
    "Sling Test: Group \"$test_group1\" should no longer exist." );
