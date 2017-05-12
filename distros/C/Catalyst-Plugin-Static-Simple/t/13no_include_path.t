#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 4;
use Catalyst::Test 'TestApp';

# test passthrough to root
ok( my $res = request('http://localhost/images/bad.gif'), 'request ok' );
is( $res->content_type, 'image/gif', 'root path ok' );

is( scalar @{ TestApp->config->{'Plugin::Static::Simple'}->{include_path} }, 1, 'One include path used');
is( TestApp->config->{'Plugin::Static::Simple'}->{include_path}->[0], TestApp->config->{root}, "It's the root path" );
