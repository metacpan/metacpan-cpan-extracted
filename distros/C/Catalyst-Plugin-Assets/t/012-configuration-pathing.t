#!perl

use strict;
use warnings;

use Test::More qw/no_plan/;
use t::Test;
use Catalyst::Test qw/t::TestCatalystPathing/;

my $scratch = t::TestCatalystPathing->scratch;
my $response;
ok($response = request('http://localhost/'));

ok($response = request('http://localhost/fruit-salad'));
compare($response->content, qw(  
    http://localhost/static/built/assets.css
    http://localhost/static/built/assets.js
));

is(sanitize $scratch->read("root/static/built/assets.css"), "div.auto{font-weight:bold;color:green}div.apple{color:red}div.apple{color:blue}");
is($scratch->read("root/static/built/assets.js"), 'function calculate(){return 1*30/23;}
var auto=8+4;alert("Automatically "+auto);var apple=1+4;alert("Apple is "+apple);')
