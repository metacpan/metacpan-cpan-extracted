use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Catalyst::Test qw/RemoteTestApp1/;

$RemoteTestEngine::REMOTE_USER = undef;
ok( request('/public')->is_success, 'anonymous user (undef) - /public' );
ok( request('/')->is_error, 'anonymous user (undef) - /' );

$RemoteTestEngine::REMOTE_USER = '';
ok( request('/public')->is_success, 'anonymous user (empty) - /public' );
ok( request('/')->is_error, 'anonymous user (empty) - /' );

$RemoteTestEngine::REMOTE_USER = 'john';
ok( request('/')->is_success, 'valid user' );

$RemoteTestEngine::REMOTE_USER = 'nonexisting';
ok( request('/')->is_error, 'non-existing user' );

$RemoteTestEngine::REMOTE_USER = 'denieduser';
ok( request('/')->is_error, 'explicitly denied user' );

$RemoteTestEngine::REMOTE_USER = 'CN=namexyz/OU=Test/C=Company';
ok( request('/')->is_success, 'testing "cutname" option 1' );
is( request('/')->content, 'User:namexyz', 'testing "cutname" option 2' );

$RemoteTestEngine::REMOTE_USER = 'CN=/OU=Test/C=Company';
is( request('/')->content, 'User:CN=/OU=Test/C=Company', 'testing "cutname" option - empty $1 match' );

done_testing;

