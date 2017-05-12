#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 31;
use Test::Exception;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::User' ); }

# test user names:
my $test_user1 = "authn_test_user_1_$$";
my $test_user2 = "authn_test_user_2_$$";

# test user pass:
my $test_pass = "pass";

# test properties:
my @test_properties;

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'User'}    = $super_user;
$sling->{'Log'}     = $log;

# Check creating authn object fails with bad password:
$sling->{'Pass'}    = 'badpasswordwillnotwork';
# Check creation with verbosity turned up:
$sling->{'Verbose'} = 3;
my $authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
throws_ok{ $authn->login_user() } qr%Basic Auth log in for user "$super_user" at URL "$sling_host" was unsuccessful%, 'Check authn object creation croaks with bad password and high verbosity';
# reset verbosity level:
$sling->{'Verbose'} = $verbose;
$authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
throws_ok{ $authn->login_user() } qr%Basic Auth log in for user "$super_user" at URL "$sling_host" was unsuccessful%, 'Check authn object creation croaks with bad password and default verbosity';

# Set the password to something that should work!
$sling->{'Pass'}    = $super_pass;

# Check creating authn object fails with unsupported auth type:
$sling->{'Auth'}    = 'badauthtypewillnotwork';
$authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
throws_ok{ $authn->login_user() } qr/Unsupported auth type: "badauthtypewillnotwork"/, 'Check authn object creation croaks with unsupported auth type';

# Set the auth type to something that should work!
$sling->{'Auth'}    = undef;

# authn object:
$sling->{'Verbose'} = 3;
$authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
ok( $authn->login_user(), "log in successful" );
$sling->{'Verbose'} = $verbose;
$authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
ok( $authn->login_user(), "log in successful" );
# user object:
my $user = Apache::Sling::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Apache::Sling::User', 'user';

# Run tests:
ok( defined $user,
    "Authn Test: Sling User Object successfully created." );

# Add two users:
ok( $user->add( $test_user1, $test_pass, \@test_properties ),
    "Authn Test: User \"$test_user1\" added successfully." );
ok( $user->check_exists( $test_user1 ),
    "Authn Test: User \"$test_user1\" exists." );
ok( $user->add( $test_user2, $test_pass, \@test_properties ),
    "Authn Test: User \"$test_user2\" added successfully." );
ok( $user->check_exists( $test_user2 ),
    "Authn Test: User \"$test_user2\" exists." );

throws_ok{ $authn->switch_user( $test_user1, $test_pass, "badauthtypewillnotwork", 1 ) } qr/Unsupported auth type: "badauthtypewillnotwork"/, 'Check switch_user croaks with unsupported auth type';
throws_ok{ $authn->switch_user( "baduser", "badpassword", "basic", 1 ) } qr/Basic Auth log in for user "baduser" at URL "$sling_host" was unsuccessful/, 'Check switch_user croaks with bad credentials';
throws_ok{ $authn->switch_user( $super_user, "badpassword", "basic", 1 ) } qr/Basic Auth log in for user "$super_user" at URL "$sling_host" was unsuccessful/, 'Check switch_user croaks with bad password';
ok( $authn->switch_user( $test_user1, $test_pass, "basic", 1 ),
    "Authn Test: Successfully switched to user: \"$test_user1\" with basic auth" );
ok( $authn->switch_user( $test_user1, $test_pass, "basic", 1 ),
    "Authn Test: Successfully stayed as user: \"$test_user1\"" );
ok( $authn->switch_user( $test_user2, $test_pass, "basic", 1 ),
    "Authn Test: Successfully switched to user: \"$test_user2\" with basic auth" );
$authn->{'Verbose'} = 3;
ok( $authn->switch_user( $super_user, $super_pass, "basic", 1 ),
    "Authn Test: Successfully switched back to user: \"$super_user\" with basic auth" );
$authn->{'Verbose'} = $verbose;

ok( $user->del( $test_user1 ),
    "Authn Test: User \"$test_user1\" deleted successfully." );
ok( ! $user->check_exists( $test_user1 ),
    "Authn Test: User \"$test_user1\" should no longer exist." );
ok( $user->del( $test_user2 ),
    "Authn Test: User \"$test_user2\" deleted successfully." );
ok( ! $user->check_exists( $test_user2 ),
    "Authn Test: User \"$test_user2\" should no longer exist." );
