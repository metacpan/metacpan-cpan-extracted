
use strict;
use warnings;

use Test::More;

use FindBin qw/$Bin/;

use lib "$Bin/lib";

use Catalyst::Test 'TestURIs';

my (undef, $c) = ctx_request;

my $tests = {
  '/static/example1.gif' => 'https://static.example.com/mystatic/static/example1.gif',
  '/static2/resources/1.gif' => 'https://static.example.com/static2/resources/1.gif',
  '/static3/resources/1.gif' => 'https://static.example.com/mystatic/static3/resources/1.gif',
  '/static4/resources/1.gif' => 'https://static.example.com/mystatic/static4/resources/1.gif',
  '/css/css1.css' => 'http://css.example.com/css/css1.css',
  '/js/script1.js' => 'http://js.example.com:99/js/script1.js',
  '/this/is/content/number1' => 'http://content.example.com/this/is/content/number1',
  '/very/secure/things' => 'https://localhost/very/secure/things',
  # Two rules will match this uri
  '/very/secure/content' => 'https://content.example.com/very/secure/content',
  '/versioned/sytlesheet.css' => 'http://static.example.com/0.01/versioned/sytlesheet.css',
  '/prefixed/thing.gif' => 'http://localhost/v2/prefixed/thing.gif',
  '/archive/stuff' => 'http://archive.example.com/archive/stuff',
  # secure/archive should first match the "secure" rule, and never match the archive rule
  '/secure/archive' => 'https://localhost/secure/archive',
};

foreach my $test (keys %$tests){
  my $url = $c->uri_for($test);
  cmp_ok($url, 'eq', $tests->{$test}, "Got correct translation for $test");
}


done_testing();
