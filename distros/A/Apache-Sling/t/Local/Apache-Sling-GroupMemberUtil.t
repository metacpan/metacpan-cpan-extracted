#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;
BEGIN { use_ok( 'Apache::Sling::GroupMemberUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

ok(Apache::Sling::GroupMemberUtil::add_setup('http://localhost:8080','group','user') eq
  "post http://localhost:8080/system/userManager/group/group.update.html \$post_variables = [':member','/system/userManager/user/user']",'Check add_setup function' );
ok(Apache::Sling::GroupMemberUtil::delete_setup('http://localhost:8080','group','user') eq
  "post http://localhost:8080/system/userManager/group/group.update.html \$post_variables = [':member\@Delete','/system/userManager/user/user']",'Check delete_setup function' );
my $res = HTTP::Response->new( '200' );
ok( Apache::Sling::GroupMemberUtil::add_eval( \$res ), 'Check add_eval function' );
ok( ! Apache::Sling::GroupMemberUtil::delete_eval( \$res ), 'Check delete_eval function no content' );
$res->content("OK");
ok( Apache::Sling::GroupMemberUtil::delete_eval( \$res ), 'Check delete_eval function' );
throws_ok { Apache::Sling::GroupMemberUtil::add_setup() } qr/No base url defined to add against!/, 'Check add_setup function croaks without base_url specified';
throws_ok { Apache::Sling::GroupMemberUtil::add_setup('http://localhost:8080','group') } qr/Group addition detail missing!/, 'Check add_setup function croaks without add_member specified';
throws_ok { Apache::Sling::GroupMemberUtil::delete_setup() } qr/No base url defined to delete against!/, 'Check delete_setup function croaks without base_url specified';
throws_ok { Apache::Sling::GroupMemberUtil::delete_setup('http://localhost:8080') } qr/No group name defined to delete from!/, 'Check delete_setup function croaks without group specified';
throws_ok { Apache::Sling::GroupMemberUtil::delete_setup('http://localhost:8080','group') } qr/Group deletion detail missing!/, 'Check delete_setup function croaks without member specified';
