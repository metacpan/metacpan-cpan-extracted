# Perl
# $Id: test.pl,v 1.1.1.1 2004/04/09 13:02:14 cvs Exp $ 
################################################################
# Setup custom Test script
################################################################

package testApp;

BEGIN { print "1..?\n"; }
END   { exit(0); }

my $tcount=0;
sub tt {
  printf "%3d...%s\n",$tcount,shift;
}

sub ok {
  print "--> ok $tcount\n";
  $tcount+=1;
}

sub nok {
  print "--> nok $tcount\n";
  $tcount+=1;
}

################################################################
# Use modules
################################################################

tt("Using the modules we need"); 

use Aut;
use Aut::UI::Wx;
use Aut::Backend::Conf;
use Config::Frontend;
use Config::Backend::INI;
use strict;

ok();

################################################################
# Instantiate aut system
################################################################

tt("Initializing aut object");

my $cfg=new Config::Frontend(new Config::Backend::INI("./accounts.ini"));
my $backend=new Aut::Backend::Conf($cfg);
my $ui=new Aut::UI::Wx();
ok();

################################################################
# Now we need to be in side Wx
################################################################

use base 'Wx::App';

sub OnInit {
  my $dbname="zclass";
  my $host="localhost";
  my $user="zclass";
  my $pass="";
  my $dsn="dbi:Pg:dbname=$dbname;host=$host";

  ### New aut system 

  my $aut=new Aut( Backend => $backend, UI => $ui, RSA_Bits => 512 );

  #### Initializing admin

  tt("Initializing 'admin' account with password 'testpass'");

  my $ticket=$aut->ticket_get("admin","testpass");
  if (not $ticket->valid()) {
    $ticket=new Aut::Ticket("admin","testpass");
    $ticket->set_rights("admin");
    $aut->ticket_create($ticket);
  }

  ok();

  #### test ui

  #### test LOGIN

  tt("Testing user interface, logging in (login with 'admin' and 'testpass')");

  print "\n";

  $ticket=$aut->login();

  print "account :",$ticket->account(),"\n";
  print "rights  :",$ticket->rights(),"\n";

  ok();

  #### Change password

  tt("Testing user interface, Changing password");

  $aut->change_pass($ticket);

  if ($ticket->valid()) {
    my $text="This is a text!!";

    my $ciphertext=$ticket->encrypt($text);
    my $dtext=$ticket->decrypt($ciphertext);

    ok();
  }

  #### test ADMIN

  tt("Testing user interface, administrator menu (do whatever you think is appropriate ;-)).");

  $aut->admin($ticket);

  print "account :",$ticket->account(),"\n";
  print "rights  :",$ticket->rights(),"\n";

  ok();

  ### End of testing

  return 0;
}

package main;

my $a= new testApp;
$a->MainLoop();

################################################################
# Post message
################################################################

print <<EOF
You can repeat this test, after adding some accounts with different
authorization levels. Try e.g.:

- Installing with an account without 'admin' rights.
- Logging in with an invalid account (login will prompt you max. 3 times).
- Enter false data while changing the password.
- Change passwords from the admin menu.
- Change rights from the admin menu.
- Delete all accounts.
- Change rights of all accounts until and including the last admin account.

etc.

EOF










