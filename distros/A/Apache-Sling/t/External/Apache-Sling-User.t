#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 67;
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
BEGIN { use_ok( 'Apache::Sling::GroupMember' ); }

# test user name:
my $test_user = "user_test_user_$$";
# test user pass:
my $test_pass = "pass";
my $test_pass1 = "pass1";
my $test_pass2 = "pass2";
# test user new pass:
my $test_pass_new = "passnew";
# test properties:
my @test_properties;

# test group name:
my $test_group = "g-user_test_group_$$";

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;
$sling->{'Verbose'} = $verbose;
$sling->{'Log'}     = $log;

# Check error is thrown without auth:
throws_ok{ my $user = Apache::Sling::User->new(); } qr%no authn provided!%, 'Check user creation croaks with authn missing';

# authn object:
my $authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
ok( $authn->login_user(), "log in successful" );
# user object:
my $user = Apache::Sling::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Apache::Sling::User', 'user';
# group object:
my $group = Apache::Sling::Group->new( \$authn, $verbose, $log );
isa_ok $group, 'Apache::Sling::Group', 'group';
# group member object:
my $group_member = Apache::Sling::GroupMember->new( \$authn, $verbose, $log );
isa_ok $group_member, 'Apache::Sling::GroupMember', 'group_member';

# Run tests:
ok( defined $user,
    "User Test: Sling User Object successfully created." );
ok( defined $group,
    "User Test: Sling Group Object successfully created." );

# add user:
ok( $user->add( $test_user, $test_pass, \@test_properties ),
    "User Test: User \"$test_user\" added successfully." );
ok( $user->check_exists( $test_user ),
    "User Test: User \"$test_user\" exists." );
ok( ! $user->add( $test_user, $test_pass, \@test_properties ),
    "User Test: Already existing User \"$test_user\" not added successfully again." );

# Check can update properties:
@test_properties = ( "user_test_editor=$super_user" );
ok( $user->update( $test_user, \@test_properties ),
    "User Test: User \"$test_user\" updated successfully." );
ok( ! $user->update( "non-existent-$test_user", \@test_properties ),
    "User Test: non-existent user properties not updated successfully." );

# Check can update properties after addition pf user to group:
# http://jira.sakaiproject.org/browse/KERN-270
# create group:
ok( $group->add( $test_group, \@test_properties ),
    "User Test: Group \"$test_group\" added successfully." );
ok( $group->check_exists( $test_group ),
    "User Test: Group \"$test_group\" exists." );
# Add member to group:
ok( $group_member->add( $test_group, $test_user ),
    "User Test: Member \"$test_user\" added to \"$test_group\"." );
ok( $group_member->check_exists( $test_group, $test_user ),
    "User Test: Member \"$test_user\" exists in \"$test_group\"." );
# Check can still update properties:
@test_properties = ( "user_test_edit_after_group_join=true" );
ok( $user->update( $test_user, \@test_properties ),
    "User Test: User \"$test_user\" updated successfully." );
# Delete test user from group:
ok( $group_member->del( $test_group, $test_user ),
    "User Test: Member \"$test_user\" deleted from \"$test_group\"." );
ok( ! $group_member->check_exists( $test_group, $test_user ),
    "User Test: Member \"$test_user\" should no longer exist in \"$test_group\"." );
# Cleanup Group:
ok( $group->del( $test_group ),
    "User Test: Group \"$test_group\" deleted successfully." );
ok( ! $group->check_exists( $test_group ),
    "User Test: Group \"$test_group\" should no longer exist." );

# Switch to test_user
ok( $authn->switch_user( $test_user, $test_pass ),
    "User Test: Successfully switched to user: \"$test_user\" with basic auth" );

# Check can update properties:
@test_properties = ( "user_test_editor=$test_user" );
ok( $user->update( $test_user, \@test_properties ),
    "User Test: User \"$test_user\" updated successfully." );

# switch back to admin user:
ok( $authn->switch_user( $super_user, $super_pass ),
    "User Test: Successfully switched to user: \"$super_user\" with basic auth" );

# Change user's password:
ok( $user->change_password( $test_user, $test_pass, $test_pass_new, $test_pass_new ),
    "User Test: Successfully changed password from \"$test_pass\" to \"$test_pass_new\" for user: \"$test_user\"");
ok( ! $user->change_password( "non-existent-$test_user", $test_pass, $test_pass_new, $test_pass_new ),
    "User Test: non-existent user password change not successful");

# Switch to test_user with new pass:
ok( $authn->switch_user( $test_user, $test_pass_new ),
    "User Test: Successfully switched to user: \"$test_user\" with basic auth and new pass" );

# switch back to admin user:
ok( $authn->switch_user( $super_user, $super_pass ),
    "User Test: Successfully switched to user: \"$super_user\" with basic auth" );

# Testing view for user:
ok( $user->view( $test_user ),
    "User Test: User \"$test_user\" viewed successfully." );
