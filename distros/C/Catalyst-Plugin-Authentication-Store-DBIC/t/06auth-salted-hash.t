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

    eval { require Crypt::SaltedHash }
        or plan skip_all => 
        "Crypt::SaltedHash is required for this test";

    plan tests => 2;

    $ENV{TESTAPP_DB_FILE} = "$FindBin::Bin/auth.db";

    $ENV{TESTAPP_CONFIG} = {
        name => 'TestApp',
        authentication => {
            dbic => {
                user_class         => 'DBICSchema::User',
                user_field         => 'username',
                password_field     => 'password',
                password_type      => 'salted_hash',
                password_hash_type => 'SHA-1',
                password_salt_len  => 4,
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

use Test::WWW::Mechanize::Catalyst 'TestApp';
my $m = Test::WWW::Mechanize::Catalyst->new;

# log a user in
{
    $m->get_ok( 'http://localhost/user_login?username=rusty&password=testing123', undef, 'request ok' );
    $m->content_is( 'logged in', 'user logged in ok' );
}

# clean up
unlink $ENV{TESTAPP_DB_FILE};
