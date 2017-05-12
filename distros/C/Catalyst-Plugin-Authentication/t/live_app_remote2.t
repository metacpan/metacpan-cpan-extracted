use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Catalyst::Test qw/RemoteTestApp2/;

$RemoteTestEngine::REMOTE_USER = undef;

# WARNING: this requires $c->engine->env to work properly
# $c->engine->env was slightly broken in 5.8004 but this test should pass
# as it uses Engine::CGI that works fine even in 5.80004

$RemoteTestEngine::SSL_CLIENT_S_DN = 'CN=anyuser/OU=Test/C=Company';
ok( request('/')->is_success, 'testing "source" option' );

$RemoteTestEngine::SSL_CLIENT_S_DN = 'CN=namexyz/OU=Test/C=Company';
ok( request('/')->is_success, 'testing "source" + "cutname" 1' );
is( request('/')->content, "my_user_name:namexyz",
   'testing "source" + "cutname" 2' );

done_testing;

