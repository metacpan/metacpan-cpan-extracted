use strict;
use warnings;

use utf8;
use open ':std', ':encoding(utf8)';
use Test::More;

BEGIN {
    eval "use Dancer2";
    eval "use Dancer2::Plugin::DBIC 0.0009";
    plan skip_all => "Dancer2::Plugin::DBIC 0.0009 required to run this test"
      if $@;
}

diag "Dancer2::Plugin::DBIC version: ", $Dancer2::Plugin::DBIC::VERSION;
use Plack::Test;
use HTTP::Request::Common;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

my $deploy_once = 1;

{

    package Foo;

    use Dancer2;
    use Dancer2::Plugin::DBIC;

    set plugins => {
        DBIC => {
            default => {
                dsn          => 'dbi:SQLite:dbname=:memory:',
                schema_class => 'Test::Schema',
                options      => {
                    sqlite_unicode => 1,
                    quote_names    => 1,
                },
            },
        },
    };

    if ( $deploy_once ) {
        schema->deploy;
    }
    else {
        $deploy_once = 0;
    }

    # engines needs to set before the session itself
    set engines => {
        session => {
            DBIC => {
                db_connection_name => 'default',
            },
        },
    };

    set session => 'DBIC';

    get '/id' => sub {
        return session->id;
    };

    get '/getfoo' => sub {
        return session('foo');
    };

    get '/putfoo' => sub {
        session foo => 'bar';
        return session('foo');
    };

    get '/getcamel' => sub {
        return session('camel');
    };

    get '/putcamel' => sub {
        session camel => 'ラクダ';
        return session('camel');
    };

    get '/destroy' => sub {
        if ( app->can('destroy_session') ) {
            app->destroy_session;
        }

        # legacy
        else {
            context->destroy_session;
        }
        return "Session destroyed";
    };

    get '/sessionid' => sub {
        return session->id;
    };

}

my $app = Dancer2->runner->psgi_app;

is( ref $app, 'CODE', 'Got app' );

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->( GET '/sessionid' );

    my $newid = $res->decoded_content;

    # extract the cookie
    my $cookie = $res->header('Set-Cookie');
    $cookie =~ s/^(.*?);.*$/$1/s;
    ok( $cookie, "Got the cookie: $cookie" );
    my @headers = ( Cookie => $cookie );

    my $session_id = $cb->( GET '/id', @headers )->decoded_content;
    like( $session_id, qr/^[0-9a-z_-]+$/i, 'Retrieve session id', );

    is(
        $cb->( GET '/getfoo', @headers )->decoded_content,
        '', 'Retrieve pristine foo key',
    );

    is(
        $cb->( GET '/putfoo', @headers )->decoded_content,
        'bar', 'Set foo key to bar',
    );

    is(
        $cb->( GET '/getfoo', @headers )->decoded_content,
        'bar', 'Retrieve foo key which is "bar" now',
    );

    is(
        $cb->( GET '/getcamel', @headers )->decoded_content,
        '', 'Retrieve pristine camel key',
    );

    is(
        $cb->( GET '/putcamel', @headers )->decoded_content,
        'ラクダ', 'Set camel key to ラクダ',
    );

    is(
        $cb->( GET '/getcamel', @headers )->decoded_content,
        'ラクダ', 'Retrieve camel key which is "ラクダ" now',
    );

    like(
        $cb->( GET '/sessionid', @headers )->decoded_content,
        qr/\w/, "Found session id",
    );
    my $oldid = $cb->( GET '/sessionid', @headers )->decoded_content;
    is( $oldid, $newid, "Same id, session holds" );

    is(
        $cb->( GET '/destroy', @headers )->decoded_content,
        'Session destroyed',
        'Session destroyed without crashing',
    );

    is(
        $cb->( GET '/getfoo', @headers )->decoded_content,
        '', 'Retrieve pristine foo key after destroying',
    );

    $newid = $cb->( GET '/sessionid', @headers )->decoded_content;

    ok( $newid ne $oldid, "New and old ids differ" );
};

done_testing;
