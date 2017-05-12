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

plan( tests => 57 );

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
    $res = $app->( GET '/delete/user?username=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /delete/user';
    is $res->code => 200, 'response status is 200 for /delete/user';

    $res = $app->( GET '/user?username=sarah', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user';
    is $res->code => 200, 'response status is 200 for /user';
    like $res->content => qr#'username' => 'sarah'#, '/user content is okay';

    $res = $app->( GET '/user/roles?username=sarah', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user/roles';
    is $res->code => 200, 'response status is 200 for /user/roles';
    like $res->content => qr#'?id'?\s+=>\s+'?\d+'?#, '/user/roles content is okay';

    $res = $app->( GET '/user/groups?username=sarah', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user/groups';
    is $res->code => 200, 'response status is 200 for /user/groups';
    like $res->content => qr#'?id'?\s+=>\s+'?\d+'?#, '/user/groups content is okay';

    $res = $app->( GET '/user/has/role?role=admin&username=sarah', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user/has/role';
    is $res->code => 200, 'response status is 200 for /user/has/role';
    like $res->content => qr#yes#, '/user/has/role content is okay';

    $res = $app->( GET '/user/has/any/role?username=sarah', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user/has/any/role';
    is $res->code => 200, 'response status is 200 for /user/has/any/role';
    like $res->content => qr#yes#, '/user/has/any/role content is okay';

    $res = $app->( GET '/user/has/all/roles?username=sarah', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user/has/all/roles';
    is $res->code => 200, 'response status is 200 for /user/has/all/roles';
    like $res->content => qr#yes#, '/user/has/all/roles content is okay';

    $res = $app->( GET '/user/has/group?group=ops', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user/has/group';
    is $res->code => 200, 'response status is 200 for /user/has/group';
    like $res->content => qr#yes#, '/user/has/group content is okay';

    $res = $app->( GET '/user/has/any/group', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user/has/any/group';
    is $res->code => 200, 'response status is 200 for /user/has/any/group';
    like $res->content => qr#yes#, '/user/has/any/group content is okay';

    $res = $app->( GET '/user/has/all/groups', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user/has/all/groups';
    is $res->code => 200, 'response status is 200 for /user/has/all/groups';
    like $res->content => qr#yes#, '/user/has/all/groups content is okay';

    $res = $app->( GET '/user/has/group/with/any/permission', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user/has/group/with/any/permission';
    is $res->code => 200, 'response status is 200 for /user/has/group/with/any/permission';
    like $res->content => qr#yes#, '/user/has/group/with/any/permission content is okay';

    $res = $app->( GET '/user/has/group/permission?group=ops&permission=write', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user/has/group/permission';
    is $res->code => 200, 'response status is 200 for /user/has/group/permission';
    like $res->content => qr#yes#, '/user/has/group/permission content is okay';

    $res = $app->( GET '/create/user?username=test&password=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /create/user';
    is $res->code => 200, 'response status is 200 for /create/user';
    like $res->content => qr#yes#, '/create/user content is okay';

    $res = $app->( GET '/user?username=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /user';
    is $res->code => 200, 'response status is 200 for /user';
    like $res->content => qr#'username' => 'test'#, '/user content is okay';

    $res = $app->( GET '/assign/user/role?username=test&role=admin', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /assign/user/role';
    is $res->code => 200, 'response status is 200 for /assign/user/role';
    like $res->content => qr#yes#, '/assign/user/role content is okay';

    $res = $app->( GET '/revoke/user/role?username=test&role=admin', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /revoke/user/role';
    is $res->code => 200, 'response status is 200 for /revoke/user/role';
    like $res->content => qr#yes#, '/revoke/user/role content is okay';

    $res = $app->( GET '/modify/user?id=2&username=craig&password=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /modify/user';
    is $res->code => 200, 'response status is 200 for /modify/user';
    like $res->content => qr#yes#, '/modify/user content is okay';

    $res = $app->( GET '/delete/user?username=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /delete/user';
    is $res->code => 200, 'response status is 200 for /delete/user';
    like $res->content => qr#yes#, '/delete/user content is okay';

    $res = $app->( GET '/logout' );
    is $res->code => 302, 'response status is 302 for /logout';

    $res = $app->( GET '/' );
    is $res->code => 302, 'response status is 302 for /';
});
