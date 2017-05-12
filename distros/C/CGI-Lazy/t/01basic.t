#!/usr/bin/perl

use strict;
use Test::More;

BEGIN {
	use_ok('CGI::Pretty');
	use_ok('JSON');
	use_ok('JavaScript::Minifier');
	use_ok('HTML::Template');
	use_ok('DBI');
	use_ok('Digest::MD5');
	use_ok('Time::HiRes');
	use_ok('CGI::Lazy::Config');
	use_ok('CGI::Lazy::Plugin');
	use_ok('CGI::Lazy::DB');
	use_ok('CGI::Lazy::DB::RecordSet');
	use_ok('CGI::Lazy::Session');
	use_ok('CGI::Lazy::Template');
	use_ok('CGI::Lazy::Widget');
	use_ok('CGI::Lazy::Globals');
	use_ok('CGI::Lazy::ErrorHandler');
	use_ok('CGI::Lazy::Utility');
	use_ok('CGI::Lazy::Javascript');
	use_ok('CGI::Lazy::CSS');
	use_ok('CGI::Lazy::Image');
	use_ok('CGI::Lazy::Authn');
	use_ok('CGI::Lazy::Authz');
	use_ok('CGI::Lazy');
}

my @lazymethods = qw(
		authn
		authz
		css
		csswrap
		image
		javascript
		config
		db
		dbh
		errorHandler
		header
		jswrap
		mod_perl
		new
		lazyversion
		plugin
		session
		template
		util
		vars
		widget
);

my $q = new_ok('CGI::Lazy', [{
#				tmplDir         => '/var/templates',
#				jsDir           => '/js',
#				cssDir          => '/css',
#				imgDir          => '/css',
#				buildDir        => '/var/build',
#				plugins         => {
#					mod_perl	=> {
#						PerlHandler	=> "ModPerl::Registry",
#						saveOnCleanup	=> '1',
#					},
#					dbh     => {
#						dbDatasource    => 'dbi:mysql:CIS:localhost',
#						dbUser          => 'CISuser',
#						dbPasswd        => 'l3tM31n',
#						dbArgs          => {RaiseError  => 1},
#					},
#					session => {
#						sessionTable    => 'session',
#						sessionCookie   => 'CIS',
#						saveOnDestroy   => 1,
#						expires         => '+5m',
#					},
#					authn   => {
#						table           => 'user',
#						primarykey      => 'user_id',
#						template        => 'login.tmpl',
#						salt            => '2349asdfLKj%@asdf',
#						userField       => 'username',
#						passwdField     => 'password',
#
#					},
#					authz   => {
#						permFlag        => 1,
#							userTable       => {
#							name            => 'user',
#							primarykey      => 'user_id',
#							userNameField   => 'username',
#						},
#						groupTable      => {
#							name            => 'group_list',
#							primarykey      => 'group_id',
#							groupNameField  => 'group_name',
#						},
#						mapTable        => {
#							name            => 'user_group_map',
#							groupField      => 'group_id_map',
#							userField       => 'user_id_map',
#							perms   => [],
#						},

#					},
#				},

			}]);

can_ok($q, @lazymethods);
ok($q->lazyversion, "Version Check");

#isa_ok($q->authn, "CGI::Lazy::Authn");
#isa_ok($q->db, "CGI::Lazy::DB");
isa_ok($q->css, "CGI::Lazy::CSS");
isa_ok($q->image, "CGI::Lazy::Image");
isa_ok($q->javascript, "CGI::Lazy::Javascript");
isa_ok($q->errorHandler, "CGI::Lazy::ErrorHandler");
isa_ok($q->config, "CGI::Lazy::Config");
isa_ok($q->plugin, "CGI::Lazy::Plugin");
isa_ok($q->template, "CGI::Lazy::Template");
isa_ok($q->util, "CGI::Lazy::Utility");
isa_ok($q->widget, "CGI::Lazy::Widget");


done_testing();
