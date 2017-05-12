#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
	eval { require Catalyst::View::TT }
        or plan skip_all =>
        "Catalyst::View::TT is required for this test";
	eval { require Catalyst::Action::RenderView }
        or plan skip_all =>
        "Catalyst::Action::RenderView is required for this test";
	eval { require Test::WWW::Mechanize::Catalyst }
        or plan skip_all =>
        "Test::WWW::Mechanize::Catalyst is required for this test";
}

plan tests => 28;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# 1 make sure testapp works
use_ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;

# 2-4
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'text/html; charset=utf-8',
  'No Accept header = text/html';

$mech->add_header( Accept => 'text/html' );

# 5-7
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'text/html; charset=utf-8',
  'Accept header of text/html = text/html';

$mech->add_header( Accept => 'application/xhtml+xml' );

# 8-10
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'application/xhtml+xml; charset=utf-8',
  'Accept xhtml gives content type application/xhtml+xml';

# 11-13
$mech->get_ok('http://localhost/nothtml', 'get nothtml page');
$mech->content_like(qr/not html/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'application/json',
  'application/json is unmolested';

# 14-16
$mech->add_header( Accept => 'text/html, application/xhtml+xml');
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'application/xhtml+xml; charset=utf-8',
  'Accept xhtml AND html gives content type application/xhtml+xml';


# 17-19
$mech->add_header( Accept => 'text/html, application/xhtml+xml;q=0');
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'text/html; charset=utf-8',
  'Accept header of application/xhtml+xml with q value of 0 and text/html = text/html';

# 20-22
$mech->add_header( Accept => 'text/html;q=0, application/xhtml+xml');
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'application/xhtml+xml; charset=utf-8',
  'Accept html with a q value of 0 gives content type application/xhtml+xml';

# 23-25
$mech->add_header( Accept => '*/*');
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'text/html; charset=utf-8',
  'Accept */* content type text/html';

# 26-28
$mech->add_header( Accept => '*/*, application/xhtml+xml');
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
is $mech->response->headers->{'content-type'}, 'application/xhtml+xml; charset=utf-8',
  'Accept */* and application/xhtml+xml gives content type application/xhtml+xml';
 