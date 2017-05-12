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

    eval { require DBIx::Class }
        or plan skip_all =>
        "DBIx::Class is required for this test";

    plan tests => 2;

    $ENV{TESTAPP_DB_FILE} = "$FindBin::Bin/auth.db";

    $ENV{TESTAPP_CONFIG} = {
        name => 'TestApp',
        authentication => {
            dbic => {
                user_class     => 'DBICSchema::User',
                user_field     => 'username',
                password_field => 'password',
                password_type  => 'crypted',
            },
        },
    };

    $ENV{TESTAPP_PLUGINS} = [
        qw/Authentication
           Authentication::Store::DBIC
           Authentication::Credential::Password
           /
    ];
}

use SetupDB;

use Catalyst::Test 'TestApp';

# log a user in
{
    ok( my $res = request('http://localhost/user_login?username=sri&password=hackme'), 'request ok' );
    is( $res->content, 'logged in', 'user logged in ok' );
}

# clean up
unlink $ENV{TESTAPP_DB_FILE};
