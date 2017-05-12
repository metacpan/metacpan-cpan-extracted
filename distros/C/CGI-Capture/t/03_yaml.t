#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use CGI::Capture ();

# Test YAML support
SKIP: {
	my $cgi = CGI::Capture->new;
	isa_ok( $cgi, 'CGI::Capture' );

	ok( $cgi->capture, '->capture ok' );
	my $yaml = $cgi->as_yaml;
	isa_ok( $yaml, 'YAML::Tiny' );

	# Does the YAML document round-trip
	my $yaml2 = YAML::Tiny->read_string( $yaml->write_string );
	is_deeply( $yaml, $yaml2, 'YAML object round-trips ok' );

	# Generate the YAML document
	my $string = $cgi->as_yaml_string;
	ok( $string =~ /^---\nARGV:\s/, '->as_yaml returns a YAML document' );

	# Round-trip the CGI::Capture
	my $cgi2 = CGI::Capture->from_yaml_string( $string );
	is_deeply( $cgi, $cgi2, 'CGI::Capture round-trips ok' );
}
