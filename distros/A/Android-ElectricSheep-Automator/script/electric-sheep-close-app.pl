#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.08';

use lib ('blib/lib');

use Getopt::Long qw(:config no_ignore_case);

use Android::ElectricSheep::Automator;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used
my $APPNAME;
my $DEVICE;
my $CONFIGFILE;

if( ! Getopt::Long::GetOptions(
  'name|n=s' => \$APPNAME,
  'keyword=s' => sub { $APPNAME = qr/\Q$_[1]\E/i },
  'device|d=s' => \$DEVICE,
  'verbosity|v=i' => \$VERBOSITY,
  'configfile|c=s' => \$CONFIGFILE,
  'help|h' => sub { print STDOUT usage(); exit(0); }
) ){ die usage() }

if( ! defined $APPNAME ){ print STDERR usage(); print STDERR "\n$0 : error, the name of the application to close must be specified with '--name'.\n"; exit(1); }
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

my $ret = $client->close_app({
	'package' => qr/\Q$APPNAME\E/i
});
if( ! defined($ret) ){ die "$0 : failed to close app '$APPNAME'." }

print "$0 : done, success! App '$APPNAME' must now be closed.\n";

sub usage {
	return "Usage $0 --name APPNAME --configfile CONFIGFILE [--device DEVICE] [--verbosity v]"
		. "\n\nThis script will close an app on a mobile device connected on your computer given its name exactly (--name) or given a keyword (--keyword) to be matched (case insensitive) against all app names. Note that you can use electric-sheep-find-installed-apps.pl in order to list all apps on device.\n"
		. "Note that --keyword KEYWORD creates a regular expression from user input as ".'qr/\Q<userinput>\E/i'."\n"
		. "\nExample:\n"
		. "$0 --configfile config/myapp.conf --name com.android.settings\n"
		. "$0 --configfile config/myapp.conf --keyword 'clock'\n"
		. "\n\nProgram by Andreas Hadjiprocopis (c) 2025 / bliako at cpan.org / andreashad2 at gmail.com\n\n"
	;
}

1;

