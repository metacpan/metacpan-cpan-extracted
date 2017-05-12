use strict;
use warnings FATAL => 'all';

# test the processing of variations of the key lengths and the keys
# numbers

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw(GET_BODY POST_BODY GET);
use constant WIN32 => Apache::TestConfig::WIN32;

my $module = 'TestCGI::extra';
my $location = Apache::TestRequest::module2url($module);

my $line_end = "\n";
my $filler = "0123456789" x 6400; # < 64K

plan tests => 8, have_lwp;

ok t_cmp(POST_BODY("$location?foo=1", Content => $filler),
          "\tfoo => 1$line_end", "simple post");

ok t_cmp(GET_BODY("$location?foo=%3F&bar=hello+world"),
         "\tfoo => ?$line_end\tbar => hello world$line_end", "simple get");

my $body = POST_BODY($location, content =>
                     "aaa=$filler;foo=1;bar=2;filler=$filler");
ok t_cmp($body, "\tfoo => 1$line_end\tbar => 2$line_end",
         "simple post");

$body = POST_BODY("$location?foo=1", content =>
                  "intro=$filler&bar=2&conclusion=$filler");
ok t_cmp($body, "\tfoo => 1$line_end\tbar => 2$line_end",
         "simple post");

my $res = GET "$location?header=1";
ok t_cmp $res->code, 200, "OK";
ok t_cmp $res->header('Content-Type'),
    'text/plain; charset=utf-8',
    'Content-Type: made it';
ok t_cmp $res->header('X-err_header_out'),
    'err_headers_out',
    'X-err_header_out: made it';
ok t_cmp $res->content, 
    "err_header_out" . $line_end,
    "content OK";
