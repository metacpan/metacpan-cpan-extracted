
use strict;
use warnings;

use Test::More tests => 5;

use Dancer ':tests';
use Dancer::Test;

BEGIN {
    config->{plugins}{FontSubset} = {
        fonts_dir => 't/fonts',
    };
}

use Dancer::Plugin::FontSubset;

route_exists '/font/Bocklin.ttf';
response_status_is '/font/Bocklin.ttf?t=fo', 200;

my $resp = dancer_response GET => '/font/Bocklin.ttf';
my $fh = $resp->content;
is length( join '', <$fh> ) => -s 't/fonts/Bocklin.ttf';

my $resp2 = dancer_response GET => '/font/Bocklin.ttf?t=fo';
$fh = $resp->content;
cmp_ok length( join '', <$fh> ), '<', -s 't/fonts/Bocklin.ttf', 
    'subset smaller than whole set';


response_content_like '/font/subset.js' => qr/function()/, 
    'autoload.js help script';
