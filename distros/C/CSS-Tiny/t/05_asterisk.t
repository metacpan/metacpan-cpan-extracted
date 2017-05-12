#!/usr/bin/perl

# This test holds regression tests based on samples provided in various
# rt.cpan.org bug reports.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use CSS::Tiny;





######################################################################
# Bug #87261 for CSS-Tiny: Bug with properties starting with asterisk

# Test parsing of CSS selectors with multiple whitespace elements
my $css = CSS::Tiny->read_string( <<'END_CSS' );
.mycls {
  *display: inline;
  *zoom: 1;
}
END_CSS

if (!defined $css) {
	BAIL_OUT('CSS:Tiny object not created');
}

isa_ok( $css, 'CSS::Tiny' );
is_deeply(
	[ %$css ],
	[
		'.mycls' => {
			'*display' => 'inline',
			'*zoom' => 1,
		},
	],
	'Bug 87261: Parsing properties starting with asterisk',
);
