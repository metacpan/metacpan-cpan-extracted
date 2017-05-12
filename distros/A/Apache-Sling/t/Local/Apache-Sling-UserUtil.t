#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 27;
use Test::Exception;
BEGIN { use_ok( 'Apache::Sling::UserUtil' ); }
BEGIN { use_ok( 'HTTP::Response' ); }

my $res = HTTP::Response->new( '200' );
my @properties = '';
ok( Apache::Sling::UserUtil::add_setup( 'http://localhost:8080', 'user', 'pass', \@properties) eq
  "post http://localhost:8080/system/userManager/user.create.html \$post_variables = [':name','user','pwd','pass','pwdConfirm','pass']", 'Check add_setup function' );
ok( Apache::Sling::UserUtil::update_setup('http://localhost:8080','user',\@properties ) eq "post http://localhost:8080/system/userManager/user/user.update.html \$post_variables = []", 'Check update_setup function without any properties' );
push @properties, 'a=b';
ok( Apache::Sling::UserUtil::add_setup( 'http://localhost:8080', 'user', 'pass', \@properties) eq
  "post http://localhost:8080/system/userManager/user.create.html \$post_variables = [':name','user','pwd','pass','pwdConfirm','pass','a','b']", 'Check add_setup function with properties' );
throws_ok { Apache::Sling::UserUtil::add_setup() } qr/No base url defined to add against!/, 'Check add_setup function croaks without base url';
throws_ok { Apache::Sling::UserUtil::add_setup('http://localhost:8080') } qr/No user name defined to add!/, 'Check add_setup function croaks without act_on_user';
throws_ok { Apache::Sling::UserUtil::add_setup('http://localhost:8080','testuser') } qr/No user password defined to add for user testuser!/, 'Check add_setup function croaks without act_on_pass';
ok( Apache::Sling::UserUtil::add_eval( \$res ), 'Check add_eval function' );
ok( Apache::Sling::UserUtil::change_password_setup( 'http://localhost:8080', 'user', 'pass1', 'pass2', 'pass2' ) eq
  "post http://localhost:8080/system/userManager/user/user.changePassword.html \$post_variables = ['oldPwd','pass1','newPwd','pass2','newPwdConfirm','pass2']", 'Check change_password_setup function' );
throws_ok { Apache::Sling::UserUtil::change_password_setup() } qr/No base url defined!/, 'Check change_password_setup function croaks without base url';
throws_ok { Apache::Sling::UserUtil::change_password_setup('http://localhost:8080') } qr/No user name defined to change password for!/, 'Check change_password_setup function croaks without act_on_user';
throws_ok { Apache::Sling::UserUtil::change_password_setup('http://localhost:8080','user') } qr/No current password defined for user!/, 'Check change_password_setup function croaks without act_on_pass';
throws_ok { Apache::Sling::UserUtil::change_password_setup('http://localhost:8080','user','pass') } qr/No new password defined for user!/, 'Check change_password_setup function croaks without new_pass';
throws_ok { Apache::Sling::UserUtil::change_password_setup('http://localhost:8080','user','pass1','pass2') } qr/No confirmation of new password defined for user!/, 'Check change_password_setup function croaks without new_pass_confirm';
ok( Apache::Sling::UserUtil::change_password_eval( \$res ), 'Check change_password_eval function' );
ok( Apache::Sling::UserUtil::delete_setup( 'http://localhost:8080', 'user' ) eq
  "post http://localhost:8080/system/userManager/user/user.delete.html \$post_variables = []", 'Check delete_setup function' );
throws_ok { Apache::Sling::UserUtil::delete_setup('http://localhost:8080') } qr/No user name defined to delete!/, 'Check delete_setup function croaks without user to delete specified';
throws_ok { Apache::Sling::UserUtil::delete_setup() } qr/No base url defined to delete against!/, 'Check delete_setup function croaks without base URL specified';
ok( Apache::Sling::UserUtil::delete_eval( \$res ), 'Check delete_eval function' );
ok( Apache::Sling::UserUtil::exists_setup( 'http://localhost:8080', 'user' ) eq
  "get http://localhost:8080/system/userManager/user/user.tidy.json", 'Check exists_setup function' );
throws_ok { Apache::Sling::UserUtil::exists_setup() } qr/No base url to check existence against!/, 'Check exists_setup function croaks without base URL specified';
ok( Apache::Sling::UserUtil::exists_eval( \$res ), 'Check exists_eval function' );
ok( Apache::Sling::UserUtil::update_setup( 'http://localhost:8080','user',\@properties ) eq "post http://localhost:8080/system/userManager/user/user.update.html \$post_variables = ['a','b']", 'Check update_setup function' );
throws_ok { Apache::Sling::UserUtil::update_setup() } qr/No base url defined to update against!/, 'Check update_setup function croaks without base URL specified';
ok( Apache::Sling::UserUtil::exists_eval( \$res ), 'Check exists_eval function' );
ok( Apache::Sling::UserUtil::update_eval( \$res ), 'Check update_eval function' );
