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

    eval { require Class::DBI }
        or plan skip_all =>
        "Class::DBI is required for this test";

    eval { require Catalyst::Plugin::Authorization::Roles }
        or plan skip_all =>
        "Catalyst::Plugin::Authorization::Roles is required for this test";

    plan tests => 8;

    $ENV{TESTAPP_DB_FILE} = "$FindBin::Bin/auth.db";

    $ENV{TESTAPP_CONFIG} = {
        name => 'TestApp',
        authentication => {
            dbic => {
                user_class         => 'CDBI::User',
                user_field         => 'username',
                password_field     => 'password',
                password_type      => 'clear',
            },
        },
        authorization => {
            dbic => {
                role_class           => 'CDBI::Role',
                role_field           => 'role',
                user_role_class      => 'CDBI::UserRole',
                user_role_user_field => 'user',
                user_role_role_field => 'role',
            },
        },
    };

    $ENV{TESTAPP_PLUGINS} = [
        qw/Authentication
           Authentication::Store::DBIC
           Authentication::Credential::Password
           Authorization::Roles
           /
    ];
}

use SetupDB;

use Catalyst::Test 'TestApp';

# test user's admin access
{
    ok( my $res = request('http://localhost/user_login?username=andyg&password=hackme&detach=is_admin'), 'request ok' );
    is( $res->content, 'ok', 'user is an admin' );
}

# test unauthorized user's admin access
{
    ok( my $res = request('http://localhost/user_login?username=nuffin&password=much&detach=is_admin'), 'request ok' );
    is( $res->content, '', 'user is not an admin' );
}

# test multiple auth roles
{
    ok( my $res = request('http://localhost/user_login?username=andyg&password=hackme&detach=is_admin_user'), 'request ok' );
    is( $res->content, 'ok', 'user is an admin and a user' );
}

# test multiple unauth roles
{
    ok( my $res = request('http://localhost/user_login?username=nuffin&password=much&detach=is_admin_user'), 'request ok' );
    is( $res->content, '', 'user is not an admin and a user' );
}

# clean up
unlink $ENV{TESTAPP_DB_FILE};
