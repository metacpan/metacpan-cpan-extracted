#!perl

use strict;
use warnings;
use FindBin 1.49;
use Test::More 0.98;
use lib "$FindBin::Bin/lib";

BEGIN {
    eval { require Test::WWW::Mechanize::Catalyst }
      or plan skip_all =>
      "Test::WWW::Mechanize::Catalyst is required for this test";

    eval { require Catalyst::Plugin::Session;
           die unless $Catalyst::Plugin::Session::VERSION >= 0.02 }
        or plan skip_all =>
        "Catalyst::Plugin::Session >= 0.02 is required for this test";

    eval { require Catalyst::Plugin::Session::State::Cookie; }
        or plan skip_all =>
        "Catalyst::Plugin::Session::State::Cookie is required for this test";


    $ENV{TESTAPP_CONFIG} = {
        name => 'TestApp',	
        authentication => {
            default_realm => "users",
            realms => {
                users => {
                    credential => {
                        'class' => 'Password',
                        'password_field' => 'password',
					},
                    store => {
                        'class' => 'Person',                        
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
            Session
		    Session::Store::Dummy		   
            Session::State::Cookie				 
           /
    ];
}

use Test::WWW::Mechanize::Catalyst 'TestApp';
my $m = Test::WWW::Mechanize::Catalyst->new;

# log a user in
{
    $m->get_ok( 'http://localhost/user_login?username=test&password=test', undef, 'request ok' );
    $m->content_is( 'test logged in', 'user logged in ok' );
}

# verify the user is still logged in
{
    $m->get_ok( 'http://localhost/get_session_user', undef, 'request ok' );
    $m->content_is( 'test', 'user still logged in' );
}

{
    $m->get_ok( 'http://localhost/user_login?username=test&password=test&detach=show_user_class', undef, 'request ok' );
    $m->content_is( 'Catalyst::Authentication::Store::Person::User', 'Got correct subclass for user');
}

done_testing;
