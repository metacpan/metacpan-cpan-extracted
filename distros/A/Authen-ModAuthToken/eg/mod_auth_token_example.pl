#!/usr/bin/env perl
use strict;
use warnings;
use Carp;
use Getopt::Long;
use Authen::ModAuthToken qw/generate_mod_auth_token/;
use File::Basename;

sub show_help();

my $server = "http://my.server.com";
my $prefix = "/protected";
my $secret = "FlyingMoneys";
my $file   = undef;
my $remote_addr = undef;
my $apache = undef;

my $verbose = 0 ;

my $rc = GetOptions(
		"server|s=s" => \$server,
		"prefix|p=s" => \$prefix,
		"file|f=s"   => \$file,
		"key|k=s"    => \$secret,
		"help|h"     => \&show_help,
		"remote|r=s" => \$remote_addr,
		"verbose|v"  => \$verbose,
		"apache|a"   => \$apache,
		);
exit 1 unless $rc;
show_help() unless $file || $apache;

$prefix = '/' . $prefix unless $prefix =~ m|^/|; ## add slash to the prefix, if needed.
$file = '/' . $file if defined $file && $file !~ m|^/|; ## add slash to the filename, if needed.

if ($apache) {
	print<<EOF;

	##
	## A sample mod-auth-token protected Location.
	## see  http://code.google.com/p/mod-auth-token/ for more details.
	##

	Alias "$prefix"  "/my/protected/directory"
	<Location "/protected">
		AuthTokenSecret       "$secret"
		AuthTokenPrefix       "$prefix/"

		## Number of seconds that a Token is valid:
		AuthTokenTimeout      14400

		## Change to "on" to limit by requesting IP.
		AuthTokenLimitByIp    off
	</Location>


EOF

	exit 0;
}

my $token = generate_mod_auth_token(
	secret => $secret,
	filepath => $file,
	remote_addr => $remote_addr) ;

my $url = $server . $prefix . $token ;

print $url, "\n";


sub show_help()
{
	my $base=basename($0);
	print<<EOF;
Authen::ModAuthToken example
Copyright (C) 2012 by A. Gordon <gordon at cshl.edu>

Usage:
   $base [OPTIONS]

Options:

   -h
   --help           This helpful help screen.

   -v
   --verbose        Show server\/prefix\/url


   -s SERVER
   --server SERVER  Set the server name (default: $server)

   -p PREFIX
   --prefix PREFIX  Set the prefix URL (default: $prefix)

   -f FILE
   --file FILE      Set the filename to protect (default: $file)

   -k KEY
   --key KEY        Set the secret key (default: $secret)

   -r IP
   --remote IP      Set the remote IP address (default: No IP limit)

   -a
   --apache         Instead of URL, print an apache configuration
                    That will work with the provided parameters.

Example:
  NOTE: your output WILL be different, as the hashed token uses the current time.

  \$ ./$base --file data.txt
  http://my.server.com/protected/65d5a4c574af9cde77333f7fe5c6737e/4f0f8569/data.txt

  \$ ./$base --key MookMook --prefix /resources --file data.txt
  http://my.server.com/resources/441e2ac060c8671bd718df49f3bc61b1/4f0f8631/data.txt

  # Print an apache configuration
  \$ ./$base --prefix /resources --key 12345678 --apache

	##
	## A sample mod-auth-token protected Location.
	## see  http://code.google.com/p/mod-auth-token/ for more details.
	##

	Alias "/resources"  "/my/protected/directory"
	<Location "/protected">
		AuthTokenSecret       "12345678"
		AuthTokenPrefix       "/resources/"

		## Number of seconds that a Token is valid:
		AuthTokenTimeout      14400

		## Change to "on" to limit by requesting IP.
		AuthTokenLimitByIp    off
	</Location>


EOF
exit 0;
}
