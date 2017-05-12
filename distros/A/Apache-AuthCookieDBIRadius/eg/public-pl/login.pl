#!/usr/bin/perl -Tw
#
# $Id: login.pl,v 1.1 2000/07/11 17:03:05 jacob Exp $
#
# Display a login form with hidden fields corresponding to the page they
# wanted to see.

use strict;
use 5.004;
use Text::TagTemplate;
use Apache;

my $t = new Text::TagTemplate;
my $r = Apache->request();

my $destination;
my $authcookiereason;
if ( $r->prev() ) { # we are called as a subrequest.
	$destination = $r->prev()->args()
	             ? $r->prev()->uri() . '?' .  $r->prev->args()
	             : $r->prev()->uri();
	$authcookiereason = $r->prev()->subprocess_env( 'AuthCookieReason' );
} else {
	$destination = $r->args( 'destination' );
	$authcookiereason = $r->args( 'AuthCookieReason' );
}
$t->add_tag( DESTINATION => $destination );

unless ( $authcookiereason eq 'bad_cookie' ) {
	$t->template_file( "../html/login.html" );
} else {
	$t->template_file( "../html/login-failed.html" );
}

$r->send_http_header;
print $t->parse_file unless $r->header_only;
