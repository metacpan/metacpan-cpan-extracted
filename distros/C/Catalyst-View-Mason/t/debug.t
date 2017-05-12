#!perl

use strict;
use warnings;
use Test::More;

eval "use IO::Capture::Stderr";
plan skip_all => "IO::Capture::Stderr required for debug testing" if $@;

plan tests => 3;

use FindBin;
use lib "$FindBin::Bin/lib";

$ENV{CATALYST_DEBUG} = 1;

my $capture = IO::Capture::Stderr->new;
$capture->start;

use_ok('Catalyst::Test', 'TestApp');

my $response = request('/test');

$capture->stop;

ok($response->is_success, 'request ok');

like(join('', $capture->read), qr{\[debug\] Rendering component "/test"}, 'debug message ok');
