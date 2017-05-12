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
# Bug #60776 for CSS-Tiny: Bug in selector parsing in CSS::Tiny

# Test parsing of CSS selectors with multiple whitespace elements
my $css = CSS::Tiny->read_string( <<'END_CSS' );
.test  .bodySettings  {
  font-size:  12px;
}
END_CSS
isa_ok( $css, 'CSS::Tiny' );
is_deeply(
	[ %$css ],
	[
		'.test .bodySettings' => {
			'font-size' => '12px',
		},
	],
	'Bug 60776: Parsing with multiple whitespace',
);
