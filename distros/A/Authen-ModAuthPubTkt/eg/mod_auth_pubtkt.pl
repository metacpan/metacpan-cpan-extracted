#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use Authen::ModAuthPubTkt;
use File::Basename qw/basename/;

sub parse_command_line;
sub show_help;
sub show_version;

my $private_key_file;
my $public_key_file;
my $key_type;
my $ticket;
my $username = $ENV{USER};
my $ip = "127.0.0.1";
my $valid_until = time() + 86400 ;
my $grace_period = 3600 ;
my $tokens;
my $userdata;
my $operation;
my $quiet;

##
## Program Start
##
parse_command_line();

if ( $operation eq "generate" ) {
	my $ticket = pubtkt_generate(
		privatekey => $private_key_file,
		keytype    => $key_type,
		clientip   => $ip,
		userid     => $username,
		validuntil => $valid_until,
		graceperiod=> $grace_period,
		tokens     => $tokens,
		userdata   => $userdata );

	print $ticket,"\n";
}

elsif ( $operation eq "verify" ) {
	my $ok = pubtkt_verify (
		publickey => $public_key_file,
		keytype   => $key_type,
		ticket    => $ticket
	);
	die "Error: Ticket verification failed.\n" if ! $ok && !$quiet;
	print "ok\n" if !$quiet;
}

##
## Program End
##

sub parse_command_line
{
	my $rc = GetOptions(
			"help" => \&show_help,
			"private-key=s" => \$private_key_file,
			"public-key=s" => \$public_key_file,
			"rsa" => sub { $key_type = "rsa" ; },
			"dsa" => sub { $key_type = "dsa" ; },
			"ticket=s" => \$ticket,
			"ip=s" => \$ip,
			"username=s" => \$username,
			"valid-until=i" => \$valid_until,
			"grace-period=i" => \$grace_period,
			"tokens=s" => \$tokens,
			"userdata=s" => \$userdata,
			"generate" => sub { $operation = "generate" ; },
			"verify"   => sub { $operation = "verify" ; },
			"quiet"    => \$quiet,
			"version"  => \&show_version,
	);
	exit 1 unless $rc;


	die "Error: No operation specified. Use --generate or --verify. See --help for details.\n" unless $operation;

	if ( $operation eq "generate" ) {
		die "Error: missing private key file. Use --private-key=FILE. See --help for details.\n" unless $private_key_file;
	}
	elsif ( $operation eq "verify" ) {
		die "Error: missing ticket. Use --ticket TICKET. See --help for details.\n" unless $ticket;
	}
	die "Error: missing key type. Use --rsa or --dsa. See --help for details." unless $key_type;
}

sub show_version
{
	my $version = $Authen::ModAuthPubTkt::VERSION;
	print "Using Authen::ModAuthPubTkt version $version\n";
}


sub show_help
{
	my $basename = basename($0);
	print<<EOF;
Authen::ModAuthPubTkt command line utility.
Copyright (C) 2012 by A. Gordon (gordon at cshl dot edu)

This program uses the Authen::ModAuthPubTkt to generate a 'mod_auth_pubtkt'
compatible ticket string.

Usage:
  # Generate a ticket
  $basename --generate --private-key=FILE [--rsa|--dsa] [OPTIONS]

  # verify a ticket
  $basename --verify --public-key=FILE [--rsa|--dsa] --ticket TICKET [OPTIONS]


OPTIONS:
  --help               This helpful help screen.
  --version            Show version and exit.

  --generate           Generate a new ticket, print it to STDOUT.
  --verify             Verify a ticket.
                       Prints 'ok' to STDOUT or error message to STDERR.

  --private-key FILE   The private key file (rsa or dsa).

  --public-key FILE    The public key file (rsa or dsa).
  --rsa                The key files are RSA keys.
  --dsa                The key files are DSA keys.
  --IP IP              The Client IP address (X.X.X.X).
                       Default = 127.0.0.1
  --username USER      The username. Default: current user name.
  --valid-until TIME   Validity period. Numeric value of seconds since epoch.
                       Default: current time + 24 hours.
  --grace-period       Grace period, in seconds.
                       Default: $grace_period
  --tokens TEXT        Text to be added to the "tokens" item in the ticket.
  --userdata TEXT      Text to be added to the "userdata" item in the ticket.

  --ticket TICKET      The ticket text to verify (when using --verify)
  --quiet              When verifing ticket, don't print anything to STDERR/STDOUT,
                       Just exit with code 0 for success or non-zero for failure.

Example:
   ## Generate RSA keys
   \$ ./generate_rsa_keys.sh
   RSA keys generated:
      private: rsa.privkey.pem
      public:  rsa.pubkey.pem

   ## Generate a Ticket:
   \$ $basename --generate --private-key rsa.privkey.pem --rsa
   uid=gordon;cip=127.0.0.1;validuntil=1340391983;graceperiod=1340388383;tokens=;udata=;sig=mkyCv1WIqxDynBWYYEftkBEcCi0qKzH8zdzuse9ZVMgpi0VGc+yHQ5Tzbr50AFUpBRYN/EugA9XbcbUi1gW6i7LR26HDJw5AYrykovaT3hswnYwD4mFUfHcdUxjH3XTnYYgHn8hXfBZNd560CW1q/XGFD9eVMPT3AKVEtSWYM8U=

   ## Save the ticket and verify it
   \$ TICKET=\$($basename --generate --private-key rsa.privkey.pem --rsa)
   \$ $basename --verify --public-key rsa.pubkey.pem --rsa --ticket "\$TICKET"
   ok

EOF
	exit 0;
}
