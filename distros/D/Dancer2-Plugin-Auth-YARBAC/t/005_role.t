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

plan( tests => 30 );

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
    $res = $app->( GET '/delete/role?role=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /delete/role';
    is $res->code => 200, 'response status is 200 for /delete/role';

    $res = $app->( GET '/role?role=admin', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /role';
    is $res->code => 200, 'response status is 200 for /role';
    like $res->content => qr#'?id'?\s+=>\s+'?\d+'?#, '/role content is okay';

    $res = $app->( GET '/role/groups?role=admin', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /role/groups';
    is $res->code => 200, 'response status is 200 for /role/groups';
    like $res->content => qr#'?id'?\s+=>\s+'?\d+'?#, '/role/groups content is okay';

    $res = $app->( GET '/role/has/group?role=admin&group=cs', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /role/has/group';
    is $res->code => 200, 'response status is 200 for /role/has/group';
    like $res->content => qr#yes#, '/role/has/group content is okay';

    $res = $app->( GET '/create/role?role=test&description=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /create/role';
    is $res->code => 200, 'response status is 200 for /create/role';
    like $res->content => qr#yes#, '/create/role content is okay';

    $res = $app->( GET '/assign/role/group?role=test&group=cs', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /assign/role/group';
    is $res->code => 200, 'response status is 200 for /assign/role/group';
    like $res->content => qr#yes#, '/assign/role/group content is okay';

    $res = $app->( GET '/revoke/role/group?role=test&group=cs', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /revoke/role/group';
    is $res->code => 200, 'response status is 200 for /revoke/role/group';
    like $res->content => qr#yes#, '/revoke/role/group content is okay';

    $res = $app->( GET '/modify/role?id=2&role=manager&description=managers', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /modify/role';
    is $res->code => 200, 'response status is 200 for /modify/role';
    like $res->content => qr#yes#, '/modify/role content is okay';

    $res = $app->( GET '/delete/role?role=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /delete/role';
    is $res->code => 200, 'response status is 200 for /delete/role';
    like $res->content => qr#yes#, '/delete/role content is okay';

    $res = $app->( GET '/logout' );
    is $res->code => 302, 'response status is 302 for /logout';

    $res = $app->( GET '/' );
    is $res->code => 302, 'response status is 302 for /';
});
