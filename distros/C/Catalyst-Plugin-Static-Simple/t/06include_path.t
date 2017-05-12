#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 6;
use Catalyst::Test 'TestApp';

# test altenate root dirs
TestApp->config->{'Plugin::Static::Simple'}->{include_path} = [
    TestApp->config->{root} . '/overlay',
    \&TestApp::incpath_generator,
    TestApp->config->{root},
];

# test overlay dir
ok( my $res = request('http://localhost/overlay.jpg'), 'request ok' );
is( $res->content_type, 'image/jpeg', 'overlay path ok' );

# test incpath_generator
ok( $res = request('http://localhost/incpath.css'), 'request ok' );
is( $res->content_type, 'text/css', 'incpath coderef ok' );

# test passthrough to root
ok( $res = request('http://localhost/images/bad.gif'), 'request ok' );
is( $res->content_type, 'image/gif', 'root path ok' );