ok( ! $user->view( "non-existent-$test_user" ),
    "User Test: non-existent user not viewed successfully." );

# Testing user addition from file
# test user name:
my $test_upload_user1 = "user_test_upload_user_1_$$";
my $test_upload_user2 = "user_test_upload_user_2_$$";
my $test_upload_user3 = "user_test_upload_user_3_$$";
my $test_upload_user4 = "user_test_upload_user_4_$$";

my $upload = "user,password\n$test_upload_user1,$test_pass";
ok( $user->add_from_file(\$upload,0,1), 'Check add_from_file function' );
$upload = "user,password\n$test_upload_user2,$test_pass\n$test_upload_user3,$test_pass\n$test_upload_user4,$test_pass";
ok( $user->add_from_file(\$upload,0,3), 'Check add_from_file function with three forks' );
$upload = "user,bad_heading\n$test_upload_user1,$test_pass";
throws_ok{ $user->add_from_file(\$upload,0,1); } qr%Second CSV column must be the user password, column heading must be "password". Found: "bad_heading".%, 'Check add_from_file function with bad second heading';
$upload = "user,password\n$test_upload_user1,$test_pass,bad_extra_column";
throws_ok{ $user->add_from_file(\$upload,0,1); } qr%Found "3" columns. There should have been "2".%, 'Check add_from_file function with heading / data count mismatch';
$upload = "user,password,property\n$test_upload_user2,$test_pass,test";
ok( $user->add_from_file(\$upload,0,1), 'Check add_from_file function with extra property specified' );

# Check user deletion:
ok( ! $user->del( "non-existent-$test_user" ),
    "User Test: non-existent user not deleted successfully." );
ok( $user->del( $test_user ),
    "User Test: User \"$test_user\" deleted successfully." );
ok( $user->del( $test_upload_user1 ),
    "User Test: User \"$test_upload_user1\" deleted successfully." );
ok( $user->del( $test_upload_user2 ),
    "User Test: User \"$test_upload_user2\" deleted successfully." );
ok( $user->del( $test_upload_user4 ),
    "User Test: User \"$test_upload_user4\" deleted successfully." );
ok( ! $user->check_exists( $test_user ),
    "User Test: User \"$test_user\" should no longer exist." );
ok( ! $user->check_exists( $test_upload_user1 ),
    "User Test: User \"$test_upload_user1\" should no longer exist." );
ok( ! $user->check_exists( $test_upload_user2 ),
    "User Test: User \"$test_upload_user2\" should no longer exist." );
ok( ! $user->check_exists( $test_upload_user4 ),
    "User Test: User \"$test_upload_user4\" should no longer exist." );

# user object:
$user = Apache::Sling::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Apache::Sling::User', 'user';

# add user:

ok( my $user_config = Apache::Sling::User->config($sling), 'check user_config function' );
$user_config->{'add'} = \$test_user;
$user_config->{'email'} = \"test\@example.com";
$user_config->{'first-name'} = \"test";
$user_config->{'last-name'} = \"test";
$user_config->{'password'} = \$test_pass1;
ok( Apache::Sling::User->run($sling,$user_config), q{check user_run function adding user $test_user} );

ok( $user_config = Apache::Sling::User->config($sling), 'check user_config function' );
$user_config->{'exists'} = \$test_user;
ok( Apache::Sling::User->run($sling,$user_config), q{check user_run function check exists user $test_user} );

ok( $user_config = Apache::Sling::User->config($sling), 'check user_config function' );
$user_config->{'view'} = \$test_user;
ok( Apache::Sling::User->run($sling,$user_config), q{check user_run function view user $test_user} );

ok( $user_config = Apache::Sling::User->config($sling), 'check user_config function' );
$user_config->{'update'} = \$test_user;
ok( Apache::Sling::User->run($sling,$user_config), q{check user_run function update user $test_user} );

ok( $user_config = Apache::Sling::User->config($sling), 'check user_config function' );
$user_config->{'change-password'} = \$test_user;
$user_config->{'password'} = \$test_pass1;
$user_config->{'new-password'} = \$test_pass2;
ok( Apache::Sling::User->run($sling,$user_config), q{check user_run function update user $test_user} );

my ( $tmp_user_additions_handle, $tmp_user_additions_name ) = File::Temp::tempfile();
ok( $user_config = Apache::Sling::User->config($sling), 'check user_config function' );
$user_config->{'additions'} = \$tmp_user_additions_name;
ok( Apache::Sling::User->run($sling,$user_config), q{check user_run function additions} );
unlink( $tmp_user_additions_name ); 

# Cleanup user:
ok( $user_config = Apache::Sling::User->config($sling), 'check user_config function' );
$user_config->{'delete'} = \$test_user;
ok( Apache::Sling::User->run($sling,$user_config), q{check user_run function delete user $test_user} );
ok( ! $user->check_exists( $test_user ),
    "Sling Test: User \"$test_user\" should no longer exist." );
