#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.08';

use lib ('blib/lib');

use Getopt::Long qw(:config no_ignore_case);
use Data::Roundtrip qw/perl2dump perl2json no-unicode-escape-permanently/;

use Android::ElectricSheep::Automator;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used
my $DEVICE;
my $CONFIGFILE;
my $APKFILENAME;
my @INSTALL_PARAMS;

if( ! Getopt::Long::GetOptions(
  'device|d=s' => \$DEVICE,
  'verbosity|v=i' => \$VERBOSITY,
  'apk-filename|i=s', sub { if( ! -f $_[1] ){ die "$0 : error, input apk filename (".$_[1].") does not exist." } $APKFILENAME = $_[1]; },
  'configfile|c=s' => \$CONFIGFILE,
  'install-parameter|p=s' => sub { push @INSTALL_PARAMS, $_[1] },
  'help|h' => sub { print STDOUT usage(); exit(0); }
) ){ die usage() }

if( ! defined $APKFILENAME ){ print STDERR usage(); print STDERR "\n$0 : error, an input APK filename to be installed must be specified with '--apk-filename'.\n"; exit(1); }
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

my $sparams = {
	'apk-filename' => $APKFILENAME,
	'install-parameters' => \@INSTALL_PARAMS,
};
my $res = $client->install_app($sparams);
if( 1 == $res ){ die perl2dump($sparams)."$0 : failed to install APK file '$APKFILENAME'." }
print STDOUT "$0 : done, success! APK '$APKFILENAME' is now installed on the device.\n";

sub usage {
	return "Usage $0 --apk-filename FILENAME --configfile CONFIGFILE [--install-parameter|-p 'PARAM'] [--device DEVICE] [--verbosity v]\n"
		. "\nThis script will install the specified APK file onto the device. It accepts extra parameters, preferably quoted, using -p 'PARAM', to be passed on to the installation command as per the documentation of adb here: https://developer.android.com/tools/adb\n"
		. "\nExample:\n"
		. "  It installs the specified APK file with -r and -g extra installation parameters (-r: reinstall, -g: grant all permissions):\n"
		. "$0 --configfile config/myapp.conf --apk-filename Gallery2.apk -p '-r' -p '-g'\n"
		. "\nProgram by Andreas Hadjiprocopis (c) 2025 / bliako at cpan.org / andreashad2 at gmail.com\n\n"
	;
}

1;
