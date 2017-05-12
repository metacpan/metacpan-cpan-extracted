#!perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More tests => 9;

use Catalyst::Test 'TestApp';
use HTTP::Request::Common;

my $response = request POST '/cgi-bin/test.cgi', [
    foo => 'bar',
    bar => 'baz'
];

is($response->content, 'foo:bar bar:baz', 'POST to CGI');

$response = request POST '/cgi-bin/test.cgi', [
  foo => 'bar',
  bar => 'baz',
], User_Agent => 'perl/5', Content_Type => 'form-data';

is($response->content, 'foo:bar bar:baz', 'POST to CGI (form-data)');

$response = request POST '/cgi-bin/test.cgi',
  Content => [
    foo => 1,
    bar => 2,
    baz => [
        undef,
        'baz',
        'Some-Header' => 'blah',
        'Content-Type' => 'text/plain',
        Content => 3
    ],
    quux => [ undef, quux => Content => 4 ],
  ],
  User_Agent => 'perl/5',
  Content_Type => 'form-data';

is($response->content, 'foo:1 bar:2 baz:3 quux:4', 'POST with file upload');

$response = request '/cgi-bin/test_pathinfo.cgi/path/%2Finfo';
is($response->content, '/path//info', 'PATH_INFO is correct');

$response = request '/cgi-bin/test_filepathinfo.cgi/path/%2Finfo';
is($response->content, '/test_filepath_info/path//info',
    'FILEPATH_INFO is correct');

$response = request '/cgi-bin/mtfnpy/test_scriptname.cgi/foo/bar';
is($response->content, '/cgi-bin/mtfnpy/test_scriptname.cgi',
    'SCRIPT_NAME is correct');

$response = request POST '/cgi-bin/test_body_reset.cgi',
    Content => 'bar',
    User_Agent => 'perl/5',
    Content_Type => 'text/xml';
is($response->content, 'bar',
    'seek $c->req->body back to 0 on POST');

$response = request POST '/cgi-bin/test_body_post_reset.cgi',
    Content => 'baz',
    User_Agent => 'perl/5',
    Content_Type => 'text/xml';
is($response->content, 'bazbaz',
    'seek $c->req->body back to 0 on after WrapCGI POST processing');

SKIP: {
  require Catalyst;

  skip 'no $c->req->remote_user', 1
    if $Catalyst::VERSION < 5.80005;

  $ENV{REMOTE_USER} = 'TEST_USER';
  $response = request( '/cgi-bin/test_remote_user.cgi',
                       { extra_env => { REMOTE_USER => 'TEST_USER' } },
                       );
  is($response->content, 'TEST_USER', 'REMOTE_USER was passed');
}
