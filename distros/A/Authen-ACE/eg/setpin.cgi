#! /ipl/perl5/bin/perl

# $Id: setpin.cgi,v 1.1 1997/09/19 16:40:36 carrigad Exp $

# Copyright (C), 1997, Interprovincial Pipe Line Inc.

use strict;

use CGI;

use Authen::ACE;

my $query = new CGI;
my $myurl = $query->url;

print $query->header;

print $query->start_html(-title => "Setting Your SecurID PIN",
			 -bgcolor => "white");

my $username = $query->param("username");
my $token = $query->param("token");
my $pin = $query->param("pin");
my $confirm = $query->param("confirm");

# Basic sanity checks before we even contact the ACE server
if ($username eq "" or $token eq "") {
  print "Sorry, but you must enter a username and a token. Please go back and try again.\n";
  exit(0);
}

if ($pin ne $confirm) {
  print "Sorry, but the two PINs do not match. Please go back and try again.\n";
  exit(0);
}

if (length($pin) && !($pin =~ /[a-z0-9]/i)) {
  print "Your chosen PIN does not consist solely of letters and numbers.\n";
  print "Please go back and choose a new PIN.\n";
  exit(0);
}

# Connect to the ACE
my $ace;
eval {$ace = new Authen::ACE;};
if ($@) {
  print <<EOF

Hmm. There was an error in trying to communicate with the
authentication server. Please contact the Help Desk at 420-8255 and
report the following error message to them: <p>

<hr>

<pre>
 $@
</pre>

<hr>

EOF
  ;
  exit(0);
}

# Make sure that the token is valid and the card is in new PIN mode
my ($result, $nt) = $ace->Check($token, $username);
if ($result != ACM_NEW_PIN_REQUIRED) {
  print <<EOF

Sorry, but the Authentication Server did not accept your token.
Possible causes are

<ul>
<li>You misspelled your username
<li>You mistyped the token
<li>Your card already has a PIN
</ul>

Please try to rectify the problem, or call the Help Desk at 420-8255
for assistance or if you would like to change your PIN.

EOF
  ;
  exit(0);
}

# Miscellaneous checks
# If user must choose PIN, then he better have provided one
if ($nt->{"user_selectable"} == MUST_CHOOSE_PIN && $pin eq "") {
  print "Sorry, but the system cannot generate a PIN for this card.\n";
  print "Please go back and enter a proper PIN.\n";
  exit(0);
}

# If the user gets no choice, or if the PIN was blank, set the system pin
if ($nt->{"user_selectable"} == CANNOT_CHOOSE_PIN || $pin eq "") {
  if ($ace->PIN($nt->{"system_pin"}) == ACM_NEW_PIN_ACCEPTED) {
    if ($nt->{"user_selectable"} == CANNOT_CHOOSE_PIN) {
      print "The system does not allow user-chosen PINs for this card.\n";
      print "It has generated a PIN for you.\n";
    }

    print "The system has assigned you a new PIN of <b>",
    $nt->{"system_pin"}, "</b>.\n";
  } else {
    print "Sorry, but the attempt to set your PIN failed.\n";
    print "Please call the Help Desk at 420-8255 for assistance.\n";
  }
  exit(0);
}

# Check the pin against system requirements
if (length($pin) > $nt->{"max_pin_len"}) {
  print "The PIN you chose is too long.\n";
  print "The maximum PIN length is ", $nt->{"max_pin_len"}, ".\n";
  print "Please go back and try again.\n";
  $ace->PIN("",1);
  exit(0);
}

if (length($pin) < $nt->{"min_pin_len"}) {
  print "The PIN you choose is too short.\n";
  print "The minimum PIN length is ", $nt->{"min_pin_len"}, ".\n"; 
  print "Please go back and try again.";
  $ace->PIN("",1);
  exit(0);
}

if (!$nt->{"alphanumeric"} && $pin =~ /\D/) {
  print "The system only allows numeric PINs for this card.\n";
  print "Please go back and try again.\n";
  $ace->PIN("",1);
  exit(0);
}

if ($ace->PIN($pin) == ACM_NEW_PIN_ACCEPTED) {
  print "The system has successfully set your chosen PIN.\n";
} else {
  print "Sorry, but the attempt to set your PIN failed.\n";
  print "Please call the Help Desk at 420-8255 for assistance.\n";
}
exit(0);
