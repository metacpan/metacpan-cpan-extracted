use strict;
use warnings FATAL =>'all';

use FindBin;
use Test::More;
use HTTP::Request::Common qw/GET/;

use lib "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp';

SKIP: {
  skip 'Catalyst Not in Debug Mode', 4 unless TestApp->debug;
  is request(GET '/foo?http-accept=text/plain')->content, 'text_plain';
  is request(GET '/foo?http-accept=text/html')->content, 'text_html';
  is request(GET '/foo?http-accept=application/json')->content, 'json';
  is request(GET '/text_plain_and_html?http-accept=text/html&http-accept=text/plain')->content, 'text_plain_and_html';
}

is request(GET '/foo', 'Accept' => 'text/plain')->content, 'text_plain';
is request(GET '/foo', 'Accept' => 'text/html')->content, 'text_html';
is request(GET '/foo', 'Accept' => 'application/json')->content, 'json';
is request(GET '/text_plain_and_html', 'Accept' => ['text/html','text/plain'])->content, 'text_plain_and_html';
is request(GET '/text_plain_and_html', 'Accept' => ['text/html'])->content, 'text_plain_and_html';
is request(GET '/text_plain_and_html', 'Accept' => ['text/plain'])->content, 'text_plain_and_html';

is(request(GET '/baz')->content, 'any');
is(request(GET '/baz', 'Accept' => 'text/plain')->content, 'any');
is(request(GET '/baz', 'Accept' => 'text/html')->content, 'any');
is(request(GET '/baz', 'Accept' => ['text/html','text/plain'])->content, 'any');

is request(GET '/chained')->content, 'error_not_accepted';
is request(GET '/chained', 'Accept' => 'text/plain')->content, 'text_plain';
is request(GET '/chained', 'Accept' => 'text/html')->content, 'text_html';
is request(GET '/chained', 'Accept' => 'application/json')->content, 'json';

done_testing;
