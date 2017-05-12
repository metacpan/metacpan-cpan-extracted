use strict;
use warnings;
use DBI;
use FindBin;
use Test::More;
use lib "$FindBin::Bin/lib";

BEGIN {
	eval {
		require Catalyst::Model::DBI;
		require Catalyst::Plugin::Authorization::Roles;
		require Catalyst::Plugin::Session;
		require Catalyst::Plugin::Session::State::Cookie;
		require Catalyst::Plugin::Session::Store::File;
		require DBD::SQLite;
		require Test::WWW::Mechanize::Catalyst;
	} or plan skip_all => $@;

	plan tests => 12;

	unless (exists($ENV{'TESTAPP_DB_FILE'})) {
		$ENV{'TESTAPP_DB_FILE'} = "$FindBin::Bin/test.db";
	}

	$ENV{'TESTAPP_CONFIG'} = {
		'name'			=> 'TestApp',
		'Model::DBI'		=> {
			'dsn'			=> 'dbi:SQLite:' . $ENV{'TESTAPP_DB_FILE'},
		},
		'authentication'	=> {
			'default_realm'		=> 'users',
			'realms'		=> {
				'users'			=> {
					'credential'		=> {
						'class'			=> 'Password',
						'password_field'	=> 'password',
						'password_type'		=> 'clear',
					},
					'store'			=> {
						'class'			=> 'DBI::ButMaintained',
						'user_table'		=> 'user',
						'user_key'		=> 'id',
						'user_name'		=> 'name',
						'role_table'		=> 'role',
						'role_key'		=> 'id',
						'role_name'		=> 'name',
						'user_role_table'	=> 'userrole',
						'user_role_user_key'	=> 'user',
						'user_role_role_key'	=> 'role',
					},
				},
			},
		},
	};

	$ENV{'TESTAPP_PLUGINS'} = [ qw(
		Authentication
		Session
		Session::Store::File
		Session::State::Cookie
		Authorization::Roles
	) ];
}

use SetupDB;

use Test::WWW::Mechanize::Catalyst 'TestApp';

my $m = Test::WWW::Mechanize::Catalyst->new();

# test login failure
{
	$m->get_ok('http://localhost/login?name=joe&password=a', 'request ok');
	$m->content_is('not logged in', 'check wrong password');
}

# test sucessful login
{
	$m->get_ok('http://localhost/login?name=joe&password=x', 'request ok');
	$m->content_is('joe logged in', 'user logged in');
}

#role test
{
	$m->get_ok('http://localhost/rolecheck?role=admin', 'request ok');
	$m->content_is('joe is in role admin', 'member role ok');
}

#role test unsuccessfull
{
	$m->get_ok('http://localhost/rolecheck?role=foobar', 'request ok');
	$m->content_is('joe is not in role foobar', 'random role ok');
}

# test logout
{
	$m->get_ok('http://localhost/dologout', 'request ok');
	$m->content_is('logged out', 'log out');
}

# test already logged out
{
	$m->get_ok('http://localhost/dologout', 'request ok');
	$m->content_is('not logged out', 'logged out already');
}

