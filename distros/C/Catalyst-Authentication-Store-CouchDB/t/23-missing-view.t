#!perl

use strict;
use warnings;
use FindBin 1.49;
use lib "$FindBin::Bin/lib";


use Test::More 0.98;

BEGIN {
    $ENV{TESTAPP_CONFIG} = {
        name => 'TestApp',
        authentication => {
            default_realm => "users",
            realms => {
                users => {
                    credential => {
                        class          => "Password",
                        password_field => 'password',
                        password_type  => 'clear'
                    },
                    store => {
                        class       => 'CouchDB',
                        couchdb_uri => 'http://localhost:5984/',
                        dbname      => 'demouser',
                        designdoc   => '_design/user',
                        view        => 'missing',
                        ua          => 'MockLWP',
                    },
                },
            },
        },
    };

    $ENV{TESTAPP_PLUGINS} = [
        qw/Authentication/
    ];
}

use Catalyst::Test 'TestApp';

# log a user in
{
    ok( my $res = request('http://localhost/user_login?username=test&password=test'), 'request ok' );
    is( $res->content, 'Design document does not contain view', 'Correct diagnostic for missing view');
}

done_testing;
