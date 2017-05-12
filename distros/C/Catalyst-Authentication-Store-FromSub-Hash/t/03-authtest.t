#!perl

use strict;
use warnings;
use File::Path;
use FindBin;
use Test::More;
use lib "$FindBin::Bin/lib";

BEGIN {

    my $has_dbi = eval "use DBI; 1;";
    $has_dbi or plan skip_all =>
        "DBI is required for this test";

    eval { require Catalyst::Model::DBIC::Schema }
        or plan skip_all =>
        "Catalyst::Model::DBIC::Schema is required for this test";

    eval { require Catalyst::Plugin::Session::State::Cookie }
        or plan skip_all =>
        "Catalyst::Plugin::Session::State::Cookie is required for this test";

    eval { require DBD::SQLite }
        or plan skip_all =>
        "DBD::SQLite is required for this test";

    plan tests => 10;

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
                        'class' => 'FromSub::Hash',
                        'model_class' => 'UserAuth',
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

# clean up
unlink $ENV{TESTAPP_DB_FILE};
