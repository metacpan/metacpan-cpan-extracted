#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.09';

use lib ('blib/lib');

use Getopt::Long qw(:config no_ignore_case);
use Data::Roundtrip qw/perl2dump perl2json no-unicode-escape-permanently/;

use Android::ElectricSheep::Automator;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used
my $DEVICE;
my $CONFIGFILE;
my $OUTFILE;
my $PACKAGE_NAME;
my $FAST = 0;
if( ! Getopt::Long::GetOptions(
  'device|d=s' => \$DEVICE,
  'verbosity|v=i' => \$VERBOSITY,
  'fast' => \$FAST, # if fast then it is not full
  'package=s' => \$PACKAGE_NAME,
  'output|o=s'=> \$OUTFILE,
  'configfile|c=s' => \$CONFIGFILE,
  'help|h' => sub { print STDOUT usage(); exit(0); }
) ){ die usage() }

if( ! defined $CONFIGFILE ){ print STDERR usage(); print STDERR "\n$0 : error, a configuration file must be specified with '--configfile'.\n"; exit(1); }
if( ! -f $CONFIGFILE ){ die "$0 : failed to find config file '$CONFIGFILE'." }

my $params = {
	'configfile' => $CONFIGFILE,
	'verbosity' => $VERBOSITY,
	'device-connected' => 1,
};
# we assume there is a device connected which the user
# must specify by serial, of if just one, we connect to
# it without the serial
if( defined $DEVICE ){ $params->{'device-serial'} = $DEVICE }
else { $params->{'device-is-connected'} = 1 }

my $client = Android::ElectricSheep::Automator->new($params);
if( ! defined($client) ){ die "$0 : failed to instantiate the automator." }

my $fpars = {};
if( ! $FAST ){
	$fpars->{'lazy'} = 0;
}
if( defined $PACKAGE_NAME ){
	$fpars->{'packages'} = qr/\Q${PACKAGE_NAME}\E/i;
	$fpars->{'lazy'} = 1;
}
my $apps = $client->find_installed_apps($fpars);
if( ! defined($apps) ){ die "$0 : failed to find installed apps on the connected device." }
if( scalar(keys %$apps) == 0 ){ print STDERR "$0 : WARNING, no apps were found, surely there is something wrong.\n"; exit(1) }
# remove the null value (because in FAST mode we have no properties, only keys)
if( $FAST ){
	for (keys %$apps){
		$apps->{$_} = {} unless defined($apps->{$_})
	}
}

# $apps is a hash with keys the package name (e.g. com.google.settings whatever)
# and the value is an AppProperties object.
# you need convert_blessed and TO_JSON!

# if packages were specified we will filter the output
if( defined $PACKAGE_NAME ){
	my %newapps;
	for (keys %$apps){
		if( $_ =~ $PACKAGE_NAME ){ $newapps{$_} = $apps->{$_} }
	}
	$apps = \%newapps
}

my $jsonstr = perl2json($apps, {terse=>1, pretty=>1, convert_blessed=>1});
if( ! defined $jsonstr ){ print STDERR "$0 : error, failed to convert perl data structure to JSON.\n"; exit(1) }

if( defined $OUTFILE ){
	my $FH;
	open($FH, '>', $OUTFILE) or die "$0 : failed to open output file '$OUTFILE' for writing, $!";
	print $FH $jsonstr;
	close $FH;
} else { print STDOUT $jsonstr }

print STDOUT "$0 : done, success!".(defined($OUTFILE)?" Output written to file '$OUTFILE'.\n":"\n");

sub usage {
	return "Usage $0 --configfile CONFIGFILE [--package NAME] [--output file.json] [--fast] [--device DEVICE] [--verbosity v]"
		. "\n\nThis script will find all installed apps or those matched partially and case-insensitively by 'NAME' and dump them as JSON with their properties (e.g. MainActivity, permissions, etc.). The latter takes some time (10,15 seconds) and so it can be skipped by specifying --fast (which will dump only the names of the apps).\n"
		. "\nExample:\n"
		. "$0 --configfile config/myapp.conf --device Pixel_2_API_30_x86_ --output myapps.json\n"
		. "$0 --package clock --configfile config/myapp.conf --device Pixel_2_API_30_x86_ --output myapps.json --fast\n"
		. "\n\nProgram by Andreas Hadjiprocopis (c) 2025 / bliako at cpan.org / andreashad2 at gmail.com\n\n"
	;
}

1;
