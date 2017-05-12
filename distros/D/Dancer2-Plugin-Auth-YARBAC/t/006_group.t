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
    $res = $app->( GET '/delete/group?group=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /delete/group';
    is $res->code => 200, 'response status is 200 for /delete/group';

    $res = $app->( GET '/group?group=ops', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /group';
    is $res->code => 200, 'response status is 200 for /group';
    like $res->content => qr#'?id'?\s+=>\s+'?\d+'?#, '/group content is okay';

    $res = $app->( GET '/group/has/permission?group=cs&permission=read', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /group/has/permission';
    is $res->code => 200, 'response status is 200 for /group/has/permission';
    like $res->content => qr#yes#, '/group/has/permission content is okay';

    $res = $app->( GET '/group/permissions?group=cs', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /group/permissions';
    is $res->code => 200, 'response status is 200 for /group/permissions';
    like $res->content => qr#'?id'?\s+=>\s+'?\d+'?#, '/group/permissions content is okay';

    $res = $app->( GET '/create/group?group=test&description=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /create/group';
    is $res->code => 200, 'response status is 200 for /create/group';
    like $res->content => qr#yes#, '/create/group content is okay';

    $res = $app->( GET '/assign/group/permission?group=test&permission=read', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /assign/group/permission';
    is $res->code => 200, 'response status is 200 for /assign/group/permission';
    like $res->content => qr#yes#, '/assign/group/permission content is okay';

    $res = $app->( GET '/revoke/group/permission?group=test&permission=read', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /revoke/group/permission';
    is $res->code => 200, 'response status is 200 for /revoke/group/permission';
    like $res->content => qr#yes#, '/revoke/group/permission content is okay';

    $res = $app->( GET '/modify/group?id=4&group=finance&description=finance', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /modify/group';
    is $res->code => 200, 'response status is 200 for /modify/group';
    like $res->content => qr#yes#, '/modify/group content is okay';

    $res = $app->( GET '/delete/group?group=test', Cookie => "dancer.session=$cookie" );
    ok $res->is_success, 'GET /delete/group';
    is $res->code => 200, 'response status is 200 for /delete/group';
    like $res->content => qr#yes#, '/delete/group content is okay';

    $res = $app->( GET '/logout' );
    is $res->code => 302, 'response status is 302 for /logout';

    $res = $app->( GET '/' );
    is $res->code => 302, 'response status is 302 for /';
});
