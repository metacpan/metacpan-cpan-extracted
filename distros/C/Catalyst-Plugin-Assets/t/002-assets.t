#!perl

use strict;
use warnings;

use Test::More qw/no_plan/;
use t::Test;
use Catalyst::Test qw/t::TestCatalyst/;

my $response;
ok($response = request('http://localhost/'));

ok($response = request('http://localhost/fruit-salad'));
compare($response->content, qw(  
    http://localhost/static/auto.css
    http://localhost/static/apple.css
    http://localhost/static/auto.js
    http://localhost/static/apple.js
    http://localhost/static/banana.js
));

SKIP: {
    skip 'install ./yuicompressor.jar to enable this test' unless -e "./yuicompressor.jar";

    ok($response = request('http://localhost/yui-compressor'));
    compare($response->content, qw(  
        http://localhost/static/yui-compressor/assets.css
        http://localhost/static/auto.js
        http://localhost/static/yui-compressor.js
    ));
}

ok($response = request('http://localhost/concat'));
compare($response->content, qw(  
    http://localhost/static/concat/assets.css
    http://localhost/static/concat/assets.js
));

ok(t::TestCatalyst->scratch->exists("root/static/concat/assets.js"));
ok(t::TestCatalyst->scratch->exists("root/static/concat/assets.css"));

is(t::TestCatalyst->scratch->read("root/static/concat/assets.js"), <<_END_);
/* Test js file for auto.js */

function calculate() {
    return 1 * 30 / 23;
}

var auto = 8 + 4;

alert("Automatically " + auto);

/* Test js file for root/static/concat.js */
_END_

is(t::TestCatalyst->scratch->read("root/static/concat/assets.css"), <<_END_);
/* Test css file for auto.css */

div.auto {
    font-weight: bold;
    color: green;
}

/* Comment at the end */

/* Test css file for root/static/concat.css */
_END_
