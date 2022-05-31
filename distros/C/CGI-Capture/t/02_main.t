#!/usr/bin/perl

# Main tests for CGI::Capture.
# There aren't many, but then CGI::Capture is so damned simple that
# there's really not that much to test.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use File::Spec::Functions ':ALL';
use CGI::Capture ();

# Check that the use of IO::String for _stdin works
SCOPE: {
	my $input     = "foo\nbar\n";
	my $input_ref = \$input;
	ok( CGI::Capture->_stdin( $input_ref ), 'Set STDIN ok' );
	my $foo = <STDIN>;
	my $bar = <STDIN>;
	is( $foo, "foo\n", 'Read from STDIN ok' );
	is( $bar, "bar\n", 'Read from STDIN ok' );
}

# Test basic functionality
SCOPE: {
	# Create a new object
	my $cgi = CGI::Capture->new;
	isa_ok( $cgi, 'CGI::Capture' );

	# Check that capture auto-constructs
	$cgi = CGI::Capture->capture;
	is( $cgi->{CONFIG_PATH}, $INC{'Config.pm'}, 'Config path is captured' );
}

exit(0);
