#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.08';

use lib ('blib/lib');

use Getopt::Long qw(:config no_ignore_case);
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use Android::ElectricSheep::Automator::Plugins::Apps::Viber;

my $VERBOSITY = 0; # we need verbosity of 10 (max), so this is not used
my ($DEVICE, %SENDPARS, $CONFIGFILE);
my $CLOSE_APP_AFTER = 0;
if( ! Getopt::Long::GetOptions(
  'recipient=s' => sub { $SENDPARS{$_[0]} = $_[1] },
  # 1) no unicode, 2) each space must be converted to '%s'
  'message=s' => sub { $SENDPARS{$_[0]} = $_[1] },
  'outbase=s' => sub { $SENDPARS{$_[0]} = $_[1] },
  'mock' => sub { $SENDPARS{$_[0]} = 1 },

  'close-app-after' => sub { $CLOSE_APP_AFTER = 1 },
  'device|d=s' => \$DEVICE,
  'verbosity|v=i' => \$VERBOSITY,
  'configfile|c=s' => \$CONFIGFILE,
  'help|h' => sub { print STDOUT usage(); exit(0); }
) ){ die usage() }

for ('message', 'recipient'){
	if( ! exists($SENDPARS{$_}) || ! defined($SENDPARS{$_}) ){ print STDERR usage(); print STDERR "\n$0 : error, input parameter '$_' is missing.\n"; exit(1); }
}
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

my $client = Android::ElectricSheep::Automator::Plugins::Apps::Viber->new($params);
if( ! defined($client) ){ die "$0 : failed to instantiate the automator." }

# navigate to the home screen, get rid of previous tests rubbish
$client->mother->home_screen();

my ($res);
# open the app if it is not running or bring it to foreground
# IT IS IMPORTANT TO BE IN THE FOREGROUND
# open the app
$res = $client->open_app();
if( ! defined($res) ){ die "$0 : failed to open Viber app." }
sleep(4);
# is the app running?
$res = $client->is_app_running();
if( ! defined($res) ){ die "$0 : failed to check if Viber app is running." }
if( $res != 1 ){ die "$0 : Viber app is not running yet, perhaps increase the waiting time..." }

# ok app is running and on the foreground

my $ret = $client->send_message(\%SENDPARS);
if( ! defined($ret) ){ die "$0 : failed to send message." }
if( $VERBOSITY > 0 ){ print STDOUT "$0 : message sent OK.\n" }

if( $CLOSE_APP_AFTER ){
	if( $VERBOSITY > 0 ){ print STDOUT "$0 : closing the app ...\n" }
	$res = $client->close_app();
	if( ! defined($res) ){ die "$0 : failed to close Viber app (message was sent successfully)." }
	sleep(4);
	# is the app still running?
	$res = $client->is_app_running();
	if( ! defined($res) ){ die "$0 : failed to check if Viber app is running (message was sent successfully)." }
	if( $res != 1 ){ die "$0 : Viber app is not running yet, perhaps increase the waiting time (message was sent successfully) ..." }
}

if( $VERBOSITY > 0 ){ print STDOUT "$0 : done, message was sent to recipient '".$SENDPARS{'recipient'}."' successfully.\n" }

sub usage {
	return "Usage $0 --configfile CONFIGFILE --recipient R --message M [--mock] [--outbase OUTBASE] [--close-app-after] [--device DEVICE] [--verbosity v]"
		. "\n\nThis script will send the specified message to the specified recipient using the Viber app.\n"
		. "\nThe message must not have unicode characters and all spaces in it must be replaced with '%s'.\n"
		. "\nExample:\n"
		. "$0 --message 'hello%sthere' --recipient 'george' --configfile config/myapp.conf\n"
		. "\nThis saves a lot of debugging information, if it fails to find a button etc. use this:\n"
		. "$0 --outbase debug --verbosity 1 --message 'hello%sthere' --recipient 'george' --configfile config/myapp.conf\n"
		. "\nMock it, do not send any message but do everything else (open app, find buttons etc.):\n"
		. "$0 --mock --message 'hello%sthere' --recipient 'george' --configfile config/myapp.conf\n"
		. "Use the flag --close-app-after in order to close the app when the message is sent.\n"
		. "\n\nProgram by Andreas Hadjiprocopis (c) 2025 / bliako at cpan.org / andreashad2 at gmail.com\n\n"
	;
}

1;

