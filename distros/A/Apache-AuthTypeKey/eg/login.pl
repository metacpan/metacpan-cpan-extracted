#!/usr/bin/perl -w
use strict;

use Apache::Util qw( escape_uri );
my $Protected = 'http://example.com/login-protected';

my $r = Apache->request;
$r->status(200);
my $prev = $r->prev;
my $uri = 'http://' . $prev->hostname . $prev->uri;

## If there are args, append them to the URI.
my $args = $prev->args;
if ($args) {
    $uri .= "?$args";
}

my $token = $prev->dir_config('TypeKeyToken');
my $tk_url = $prev->dir_config('TypeKeyURL') ||
    'https://www.typekey.com/t/typekey/login';
$uri = escape_uri("$Protected?destination=" . escape_uri($uri));

my $html = <<HTML;
<html>
<head>
<title>Login</title>
</head>
<body>
<a href="$tk_url?t=$token&v=1.1&_return=$uri">Log in via TypeKey</a>
</body>
</html>
HTML

$r->no_cache(1);
$r->content_type('text/html');
$r->header_out('Content-length' => length($html));
$r->header_out('Pragma' => 'no-cache');
$r->send_http_header;

$r->print($html);
