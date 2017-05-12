use strictures 1;
use Test::More tests => 1 + 5;
use Test::NoWarnings;
use Plack::Test;
use HTTP::Request::Common;

use t::Util;

BEGIN { t::Util::setenv }

use t::TestApp::Simple;

BEGIN { t::Util::setconf( \&t::TestApp::Simple::set ) }

############################################################################

my $app = t::TestApp::Simple->psgi_app;
ok( $app, 'Got App' );

############################################################################

t::Util::psgi_request_ok( $app, GET => q{/set?key=foo&value=bar},   qr/^set foo: bar$/ );
t::Util::psgi_request_ok( $app, GET => q{/expire?key=foo&expire=1}, qr/^expire foo: 1$/ );
t::Util::psgi_request_ok( $app, GET => q{/get?key=foo},             qr/^get foo: bar$/ );
sleep 2;
t::Util::psgi_request_ok( $app, GET => q{/get?key=foo}, qr/^get foo: $/ );

############################################################################
