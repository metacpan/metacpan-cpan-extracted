#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.04';

use lib ('blib/lib');

use Getopt::Long qw(:config no_ignore_case);
use Data::Roundtrip qw/perl2dump perl2json no-unicode-escape-permanently/;

use Android::ElectricSheep::Automator;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used
my $DEVICE;
my $CONFIGFILE;
my $OUTFILE;

if( ! Getopt::Long::GetOptions(
  'device|d=s' => \$DEVICE,
  'verbosity|v=i' => \$VERBOSITY,
  'output|o=s'=> \$OUTFILE,
  'configfile|c=s' => \$CONFIGFILE,
  'help|h' => sub { print STDOUT usage(); exit(0); }
) ){ die usage() }

if( ! defined $CONFIGFILE ){ print STDERR usage(); print STDERR "\n$0 : error, a configuration file must be specified with '--configfile'.\n"; exit(1); }
if( ! -f $CONFIGFILE ){ die "$0 : failed to find config file '$CONFIGFILE'." }

my $params = {
	'configfile' => $CONFIGFILE,
	'verbosity' => $VERBOSITY,
};
# we assume there is a device connected which the user
# must specify by serial, of if just one, we connect to
# it without the serial
if( defined $DEVICE ){ $params->{'device-serial'} = $DEVICE }
else { $params->{'device-is-connected'} = 1 }

my $client = Android::ElectricSheep::Automator->new($params);
if( ! defined($client) ){ die "$0 : failed to instantiate the automator." }

my $ret = $client->list_running_processes({
	'filename' => $OUTFILE
});
if( ! defined($ret) ){ die "$0 : failed to find running processes." }

print STDOUT $ret->{'raw'};

print STDOUT "$0 : done, success!".(defined($OUTFILE)?" Output JSON written to file '$OUTFILE'.\n":"\n");

sub usage {
	return "Usage $0 --configfile CONFIGFILE [--output procs.json] [--device DEVICE] [--verbosity v]\n"
		. "\nThis script will print the currently running processes in the device to STDOUT (as a normal 'ps' output), optionally saving a JSON version of the parsed 'ps' output to file.\n"
		. "\nExample:\n"
		. "$0 --configfile config/myapp.conf --output procs.json\n"
		. "\nProgram by Andreas Hadjiprocopis (c) 2025 / bliako at cpan.org / andreashad2 at gmail.com\n\n"
	;
}

1;
