#!perl

use strict;
use warnings;
use Test::More tests => 11;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response = request('/globals?view=PkgConfig');
ok($response->is_success, 'request ok');

like($response->content, qr{\b    c \s+ => \s+ TestApp \b}x, 'global c');
like($response->content, qr{\b base \s+ => \s+ http:// \b}x, 'global base');
like($response->content, qr{\b name \s+ => \s+ TestApp \b}x, 'global name');

$response = request('/additional_globals?view=PkgConfig');
ok($response->is_success, 'request ok');

like($response->content, qr{\b    c \s+ => \s+           TestApp \b}x, 'global c');
like($response->content, qr{\b base \s+ => \s+           http:// \b}x, 'global base');
like($response->content, qr{\b name \s+ => \s+           TestApp \b}x, 'global name');
like($response->content, qr{\b  foo \s+ => \s+               123 \b}x, 'global foo');
like($response->content, qr{\b  bar \s+ => \s+ \[moo, \s+ kooh\]   }x, 'global bar');
