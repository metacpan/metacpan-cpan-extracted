use strictures 1;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use t::Util;

BEGIN {
    eval 'use Sereal::Decoder;1'
        or plan skip_all => "Sereal::Decoder needed to run these tests";
    eval 'use Sereal::Encoder;1'
        or plan skip_all => "Sereal::Encoder needed to run these tests";
    t::Util::setenv;
    $ENV{DANCER_SESSION_REDIS_TEST_MOCK} = 0;
}

use t::TestApp::Simple;

BEGIN {
  t::Util::setconf( \&t::TestApp::Simple::set )
    or plan( skip_all => "Redis server not found so tests cannot be run" );
}

############################################################################

my $app = t::TestApp::Simple->psgi_app;
ok( $app, 'Got App' );

############################################################################

t::Util::psgi_request_ok( $app, GET => q{/get?key=foo},           qr/^get foo: $/ );
t::Util::psgi_request_ok( $app, GET => q{/set?key=foo&value=bar}, qr/^set foo: bar$/ );
t::Util::psgi_request_ok( $app, GET => q{/get?key=foo},           qr/^get foo: bar$/ );
t::Util::psgi_change_session_id( $app );
t::Util::psgi_request_ok( $app, GET => q{/get?key=foo},           qr/^get foo: bar$/ );

############################################################################
done_testing;
