use strict;
use warnings;

use Find::Lib 'testapp/lib' => 'testapp';
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Data::Dumper;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

plan( tests => 10 );

use testapp;
{ package testapp; set apphandler => 'PSGI'; set log => 'error'; }

test_psgi( app => testapp::dance, client => sub 
{
    my $app = shift;

    my $res = $app->( POST '/login', [ username => 'sarah', password => 'test' ] );
    is $res->code => 302, 'response status is 302 for /login';

    my $get_cookie = $res->header('Set-Cookie');
    $get_cookie =~ /dancer\.session=([^; ]+)/;
    my $cookie = $1;

    ok( $cookie, 'Got cookie' );

    $res = $app->( GET '/generate_hash', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /generate_hash';
    is $res->code => 200, 'response status is 200 for /generate_hash';
    like $res->content => qr#<h1>Hash</h1>#, '/generate_hash content is okay';

    $res = $app->( POST '/password_strength', [ password => 'test' ], Cookie => "dancer.session=$cookie"  );
    ok $res->is_success, 'POST /password_strength';
    is $res->code => 200, 'response status is 200 for /password_strength';
    like $res->content => qr#'?error'?\s+=>\s+'?\d+'?#, '/password_strength content is okay';

    $res = $app->( GET '/logout' );
    is $res->code => 302, 'response status is 302 for /logout';

    $res = $app->( GET '/' );
    is $res->code => 302, 'response status is 302 for /';
});
