#!perl

use strict;
use warnings;
use DBI;
use File::Path;
use FindBin;
use Test::More;
use lib "$FindBin::Bin/lib";

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all =>
        "DBD::SQLite is required for this test";

    eval { require Rose::DB::Object }
        or plan skip_all =>
        "Rose::DB::Object is required for this test";

    eval { require TestApp::User }
        or plan skip_all =>
        "TestApp::User not found: $@";

    plan tests => 13;

    $ENV{TESTAPP_DB_FILE} = "$FindBin::Bin/auth.db" unless exists($ENV{TESTAPP_DB_FILE});

    $ENV{TESTAPP_CONFIG} = {
        name => 'TestApp',
        authentication => {
            default_realm => "users",
            realms => {
                users => {
                    credential => {
                        'class' => "Password",
                        'password_field' => 'password',
                        'password_type' => 'clear'
                    },
                    store => {
                        'class' => 'RDBO',
                        'user_class' => 'TestApp::User',
                    },
                },
            },
        },
    };

    $ENV{TESTAPP_PLUGINS} = [
        qw/Authentication/
    ];
}

use SetupDB;

use Catalyst::Test 'TestApp';

# log a user in
{
    ok( my $res = request('http://localhost/user_login?username=joeuser&password=hackme'), 'request ok' );
    is( $res->content, 'joeuser logged in', 'user logged in ok' );
}

# invalid user
{
    ok( my $res = request('http://localhost/user_login?username=foo&password=bar'), 'request ok' );
    is( $res->content, 'not logged in', 'user not logged in ok' );
}

# disabled user - no disable check
{
    ok( my $res = request('http://localhost/user_login?username=spammer&password=broken'), 'request ok' );
    is( $res->content, 'spammer logged in', 'status check - disabled user logged in ok' );
}

# disabled user - should fail login
{
    ok( my $res = request('http://localhost/notdisabled_login?username=spammer&password=broken'), 'request ok' );
    is( $res->content, 'not logged in', 'status check - disabled user not logged in ok' );
}

# log the user out
{
    ok( my $res = request('http://localhost/user_logout'), 'request ok' );
    is( $res->content, 'logged out', 'user logged out ok' );
}

# searchargs test
{
    ok( my $res = request('http://localhost/searchargs_login?email=nada%40mucho.net&password=much'), 'request ok' );
    is( $res->content, 'nuffin logged in', 'searchargs based login ok' );
}

{
    $ENV{TESTAPP_CONFIG}->{authentication}->{realms}->{users}->{store}->{user_class} = 'Nonexistent::Class';
    my $res = request('http://localhost/user_login?username=joeuser&password=hackme');
    like( $res->content, qr/perhaps you forgot to load "Nonexistent::Class"/, 'test for wrong user_class' );
}
	    
	    


# clean up
unlink $ENV{TESTAPP_DB_FILE};
