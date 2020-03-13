use strict;
use warnings;
use Test::More;

{
    package TestApp;
    use Ark;

    use_plugins qw/
        Session
        Session::State::Cookie
        Session::Store::Memory
        /;

    conf 'Plugin::Session::State::Cookie' => {
        cookie_secure   => 1,
        cookie_httponly => 1,
        cookie_samesite => 'None',
    };

    package TestApp::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub test_set :Local {
        my ($self, $c) = @_;
        $c->session->set('test', 'dummy');
    }
}


use Ark::Test 'TestApp',
    components       => [qw/Controller::Root/],
    reuse_connection => 1;

{
    my $res = request(GET => '/test_set');
    like( $res->header('Set-Cookie'), qr/secure/, 'secure is true');
    like( $res->header('Set-Cookie'), qr/HttpOnly/, 'HttpOnly is true');
    like( $res->header('Set-Cookie'), qr/SameSite=None;/, 'SameSite is None');
}
done_testing;
