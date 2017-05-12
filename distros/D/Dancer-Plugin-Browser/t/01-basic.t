use strict;
use warnings;

use Test::More import => ['!pass'];

use Dancer;
use Dancer::Test;

use lib 't/lib';
use TestApp;
use Data::Dumper;

plan tests => 2;

setting appdir => setting('appdir') . '/t';

session lang => 'en';
my $res = dancer_response GET => '/';
is $res->{status}, 200, 'check status response';
isa_ok($res->{content}, 'HTTP::BrowserDetect', $res->{content});
