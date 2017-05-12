#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# use Test::More skip_all => 'Test script incomplete and spuriously failing';

use Test::More tests => 3;
use CGI          ();
use CGI::Capture ();

my $capture_string = <<'END_YAML';
---
CAPTURE_TIME: 1
STDIN: "GET http://foo.com/bar.html?foo=bar\nCookie: foo=bar\nMIME-VERSION: 1.0\n\n"
ENV:
  REQUEST_METHOD: POST
  CONTENT_TYPE: multipart/form-data

END_YAML

# Create the capture
my $capture = CGI::Capture->from_yaml_string( $capture_string );
isa_ok( $capture, 'CGI::Capture' );
$capture->{ENV}->{CONTENT_LENGTH} = length ${$capture->{STDIN}};

# Apply the capture
ok( $capture->apply, '->apply ok' );

# Get the CGI object for the request
my $cgi = CGI->new;
isa_ok( $cgi, 'CGI' );

