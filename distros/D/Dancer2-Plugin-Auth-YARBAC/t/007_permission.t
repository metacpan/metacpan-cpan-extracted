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

plan( tests => 18 );

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

    # clear just in case
    $res = $app->( GET '/delete/permission?permission=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /delete/permission';
    is $res->code => 200, 'response status is 200 for /delete/permission';

    $res = $app->( GET '/permission?permission=write', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /permission';
    is $res->code => 200, 'response status is 200 for /permission';
    like $res->content => qr#'?id'?\s+=>\s+'?\d+'?#, '/permission content is okay';

    $res = $app->( GET '/create/permission?permission=test&description=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /create/permission';
    is $res->code => 200, 'response status is 200 for /create/permission';
    like $res->content => qr#yes#, '/create/permission content is okay';

    $res = $app->( GET '/modify/permission?id=1&permission=read&description=read', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /modify/permission';
    is $res->code => 200, 'response status is 200 for /modify/permission';
    like $res->content => qr#yes#, '/modify/permission content is okay';

    $res = $app->( GET '/delete/permission?permission=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /delete/permission';
    is $res->code => 200, 'response status is 200 for /delete/permission';
    like $res->content => qr#yes#, '/delete/permission content is okay';

    $res = $app->( GET '/logout' );
    is $res->code => 302, 'response status is 302 for /logout';

    $res = $app->( GET '/' );
    is $res->code => 302, 'response status is 302 for /';
});
