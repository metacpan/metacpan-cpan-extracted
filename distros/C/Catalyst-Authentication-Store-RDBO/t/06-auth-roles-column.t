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

    eval { require Catalyst::Plugin::Authorization::Roles }
        or plan skip_all =>
        "Catalyst::Plugin::Authorization::Roles is required for this test";

    plan tests => 8;

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
                        'role_column' => 'role_text'
                    },
                },
            },
        },
    };

    $ENV{TESTAPP_PLUGINS} = [
        qw/Authentication
           Authorization::Roles
           /
    ];
}

use SetupDB;

use Catalyst::Test 'TestApp';

# test user's admin access
{
    ok( my $res = request('http://localhost/user_login?username=joeuser&password=hackme&detach=is_admin'), 'request ok' );
    is( $res->content, 'ok', 'user is an admin' );
}

# test unauthorized user's admin access
{
    ok( my $res = request('http://localhost/user_login?username=jayk&password=letmein&detach=is_admin'), 'request ok' );
    is( $res->content, 'failed', 'user is not an admin' );
}

# test multiple auth roles
{
    ok( my $res = request('http://localhost/user_login?username=nuffin&password=much&detach=is_admin_user'), 'request ok' );
    is( $res->content, 'ok', 'user is an admin and a user' );
}

# test multiple unauth roles
{
    ok( my $res = request('http://localhost/user_login?username=joeuser&password=hackme&detach=is_admin_user'), 'request ok' );
    is( $res->content, 'failed', 'user is not an admin and a user' );
}

# clean up
unlink $ENV{TESTAPP_DB_FILE};
