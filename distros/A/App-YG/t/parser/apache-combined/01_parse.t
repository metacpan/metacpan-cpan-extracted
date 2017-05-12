use strict;
use warnings;
use Test::More;
use t::AppYGParserTest qw/can_parse parse_fail/;

my $parser_class = 'App::YG::Apache::Combined';
require_ok $parser_class;

note '----- OK -----';
can_parse(
    $parser_class,
    '127.0.0.1 - - [30/Sep/2012:12:34:56 +0900] "GET /foo HTTP/1.0" 200 123 "http://example.com/" "Mozilla/5.0"',
    [
        '127.0.0.1',
        '-',
        '-',
        '30/Sep/2012:12:34:56 +0900',
        'GET /foo HTTP/1.0',
        '200',
        '123',
        'http://example.com/',
        'Mozilla/5.0',
    ],
);
can_parse(
    $parser_class,
    'example.com - - [06/Aug/2012:12:34:56 +0900] "POST /bar HTTP/1.1" 404 4567 "http://example.com/index.html" "Mozilla/5.0 (compatible; Linux;)"',
    [
        'example.com',
        '-',
        '-',
        '06/Aug/2012:12:34:56 +0900',
        'POST /bar HTTP/1.1',
        '404',
        '4567',
        'http://example.com/index.html',
        'Mozilla/5.0 (compatible; Linux;)',
    ],
);

note '----- NG -----';
parse_fail(
    $parser_class,
    'this is bad log!'
);
parse_fail(
    $parser_class,
    '127.0.0.1 - - (30/Sep/2012:12:34:56 +0900) "GET /foo HTTP/1.0" 200 123 "http://example.com/" "Mozilla/5.0"'
);

done_testing;
