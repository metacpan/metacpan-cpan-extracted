#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long qw/:config no_ignore_case/;
use Astro::MoonPhase::Simple;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

my $VERBOSITY = 0;

my $params = {};
my $OUTFILE;
if( ! Getopt::Long::GetOptions(
	"date|d=s" => sub {
		die "date does not parse YYYY-MM-DD : $_[1]"
		 unless $_[1] =~ /^\d{4}\-(0[1-9]|1[012])\-(0[1-9]|[12][0-9]|3[01])$/
		;
		$params->{'date'} = $_[1]
	},
	"time|t=s" => sub {
		die "time does not parse hh:mm:ss : $_[1]"
		 unless $_[1] =~ /^(?:(?:([01]?\d|2[0-3]):)?([0-5]?\d):)?([0-5]?\d)$/
		;
		$params->{'time'} = $_[1]
	},
	"timezone|T=s" => sub {
		$params->{'timezone'} = $_[1]
	},
	"location|l=s" => sub {
		die "location does not parse lon:lat : $_[1]"
		 unless $_[1] =~ /^([-+]?([1-8]?\d(\.\d+)?|90(\.0+)?)),\s*([-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?))$/
		;
		$params->{'location'} = {'lon' => $1, 'lat' => $2}
	},
	"outfile|o=s" => \$OUTFILE,
	"verbosity|v" => sub { $VERBOSITY++ }
) ){ print STDERR Usage($0) . "\n\n$0 : something wrong with the command line parameters.\n"; exit(1) }

print perl2dump($params)."$0 : calculating moon phase using above parameters ...\n" if $VERBOSITY > 0;
my $res = calculate_moon_phase($params);
die perl2dump($params)."$0 : call to calculate_moon_phase() has failed for above parameters." unless defined $res;

if( $OUTFILE ){
	my $FH;
	open($FH, '>', $OUTFILE) or die "failed to open output file '$OUTFILE', $!";
	print $FH perl2dump($res);
	close $FH;
	print STDOUT "$0 : output written to '$OUTFILE'.\n" if $VERBOSITY > 0;
} else { print STDOUT perl2dump($res) }

sub Usage {
	my $appname = $_[0];
	return "Usage : $appname -d date [-t time] [-T timezone] [-l location] [-o outfile] [-v]\n\n"
	. " --date|-d date : specify the date in the format YYYY-MM-DD, e.g. 2012-11-20.\n"
	. "[--time|-t time : optionally specify the time in the format hh:mm:ss (e.g. 20:10:21. Default is 00:00:01.]\n"
	. "[--timezone|-T timezone : optionally set the timezone as a TZ identifier e.g. Africa/Abidjan. If you specified a location the timezone will be inferred from that if you did not specify one here.]\n"
	. "[--location|-l location : optionally specify a location, only for finding the timezone. This should be in the form of a tuple of longitude and lattitude separated by a colon, e.g. --location -81.1376:22.17927]\n"
	. "[--output|o outfile : optionally specify a filename to write the output into.]\n"
	."\nThis script will calculate the Moon Phase for a given date. It relies on DateTime to handle all historical changes occured on dates throughout the aeons. It assumes that the Moon Phase is the same irrespective of the location of the earthian observer. Location is only for the purpose of deducing the timezone.\n\nProgram by Andreas Hadjiprocopis (andreashad2\@gmail.com) (c) 2021\nThank you to Astro::MoonPhase for doing all the heavy lifting.\n"
}

