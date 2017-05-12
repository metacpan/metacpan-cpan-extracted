#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

plan tests => 6;
use Catalyst::Test 'TestApp';

# configure verbose level 1
TestApp->config->{stacktrace}->{verbose} = 1;

open STDERR, '>/dev/null';

# test that a crashed action prints the appropriate debug screen order
{
    ok( my $res = request('http://localhost/foo/not_ok'), 'request ok' );

    like( $res->content, qr{<td>TestApp::Controller::Foo</td>.*<td>Catalyst::Test</td>}s, 'normal order ok' );
    unlike( $res->content, qr{<td>Catalyst::Test</td>.*<td>TestApp::Controller::Foo</td>}s, 'not reversed ok' );
}

# scratch that. flip it around.
TestApp->config->{stacktrace}->{reverse} = 1;

# test that a crashed action prints the appropriate debug screen order
{
    ok( my $res = request('http://localhost/foo/not_ok'), 'request ok' );

    like( $res->content, qr{<td>Catalyst::Test</td>.*<td>TestApp::Controller::Foo</td>}s, 'reverse order  ok' );
    unlike( $res->content, qr{<td>TestApp::Controller::Foo</td>.*<td>Catalyst::Test</td>}s, 'not normal order' );
}
