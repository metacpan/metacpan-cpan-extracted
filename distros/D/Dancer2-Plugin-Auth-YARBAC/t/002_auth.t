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

    my $res = $app->( GET '/login' );
    ok $res->is_success, 'GET /login';
    is $res->code => 200, 'response status is 200 for /login';
    like $res->content => qr#<form action="/login" method="post">#, '/login content is okay';

    $res = $app->( POST '/login', [ username => 'sarah', password => 'test' ] );
    is $res->code => 302, 'response status is 302 for /login';

    my $get_cookie = $res->header('Set-Cookie');
    $get_cookie =~ /dancer\.session=([^; ]+)/;
    my $cookie = $1;

    ok( $cookie, 'Got cookie' );

    $res = $app->( GET '/', Cookie => "dancer.session=$cookie");
    ok $res->is_success, 'GET /';
    is $res->code => 200, 'response status is 200 for /';
    like $res->content => qr#<h1>Welcome</h1>#, '/ content is okay';

    $res = $app->( GET '/logout' );
    is $res->code => 302, 'response status is 302 for /logout';

    $res = $app->( GET '/' );
    is $res->code => 302, 'response status is 302 for /';
});
