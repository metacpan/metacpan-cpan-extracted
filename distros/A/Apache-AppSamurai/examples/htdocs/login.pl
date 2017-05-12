#!/usr/bin/perl
#
# $Id: login.pl,v 1.9 2008/05/03 06:43:24 pauldoom Exp $

# Decide which mod_perl to load
BEGIN {
    use vars qw($MP);
    if (eval{require mod_perl2;}) {
	$MP = 2;
    } else {
	require mod_perl;
	$MP = 1;
    }
}

use strict;
use warnings;
# Use the session key maker and session ID computer (which is just a
# HMAC) for CSRF protection in the login form
use Apache::AppSamurai::Util qw(CreateSessionAuthKey ComputeSessionId
				CheckSidFormat HashPass);


# Point to HTML login page
my $formsource = "login.html";

# Mod_Perl 2 does not chdir to the script's folder, so you must use
# a full path.  The list below includes common base paths.  Remove
# the other array items and enter your local path if none of these
# match you setup.
my @formpaths = ( "/var/www/htdocs/AppSamurai",
		  "/var/www/html/AppSamurai",
		  "/htdocs/AppSamurai",
		  "/html/AppSamurai"
		  );

# This is lame.  Just cycles the paths looking for the form source
# template ($formsource)
my $ffound = 0;
foreach (@formpaths) {
    if (-f "$_/$formsource") {
	$formsource = "$_/$formsource";
	$ffound = 1;
	last;
    }
}

($ffound) or die "FATAL: Could not find form source template file $formsource\n";

# These will replace any __NAME__ values in the form
my %params = ( MESSAGE => '',
	       REASON => '',
               URI => '',
	       FORMACTION => '/AppSamurai/LOGIN',
	       USERNAME => ''
	       );


my $r = shift;
($r) or die "FATAL: NO REQUEST SENT TO SCRIPT!\n";

# if there are args, append that to the uri after checking for and removing
# any ASERRCODE code.
$params{URI} = $r->prev->uri || '';

my $args = $r->prev->args || '';

if (($args) && ($args =~ s/&?ASERRCODE\=(bad_credentials|no_cookie|bad_cookie|expired_cookie)//)) {
    $params{REASON} = $1;
}

if ($args) { 
    $params{URI} .= '?' . $args;
}

# These messages have HTML in them with CSS. (Update as needed, or add a
# JavaScript snippet to check a hidden value and display the corresponding
# message, then just set a variable.)

# Default message
$params{MESSAGE} = "<span class=\"infonormal\">Please log in</span>";

if ($params{REASON} eq 'bad_credentials') {
    # Login failure	
    $params{MESSAGE} = "<span class=\"infored\">Access Denied - The credentials supplied were invalid. Please try again.</span>";
} elsif ($params{REASON} eq 'expired_cookie') {
    # Expired session
    $params{MESSAGE} = "<span class=\"infored\">Access Denied - Your session has expired. Please log in.</span>";
}

# Build nonce and HMAC (using server key) fro CSRF protection.  (Note - this
# only protects the login form.... once logged in, the app must protect itself.
# Yet another place where having bidirectional filtering would be useful)
# Required for CSRF protection

# Note - Pulling session config code out of the main module would allow this
# to be much shorter/simpler. Strike 90834895345 against the giant module.
# TODO - This should be in a module!!!
my $auth_name = ($r->auth_name()) || (die("login.pl(): No auth name defined!\n"));
my $dirconfig = $r->dir_config;
my $serverkey = '';
if (exists($dirconfig->{$auth_name . "SessionServerPass"})) {
    my $serverpass = $dirconfig->{$auth_name . "SessionServerPass"};
    ($serverpass =~ s/^\s*([[:print:]]{8,}?)\s*$/$1/s) || 
	die('error', "login.pl(): Invalid ${auth_name}SessionServerPass (must be use at least 8 printable characters\n");
    ($serverpass =~ /^(password|serverkey|serverpass|12345678)$/i) && 
	die("login.pl: ${auth_name}SessionServerPass is $1...  That is too lousy\n");
    
    ($serverkey = HashPass($serverpass)) || die("login.pl: Problem computing server key hash for $auth_name");

} elsif (exists($dirconfig->{$auth_name . "SessionServerKey"})) {
    $serverkey = $dirconfig->{$auth_name . "SessionServerKey"};

} else {
    die("login.pl(): You must configure either ${auth_name}SessionServerPass or ${auth_name}SessionServerKey in your Apache configuration\n"); 
}

# Check for valid key format
(CheckSidFormat($serverkey)) || die("login.pl(): You must a valid ${auth_name}SessionServerPass or ${auth_name}SessionServerKey configured!");

# Get a nonce.  Note - since this gets sent back, and it is the same as the alg
# used to get the random session key, PRNG weakness could be an issue.
$params{NONCE} = CreateSessionAuthKey();

# Get HMAC of nonce with server key (this is just like we use the session key
# and server key to get the real session ID, though THIS time we are sending it
# to the browser.)
$params{SIG} = ComputeSessionId($params{NONCE}, $serverkey);

# Read in form
my $form = '';
open(F, "$formsource") or die "FATAL: Could not find/open login page content\n";
while (<F>) {
    $form .= $_;
}
close(F);

# Apply parameters
foreach (keys %params) {
    $form =~ s/__${_}__/$params{$_}/gs;
}

$r->no_cache(1);

$r->content_type("text/html");
$r->headers_out->set("Content-length", length($form));
$r->headers_out->set("Pragma", "no-cache");
# Only for mod_perl 1
($MP eq 1) and $r->send_http_header;

$r->print ($form);
