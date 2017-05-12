#!/usr/bin/perl -w
#
# takes an astroconst.dat file and writes out a much better xml version
# Boyd Duffee, Dec 2015

use strict;
use autodie;
use XML::Writer;

die "Usage: $0 infile outfile" unless @ARGV == 2;

open my $fh_in, '<', $ARGV[0];
my $output = IO::File->new($ARGV[1], 'w');

my $xml;
my $category = $ARGV[0] =~ s%.*?([^/]+)\.dat%$1%r;
my $writer = XML::Writer->new( OUTPUT => $output, DATA_INDENT => 4, );
$writer->setDataMode(1);

write_collection_header($writer);

while (<$fh_in>) {
	next if /^#/ || /^\s*$/;
	chomp;

	my @fields = split /\t/;
	my ($short, $long, $description, $cgs, $mks, $precision);

	if (@fields == 6) {
		($short, $long, $description, $cgs, $mks, $precision) = @fields;
	}
	elsif (@fields == 5) {
		($short, $long, $description, $cgs, $precision) = @fields;
		undef $mks;
	}
	else {
		print "Error with $_";
	}

	$writer->startTag('PhysicalConstant');
	$writer->dataElement('name', $long, 'type' => 'long');
	$writer->dataElement('name', $short, 'type' => 'short');
	$writer->emptyTag('alternateName');
	$writer->dataElement('description', $description);

	#print "Extra stuff in \n", $_ if $extra;

	if (! defined $mks ) {
		# Unitless constant
		$writer->dataElement('value', $cgs );
	}
	else {
		$writer->dataElement('value', $mks, system => 'MKS');
		$writer->dataElement('value', $cgs, system => 'CGS');
	}

	$writer->dataElement('uncertainty', $precision, type => 'relative');		# absolute|relative
	$writer->emptyTag('dimensions');	# mass^1, length^-3, time|luminosity
	$writer->emptyTag('maxValue');
	$writer->emptyTag('minValue');

	my $search_term = $short =~ s/A_//r;
	$writer->emptyTag('url', 'href' => "http://physics.nist.gov/cgi-bin/cuu/Value?$search_term");

	$writer->startTag('categoryList');
	$writer->dataElement('category', $category);
	$writer->endTag();
	$writer->endTag('PhysicalConstant');
}

$writer->endTag('items');
$writer->endTag('Collection');

$writer->end();

$output->close();	# print $xml;
exit;

####

sub write_collection_header {
	my $w = shift;

	$w->xmlDecl( 'UTF-8' );
	$w->startTag('Collection');
	$w->dataElement('title', 'Astro::Constants');
	$w->startTag('description');
		$w->characters('Physical constants for astronomy for use in Astro::Constants v0.10');
	$w->endTag();
	$w->dataElement('timestamp', scalar localtime );
	$w->dataElement('version', 'v0.10');
	$w->dataElement('source', '2014 CODATA');
	$w->emptyTag('link', href => 'http://metacpan.org/pod/Astro::Constants');

	$w->startTag('items');

	return $w;
}
