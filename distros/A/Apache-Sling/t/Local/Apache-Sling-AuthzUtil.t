#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 25;
use Test::Exception;

BEGIN { use_ok( 'Apache::Sling::AuthzUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

my $res = HTTP::Response->new( '200' );

# get_acl
ok( Apache::Sling::AuthzUtil::get_acl_setup( 'http://localhost:8080', 'dest' ) eq
  'get http://localhost:8080/dest.acl.json', 'Check get_acl_setup function' );
throws_ok { Apache::Sling::AuthzUtil::get_acl_setup('http://localhost:8080') } qr/No destination to view ACL for defined!/, 'Check get_acl_setup function croaks without remote destination';
throws_ok { Apache::Sling::AuthzUtil::get_acl_setup() } qr/No base url defined!/, 'Check get_acl_setup function croaks without base URL';
ok( Apache::Sling::AuthzUtil::get_acl_eval( \$res ), 'Check get_acl_eval function' );

# delete
ok( Apache::Sling::AuthzUtil::delete_setup( 'http://localhost:8080', 'dest', 'principal' ) eq
  "post http://localhost:8080/dest.deleteAce.html \$post_variables = [':applyTo','principal']", 'Check delete_setup function' );
throws_ok { Apache::Sling::AuthzUtil::delete_setup('http://localhost:8080','dest') } qr/No principal to delete ACL for defined!/, 'Check delete_setup function croaks without principal';
throws_ok { Apache::Sling::AuthzUtil::delete_setup('http://localhost:8080') } qr/No destination to delete ACL for defined!/, 'Check delete_setup function croaks without remote destination';
throws_ok { Apache::Sling::AuthzUtil::delete_setup() } qr/No base url defined!/, 'Check delete_setup function croaks without base URL';
ok( Apache::Sling::AuthzUtil::delete_eval( \$res ), 'Check delete_eval function' );

# modify_privilege
my @grant_privileges;
my @deny_privileges;
ok( Apache::Sling::AuthzUtil::modify_privilege_setup( 'http://localhost:8080', 'dest', 'principal', \@grant_privileges, \@deny_privileges ) eq
  "post http://localhost:8080/dest.modifyAce.html \$post_variables = ['principalId','principal']", 'Check modify_privilege_setup function' );
throws_ok { Apache::Sling::AuthzUtil::modify_privilege_setup('http://localhost:8080','dest') } qr/No principal to modify privilege for defined!/, 'Check modify_privilege_setup function croaks without principal';
throws_ok { Apache::Sling::AuthzUtil::modify_privilege_setup('http://localhost:8080') } qr/No destination to modify privilege for defined!/, 'Check modify_privilege_setup function croaks without remote destination';
throws_ok { Apache::Sling::AuthzUtil::modify_privilege_setup() } qr/No base url defined!/, 'Check modify_privilege_setup function croaks without base URL';
ok( Apache::Sling::AuthzUtil::modify_privilege_eval( \$res ), 'Check modify_privilege_eval function' );
push @grant_privileges, 'broken_privilege';
throws_ok { Apache::Sling::AuthzUtil::modify_privilege_setup('http://localhost:8080', 'dest', 'principal', \@grant_privileges, \@deny_privileges) } qr/Unsupported grant privilege: "broken_privilege" supplied!/, 'Check modify_privilege_setup function croaks with invalid grant privilege';
shift @grant_privileges;
push @deny_privileges, 'broken_privilege';
throws_ok { Apache::Sling::AuthzUtil::modify_privilege_setup('http://localhost:8080', 'dest', 'principal', \@grant_privileges, \@deny_privileges) } qr/Unsupported deny privilege: "broken_privilege" supplied!/, 'Check modify_privilege_setup function croaks with invalid deny privilege';
shift @deny_privileges;
push @grant_privileges, 'read';
push @deny_privileges, 'modifyProperties';
ok( Apache::Sling::AuthzUtil::modify_privilege_setup( 'http://localhost:8080', 'dest', 'principal', \@grant_privileges, \@deny_privileges ) eq
  "post http://localhost:8080/dest.modifyAce.html \$post_variables = ['principalId','principal','privilege\@jcr:read','granted','privilege\@jcr:modifyProperties','denied']", 'Check modify_privilege_setup function with two privileges used' );
push @grant_privileges, 'addChildNodes';
push @deny_privileges, 'removeNode';
ok( Apache::Sling::AuthzUtil::modify_privilege_setup( 'http://localhost:8080', 'dest', 'principal', \@grant_privileges, \@deny_privileges ) eq
  "post http://localhost:8080/dest.modifyAce.html \$post_variables = ['principalId','principal','privilege\@jcr:read','granted','privilege\@jcr:addChildNodes','granted','privilege\@jcr:modifyProperties','denied','privilege\@jcr:removeNode','denied']", 'Check modify_privilege_setup function with four privileges used' );
push @grant_privileges, 'removeChildNodes';
push @deny_privileges, 'write';
ok( Apache::Sling::AuthzUtil::modify_privilege_setup( 'http://localhost:8080', 'dest', 'principal', \@grant_privileges, \@deny_privileges ) eq
  "post http://localhost:8080/dest.modifyAce.html \$post_variables = ['principalId','principal','privilege\@jcr:read','granted','privilege\@jcr:addChildNodes','granted','privilege\@jcr:removeChildNodes','granted','privilege\@jcr:modifyProperties','denied','privilege\@jcr:removeNode','denied','privilege\@jcr:write','denied']", 'Check modify_privilege_setup function with six privileges used' );
push @grant_privileges, 'readAccessControl';
push @deny_privileges, 'modifyAccessControl';
ok( Apache::Sling::AuthzUtil::modify_privilege_setup( 'http://localhost:8080', 'dest', 'principal', \@grant_privileges, \@deny_privileges ) eq
  "post http://localhost:8080/dest.modifyAce.html \$post_variables = ['principalId','principal','privilege\@jcr:read','granted','privilege\@jcr:addChildNodes','granted','privilege\@jcr:removeChildNodes','granted','privilege\@jcr:readAccessControl','granted','privilege\@jcr:modifyProperties','denied','privilege\@jcr:removeNode','denied','privilege\@jcr:write','denied','privilege\@jcr:modifyAccessControl','denied']", 'Check modify_privilege_setup function with eight privileges used' );
push @grant_privileges, 'lockManagement';
push @deny_privileges, 'versionManagement';
ok( Apache::Sling::AuthzUtil::modify_privilege_setup( 'http://localhost:8080', 'dest', 'principal', \@grant_privileges, \@deny_privileges ) eq
  "post http://localhost:8080/dest.modifyAce.html \$post_variables = ['principalId','principal','privilege\@jcr:read','granted','privilege\@jcr:addChildNodes','granted','privilege\@jcr:removeChildNodes','granted','privilege\@jcr:readAccessControl','granted','privilege\@jcr:lockManagement','granted','privilege\@jcr:modifyProperties','denied','privilege\@jcr:removeNode','denied','privilege\@jcr:write','denied','privilege\@jcr:modifyAccessControl','denied','privilege\@jcr:versionManagement','denied']", 'Check modify_privilege_setup function with ten privileges used' );
push @grant_privileges, 'nodeTypeManagement';
push @deny_privileges, 'retentionManagement';
ok( Apache::Sling::AuthzUtil::modify_privilege_setup( 'http://localhost:8080', 'dest', 'principal', \@grant_privileges, \@deny_privileges ) eq
  "post http://localhost:8080/dest.modifyAce.html \$post_variables = ['principalId','principal','privilege\@jcr:read','granted','privilege\@jcr:addChildNodes','granted','privilege\@jcr:removeChildNodes','granted','privilege\@jcr:readAccessControl','granted','privilege\@jcr:lockManagement','granted','privilege\@jcr:nodeTypeManagement','granted','privilege\@jcr:modifyProperties','denied','privilege\@jcr:removeNode','denied','privilege\@jcr:write','denied','privilege\@jcr:modifyAccessControl','denied','privilege\@jcr:versionManagement','denied','privilege\@jcr:retentionManagement','denied']", 'Check modify_privilege_setup function with twelve privileges used' );
push @grant_privileges, 'lifecycleManagement';
push @deny_privileges, 'all';
ok( Apache::Sling::AuthzUtil::modify_privilege_setup( 'http://localhost:8080', 'dest', 'principal', \@grant_privileges, \@deny_privileges ) eq
  "post http://localhost:8080/dest.modifyAce.html \$post_variables = ['principalId','principal','privilege\@jcr:read','granted','privilege\@jcr:addChildNodes','granted','privilege\@jcr:removeChildNodes','granted','privilege\@jcr:readAccessControl','granted','privilege\@jcr:lockManagement','granted','privilege\@jcr:nodeTypeManagement','granted','privilege\@jcr:lifecycleManagement','granted','privilege\@jcr:modifyProperties','denied','privilege\@jcr:removeNode','denied','privilege\@jcr:write','denied','privilege\@jcr:modifyAccessControl','denied','privilege\@jcr:versionManagement','denied','privilege\@jcr:retentionManagement','denied','privilege\@jcr:all','denied']", 'Check modify_privilege_setup function with all privileges used' );
