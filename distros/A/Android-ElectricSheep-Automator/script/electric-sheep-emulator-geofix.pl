#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.08';

use lib ('blib/lib');

use Getopt::Long qw(:config no_ignore_case);
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use Android::ElectricSheep::Automator;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used
my $COORDINATES = {
	'latitude' => undef,
	'longitude' => undef,
};
my $DEVICE;
my $CONFIGFILE;
if( ! Getopt::Long::GetOptions(
  'latitude|lat=s' => sub { $COORDINATES->{'latitude'} = $_[1] },
  'longitude|lon=s' => sub { $COORDINATES->{'longitude'} = $_[1] },
  'device|d=s' => \$DEVICE,
  'verbosity|v=i' => \$VERBOSITY,
  'configfile|c=s' => \$CONFIGFILE,
  'help|h' => sub { print STDOUT usage(); exit(0); }
) ){ die usage() }

for (qw/latitude longitude/){ if( ! exists($COORDINATES->{$_}) || ! defined($COORDINATES->{$_}) ){ print STDERR usage(); print STDERR "\n$0 : error, $_ of the GPS coordinates is missing, it must be specified with '--$_'.\n"; exit(1); } }
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

my $ret = $client->geofix($COORDINATES);
if( ! defined($ret) ){ die perl2dump($COORDINATES, {terse=>1})."$0 : failed to fix GPS coordinates of device to above. NOTE: only emulators' can have their GPS coordinates fixed!" }

print perl2dump($COORDINATES, {terse=>1})."$0 : done, success! GPS coordinates of the device are now fixed to above.\n";

sub usage {
	return "Usage $0 --name APPNAME --configfile CONFIGFILE [--device DEVICE] [--verbosity v]"
		. "\n\nThis script will fix the GPS coordinates of an EMULATOR Android device to the provided coordinates (--latitude, --longitude). Note: only emulators' can have their GPS location fixed!\n"
		. "\nExample:\n"
		. "$0 --configfile config/myapp.conf --latitude 12.3 --longitude 45.6\n"
		. "\n\nProgram by Andreas Hadjiprocopis (c) 2025 / bliako at cpan.org / andreashad2 at gmail.com\n\n"
	;
}

1;

