#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 29;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# 1 make sure testapp works
use_ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;

# 2-5
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'text/html; charset=utf-8',
  'No Accept header = text/html';
my @vary_headers = $mech->response->headers->{'vary'};
is ((grep { 'accept' eq lc $_} @vary_headers), 1,
    "Does not Vary on Accept headers (or sets Accept multiple times)");

$mech->add_header( Accept => 'text/html' );

# 6-8
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'text/html; charset=utf-8',
  'Accept header of text/html = text/html';

$mech->add_header( Accept => 'application/xhtml+xml' );

# 9-11
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'application/xhtml+xml; charset=utf-8',
  'Accept xhtml gives content type application/xhtml+xml';

# 12-14
$mech->get_ok('http://localhost/nothtml', 'get nothtml page');
$mech->content_like(qr/not html/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'application/json',
  'application/json is unmolested';

# 15-17
$mech->add_header( Accept => 'text/html, application/xhtml+xml');
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'application/xhtml+xml; charset=utf-8',
  'Accept xhtml AND html gives content type application/xhtml+xml';


# 18-20
$mech->add_header( Accept => 'text/html, application/xhtml+xml;q=0');
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'text/html; charset=utf-8',
  'Accept header of application/xhtml+xml with q value of 0 and text/html = text/html';

# 21-23
$mech->add_header( Accept => 'text/html;q=0, application/xhtml+xml');
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'application/xhtml+xml; charset=utf-8',
  'Accept html with a q value of 0 gives content type application/xhtml+xml';

# 24-26
$mech->add_header( Accept => '*/*');
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'text/html; charset=utf-8',
  'Accept */* content type text/html';

# 27-29
$mech->add_header( Accept => '*/*, application/xhtml+xml');
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'application/xhtml+xml; charset=utf-8',
  'Accept */* and application/xhtml+xml gives content type application/xhtml+xml';
 