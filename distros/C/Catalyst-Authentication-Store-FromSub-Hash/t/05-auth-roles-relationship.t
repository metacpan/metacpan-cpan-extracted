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
                        'class' => 'FromSub::Hash',
                        'model_class' => 'UserAuth',
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
    ok( my $res = request('http://localhost/user_login?username=jayk&password=letmein&detach=is_admin'), 'request ok' );
    is( $res->content, 'ok', 'user is an admin' );
}

# test unauthorized user's admin access
{
    ok( my $res = request('http://localhost/user_login?username=nuffin&password=much&detach=is_admin'), 'request ok' );
    is( $res->content, 'failed', 'user is not an admin' );
}

# test multiple auth roles
{
    ok( my $res = request('http://localhost/user_login?username=jayk&password=letmein&detach=is_admin_user'), 'request ok' );
    is( $res->content, 'ok', 'user is an admin and a user' );
}

# test multiple unauth roles
{
    ok( my $res = request('http://localhost/user_login?username=nuffin&password=much&detach=is_admin_user'), 'request ok' );
    is( $res->content, 'failed', 'user is not an admin and a user' );
}

# clean up
unlink $ENV{TESTAPP_DB_FILE};
