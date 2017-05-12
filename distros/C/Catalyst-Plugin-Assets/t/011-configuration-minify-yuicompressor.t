#!perl -w
BEGIN {
    use Test::More;
    plan skip_all => 'install ./yuicompressor.jar to enable this test' and exit unless -e "./yuicompressor.jar"
}

use strict;
use warnings;

use Test::More qw/no_plan/;
use t::Test;
use Catalyst::Test qw/t::TestCatalystMinifyYUICompressor/;

my $scratch = t::TestCatalystMinifyYUICompressor->scratch;
my $response;
ok($response = request('http://localhost/'));

ok($response = request('http://localhost/fruit-salad'));
compare($response->content, qw(  
    http://localhost/assets.css
    http://localhost/assets.js
));

is($scratch->read("root/assets.css"), "div.auto{font-weight:bold;color:green;}div.apple{color:red;}div.apple{color:blue;}");
is($scratch->read("root/assets.js"), 'function calculate(){return 1*30/23}var auto=8+4;alert("Automatically "+auto);var apple=1+4;alert("Apple is "+apple)')
