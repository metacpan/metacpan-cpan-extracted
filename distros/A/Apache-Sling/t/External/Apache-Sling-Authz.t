#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 29;
use Test::Exception;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Authn' ); }
BEGIN { use_ok( 'Apache::Sling::Authz' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }
BEGIN { use_ok( 'Apache::Sling::User' ); }

# test user name:
my $test_user = "user_test_user_$$";
# test user pass:
my $test_pass = "pass";

# test content name:
my $test_content1 = "content_test_content_1_$$";
# test properties:
my @test_properties;
# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
$sling->{'URL'}     = $sling_host;
$sling->{'User'}    = $super_user;
$sling->{'Pass'}    = $super_pass;
$sling->{'Verbose'} = $verbose;
$sling->{'Log'}     = $log;
# authn object:
my $authn = Apache::Sling::Authn->new( \$sling );
isa_ok $authn, 'Apache::Sling::Authn', 'authentication';
ok( $authn->login_user(), "log in successful" );
# content object:
my $content = Apache::Sling::Content->new( \$authn, $verbose, $log );
isa_ok $content, 'Apache::Sling::Content', 'content';
# authz object:
my $authz = Apache::Sling::Authz->new( \$authn, $verbose, $log );
isa_ok $authz, 'Apache::Sling::Authz', 'authz';
# user object:
my $user = Apache::Sling::User->new( \$authn, $verbose, $log );
isa_ok $user, 'Apache::Sling::User', 'user';

# Run tests:
ok( $content->add( $test_content1, \@test_properties ),
    "Content Test: Content \"$test_content1\" added successfully." );

ok ( ! $authz->get_acl( 'bad_content_does_not_exist' ), 'Check get_acl function with bad content location' );

ok( $authz->get_acl( $test_content1 ),
    "Authz Test: Content \"$test_content1\" ACL fetched successfully." );

my @grant_privileges;
my @deny_privileges;

# add user:
ok( $user->add( $test_user, $test_pass ),
    "User Test: User \"$test_user\" added successfully." );

ok( $authz->modify_privileges( $test_content1, $test_user, \@grant_privileges, \@deny_privileges ),
    "Authz Test: Content \"$test_content1\" ACL privileges successfully modified." );

ok( ! $authz->modify_privileges( 'bad_content_does_not_exist', $test_user, \@grant_privileges, \@deny_privileges ),
    "Authz Test: Content \"bad_content_does_not_exist\" ACL privileges not modified." );

push @grant_privileges, 'read';

ok( $authz->modify_privileges( $test_content1, $test_user, \@grant_privileges, \@deny_privileges ),
    "Authz Test: Content \"$test_content1\" ACL privileges successfully modified." );

ok( ! $authz->del( 'bad_content_does_not_exist', $test_user ),
    "Authz Test: Content \"bad_content_does_not_exist\" ACL privileges not removed for principal: \"$test_user\"." );

ok( $authz->del( $test_content1, $test_user ),
    "Authz Test: Content \"$test_content1\" ACL privileges successfully removed for principal: \"$test_user\"." );

# Authz:
ok( my $authz_config = Apache::Sling::Authz->config($sling), 'check authz_config function' );

ok( Apache::Sling::Authz->run($sling,$authz_config), 'check authz_run function' );

$authz_config->{'write'} = \1;
$authz_config->{'read'} = \1;
$authz_config->{'addChildNodes'} = \1;
$authz_config->{'delete'} = \1;
$authz_config->{'lifecycleManage'} = \1;
$authz_config->{'lockManage'} = \1;
$authz_config->{'modifyACL'} = \1;
$authz_config->{'modifyProps'} = \1;
$authz_config->{'nodeTypeManage'} = \1;
$authz_config->{'readACL'} = \1;
$authz_config->{'removeChilds'} = \1;
$authz_config->{'removeNode'} = \1;
$authz_config->{'retentionManage'} = \1;
$authz_config->{'versionManage'} = \1;
$authz_config->{'view'} = \1;
$authz_config->{'removeNode'} = \1;
$authz_config->{'remote'} = \$test_content1;
$authz_config->{'principal'} = \$test_user;

ok( Apache::Sling::Authz->run($sling,$authz_config), q{check authz_run function adding permissions to $test_content1 for $test_user} );

$authz_config->{'write'} = \0;
$authz_config->{'read'} = \0;
$authz_config->{'addChildNodes'} = \0;
$authz_config->{'delete'} = \0;
$authz_config->{'lifecycleManage'} = \0;
$authz_config->{'lockManage'} = \0;
$authz_config->{'modifyACL'} = \0;
$authz_config->{'modifyProps'} = \0;
$authz_config->{'nodeTypeManage'} = \0;
$authz_config->{'readACL'} = \0;
$authz_config->{'removeChilds'} = \0;
$authz_config->{'removeNode'} = \0;
$authz_config->{'retentionManage'} = \0;
$authz_config->{'versionManage'} = \0;
$authz_config->{'view'} = \0;
$authz_config->{'removeNode'} = \0;

ok( Apache::Sling::Authz->run($sling,$authz_config), q{check authz_run function removing permissions from $test_content1 for $test_user} );

ok( $authz_config = Apache::Sling::Authz->config($sling), 'check authz_config function' );

$authz_config->{'all'} = \1;
$authz_config->{'remote'} = \$test_content1;
$authz_config->{'principal'} = \$test_user;

ok( Apache::Sling::Authz->run($sling,$authz_config), q{check authz_run function adding all permissions to $test_content1 for $test_user} );

$authz_config->{'all'} = \0;

ok( Apache::Sling::Authz->run($sling,$authz_config), q{check authz_run function removing all permissions from $test_content1 for $test_user} );

ok( $user->del( $test_user ),
    "User Test: User \"$test_user\" deleted successfully." );

ok( $content->del( $test_content1 ),
    "Content Test: Content \"$test_content1\" deleted successfully." );

