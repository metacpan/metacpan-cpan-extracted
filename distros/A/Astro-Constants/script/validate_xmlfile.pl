#!/usr/bin/perl -w
#
# validates PhysicalConstants.xml against its schema definition
#
# TODO
#	use Cwd and relative paths so that the script can run
#	anywhere relative to the data directory

use strict;
use XML::LibXML;
use Getopt::Std;

our($opt_h, $opt_s, $opt_f, $opt_v, );
getopts('hvs:f:');

if ($opt_h) {
	print "Usage: $0 [-h|-v] [-s schema file] [-f xml file]\n";
	exit;
}

my $schema_file = $opt_s || 'data/PhysicalConstants.xsd';
my $xml_file 	= $opt_f || 'data/PhysicalConstants.xml';

die "Cannot find xml file $xml_file" unless -e $xml_file;
die "Cannot find schema file $schema_file" unless -e $schema_file;

print "Validating $xml_file against $schema_file\n" if $opt_v;

my $doc = XML::LibXML->load_xml(location => $xml_file);
my $schema = XML::LibXML::Schema->new( location => $schema_file );

eval { $schema->validate( $doc ); };
die "Couldn't validate $xml_file: $@" if $@;

print "$xml_file is valid\n";
exit;
