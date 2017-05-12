#!/usr/bin/perl

use AxKit2::Test;
use Test::More import => [qw(like ok)];

plan tests => 2;

unlink('test_access_log');

start_server("t/server1",
    [qw(uri_to_file request_log serve_file)],
	['RequestLog test_access_log'],
);

http_get('/index.html');

stop_server;

open(FH,'<','test_access_log');

my $line = <FH>;
like($line,qr(^127\.0\.0\.1 - - \[[0-9a-zA-Z:/+ ]+\] "GET /index.html HTTP/1.1" 200 - "-" "AxKit2::Test/0.01"$), 'log format');

$line = <FH>;
ok(!defined $line, 'one line per request');

close(FH);

unlink('test_access_log');
