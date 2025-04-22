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
my %OTHEROPTIONS;
if( ! Getopt::Long::GetOptions(
  'time-limit=s' => sub { $OTHEROPTIONS{$_[0]} = $_[1] },
  'bit-rate=s' => sub { $OTHEROPTIONS{$_[0]} = $_[1] },
  'width=s' => sub { $OTHEROPTIONS{'size'}->{$_[0]} = $_[1] },
  'height=s' => sub { $OTHEROPTIONS{'size'}->{$_[0]} = $_[1] },
  'bugreport' => sub { $OTHEROPTIONS{'size'}->{$_[0]} = 1 },

  'device|d=s' => \$DEVICE,
  'verbosity|v=i' => \$VERBOSITY,
  'output|o=s'=> \$OUTFILE,
  'configfile|c=s' => \$CONFIGFILE,
  'help|h' => sub { print STDOUT usage(); exit(0); }
) ){ die usage() }

if( ! defined $OUTFILE ){ print STDERR usage(); print STDERR "\n$0 : error, an output filename must be specified with '--output'.\n"; exit(1); }
if( ! defined $CONFIGFILE ){ print STDERR usage(); print STDERR "\n$0 : error, a configuration file must be specified with '--configfile'.\n"; exit(1); }
if( ! -f $CONFIGFILE ){ die "$0 : failed to find config file '$CONFIGFILE'." }

if( exists($OTHEROPTIONS{'size'}) ){ for (qw/width height/){ if( ! exists($OTHEROPTIONS{'size'}->{$_}) || ! defined($OTHEROPTIONS{'size'}->{$_}) ){ print STDERR usage(); print STDERR "\n$0 : error, the output video size must be specified completely with 'width' AND 'height'. '$_' is missing.\n"; exit(1); } } }

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

if( $client->dump_current_screen_video({
	%OTHEROPTIONS,
	'filename' => $OUTFILE,
}) ){ die "$0 : failed to record current screen as an MP4 video." }

print STDOUT "$0 : done, success! Output written to file '$OUTFILE'.\n";

sub usage {
	return "Usage $0 --configfile CONFIGFILE --output video.mp4 [--bit-rate BITSperSECONDS] [--time-limit SECONDS] [--width W --height H] [--bugreport] [--device DEVICE] [--verbosity v]\n"
		. "\nThis script will record the current screen as an MP4 video to the specified output filename with some optional settings like duration (--time-limit SECONDS), --bit-rate BPS, --bugreport, etc.\n"
		. "\nExample:\n"
		. "$0 --configfile config/myapp.conf --output video.mp4\n"
		. "$0 --configfile config/myapp.conf --output video.mp4 --width 1280 --height 720 --bit-rate 20000000\n"
		. "\nProgram by Andreas Hadjiprocopis (c) 2025 / bliako at cpan.org / andreashad2 at gmail.com\n\n"
	;
}

1;
