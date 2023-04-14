#!/usr/bin/env perl

# using object interface
# read JSON, create Perl Data Structure and print references

=head1 drp.pl

 This script reads in JSON from a file.

 The script then prints the values and path to the values.

=cut


use strict;
use warnings;
use Data::Dumper;
use IO::File;
use Getopt::Long;
#use lib './lib'; # development use only
use Data::Ref::JSON;

eval { require JSON::Parse };

if ($@) {
	die "The JSON::Parse Module must be installed\n";
} else {
	JSON::Parse->import( qw(parse_json) );
}

my $debugLevel=0;
# test case file
my $jsonFile = 'test-files/adobe-example-5.json';
my $help=0;

GetOptions (
	"l|debug-level=i" => \$debugLevel,
	"f|test-file=s" => \$jsonFile,
	"h|help!" => \$help
) or die usage(1);

if ($help) {
	usage();
	exit;
}

my $fh = new IO::File;

$fh->open($jsonFile,'r') || die "cannot open $jsonFile = $!\n";

my $slurpSave=$/;
undef $/; # slurp mode for file read
my $jsonStr = <$fh>;
$/ = $slurpSave;

my $json = parse_json($jsonStr);

my $dr = Data::Ref::JSON->new (
	{
		DEBUG	=> $debugLevel,
		DATA	=> $json
	}
);

$dr->walk;

# if using the default file of test-files/adobe-example-5.json
#print "\nGetting value for " . '$json->[2]{\'topping\'}[3]{\'type\'}' . "\n";
#print $json->[2]{'topping'}[3]{'type'} . "\n";

sub usage {
	print qq{

  $0 -[l|-debug-level] -[f|-test-file]  -[h|-help]

};
}
