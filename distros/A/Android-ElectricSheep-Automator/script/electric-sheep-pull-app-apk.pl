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
my $OUTDIR;
my $PACKAGE_NAME;
my $WILDCARD = 0;

if( ! Getopt::Long::GetOptions(
  'device|d=s' => \$DEVICE,
  'verbosity|v=i' => \$VERBOSITY,
  'output|o=s'=> \$OUTDIR,
  'package|p=s', \$PACKAGE_NAME,
  'wildcard' => sub { $WILDCARD = 1 },
  'configfile|c=s' => \$CONFIGFILE,
  'help|h' => sub { print STDOUT usage(); exit(0); }
) ){ die usage() }

if( ! defined $OUTDIR ){ print STDERR usage(); print STDERR "\n$0 : error, an output filename must be specified with '--output'.\n"; exit(1); }
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

if( $WILDCARD > 0 ){
	$PACKAGE_NAME = qr/\Q${PACKAGE_NAME}\E/i
}

my $sparams = {
	'package' => $PACKAGE_NAME,
	'output-dir' => $OUTDIR,
};
my $res = $client->pull_app_apk_from_device($sparams);
if( ! defined($res) ){ die perl2dump($sparams)."$0 : failed to pull APK of app specified using this name '$PACKAGE_NAME' and above parameters. Note that the error is not about not finding the app on the device, it is something else.\n"; }
my $Npackages = scalar keys %$res;
if( $Npackages == 0 ){ print STDERR "$0 : done, warning zero apps were pulled, nothing matched specified package name '$PACKAGE_NAME'.\n"; exit(0); }

my $Napks = 0;
for my $pname (sort keys %$res){
  my $arr = $res->{$pname};
  for my $v (@$arr){
	$Napks++;
	if( $VERBOSITY > 0 ){ print STDOUT "$0 : package '$pname' : saved apk ${Napks} from '".$v->{'device-path'}."' into '".$v->{'local-path'}."'.\n" }
  }
}
print STDOUT "$0 : done, success! Extracted ${Napks} APK(s) from ${Npackages} packages, written to output dir '$OUTDIR'.\n";

sub usage {
	return "Usage $0 --package NAME --output apkdir --configfile CONFIGFILE [--wildcard] [--device DEVICE] [--verbosity v]\n"
		. "\nThis script will pull the APK(s) of the specified package NAME into the local dir 'OUTPUT'. The package NAME can be the full package name, e.g. 'com.android.gallery2' or a part of it, e.g. 'gallery'. Use --wildcard option if you want to match partial package names. The OUTPUT will be a directory, which will be created if it does not exist, and at the end of a successful run, it will contain the APK files related to the package name, if any. These files have the '.apk' extension. They can be decoded/analysed using the wonderful JADX disassembler.\n"
		. "\nExample:\n"
		. "  match all packages with 'gallery2' in their name:\n"
		. "$0 --configfile config/myapp.conf --output apkdir --package 'calendar2' --wildcard\n"
		. "\n  match the package name 'com.android.gallery2' exactly:\n"
		. "$0 --configfile config/myapp.conf --output apkdir --package 'com.android.gallery2'\n"
		. "\nProgram by Andreas Hadjiprocopis (c) 2025 / bliako at cpan.org / andreashad2 at gmail.com\n\n"
	;
}

1;
