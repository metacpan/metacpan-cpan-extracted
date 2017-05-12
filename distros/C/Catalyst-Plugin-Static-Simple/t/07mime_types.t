#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 4;
use Catalyst::Test 'TestApp';

# test custom MIME types
TestApp->config->{'Plugin::Static::Simple'}->{mime_types} = {
    omg => 'holy/crap',
    gif => 'patents/are-evil',
};

ok( my $res = request('http://localhost/files/err.omg'), 'request ok' );
is( $res->content_type, 'holy/crap', 'custom MIME type ok' );

ok( $res = request('http://localhost/files/bad.gif'), 'request ok' );
is( $res->content_type, 'patents/are-evil', 'custom MIME type overlay ok' );
