use strict;
use warnings;

use Test::More import => ['!pass'];


use lib 't/lib';
use TestApp;

use Dancer2;
use Dancer2::Test apps => [ 'TestApp' ];;

plan tests => 2;

setting appdir => setting('appdir') . '/t';

my $res = dancer_response GET => '/';

ok ($res);
like $res->{content}, qr/HTTP::BrowserDetect/;
