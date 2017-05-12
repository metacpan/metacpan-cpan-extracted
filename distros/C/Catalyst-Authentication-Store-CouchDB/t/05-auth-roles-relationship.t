#!perl

use strict;
use warnings;
use FindBin 1.49;
use Test::More 0.98;
use lib "$FindBin::Bin/lib";

BEGIN {
    eval { require Catalyst::Plugin::Authorization::Roles }
        or plan skip_all =>
        "Catalyst::Plugin::Authorization::Roles is required for this test";

    plan tests => 8;

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
                        'class' => 'CouchDB',
                        couchdb_uri => 'http://localhost:5984',
                        dbname      => 'demouser',
                        designdoc   => '_design/user',
                        view        => 'user',
                        ua          => 'MockLWP',
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

use Catalyst::Test 'TestApp';

# test user's admin access
{
    ok( my $res = request('http://localhost/user_login?username=test&password=test&detach=is_admin'), 'request ok' );
    is( $res->content, 'ok', 'user is an admin' );
}

# test unauthorized user's admin access
{
    ok( my $res = request('http://localhost/user_login?username=test2&password=test2&detach=is_admin'), 'request ok' );
    is( $res->content, 'failed', 'user is not an admin' );
}

# test multiple auth roles
{
    ok( my $res = request('http://localhost/user_login?username=test&password=test&detach=is_admin_user'), 'request ok' );
    is( $res->content, 'ok', 'user is an admin and a user' );
}

# test multiple unauth roles
{
    ok( my $res = request('http://localhost/user_login?username=test2&password=test2&detach=is_admin_user'), 'request ok' );
    is( $res->content, 'failed', 'user is not an admin and a user' );
}
