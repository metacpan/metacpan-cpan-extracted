use strict;
use warnings;
use DBI;
use FindBin;
use Test::More;
use lib "$FindBin::Bin/lib";

BEGIN {
	eval { require DBD::SQLite }
	    or plan skip_all =>
	    "DBD::SQLite is required for this test";

	eval { require Catalyst::Model::DBI }
	    or plan skip_all =>
	    "Catalyst::Model::DBI is required for this test";

	plan tests => 6;

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

	$ENV{'TESTAPP_PLUGINS'} = [ qw(Authentication) ];
}

use SetupDB;

use Catalyst::Test 'TestApp';

# test login failure
{
	ok(my $res = request('http://localhost/login?name=joe&password=a'), 'request ok');
	is($res->content(), 'not logged in', 'check wrong password');
}

# test sucessful login
{
	ok(my $res = request('http://localhost/login?name=joe&password=x'), 'request ok');
	is($res->content(), 'joe logged in', 'user logged in');
}

# test inactive login
{
	ok(my $res = request('http://localhost/nologin?name=martin&password=z'), 'request ok');
	is($res->content(), 'user martin is inactive', 'user inactive');
}

