#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, contact.pl for ASNMTAP::Asnmtap::Applications::CGI
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "contact.pl";
my $prgtext     = "$APPLICATION Contact Server Administrators";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir  = (defined $cgi->param('pagedir')) ? $cgi->param('pagedir') : 'index'; $pagedir =~ s/\+/ /g;
my $pageset  = (defined $cgi->param('pageset')) ? $cgi->param('pageset') : 'index-cv'; $pageset =~ s/\+/ /g;
my $debug    = (defined $cgi->param('debug'))   ? $cgi->param('debug')   : 'F';
my $action   = (defined $cgi->param('action'))  ? $cgi->param('action')  : 'sendView';
my $Csubject = (defined $cgi->param('subject')) ? $cgi->param('subject') : '';
my $Cmessage = (defined $cgi->param('message')) ? $cgi->param('message') : '';

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

my $htmlTitle = $APPLICATION .' - '. $ENVIRONMENT{$environment};

# Init parameters
my ($nextAction, $submitButton, $sendMessage);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (0, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Contact", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&subject=$Csubject&message=$Cmessage";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>subject       : $Csubject<br>message       : $Cmessage<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  if ($action eq 'sendView') {
    $htmlTitle    = "Send contact email";
    $submitButton = "Send";
    $nextAction   = "send";
  } elsif ($action eq 'send') {
    my $tDebug = ($debug eq 'T') ? 2 : 0;
    my $returnCode = sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, "$APPLICATION / $Csubject", $Cmessage, $tDebug );
    $sendMessage = ( $returnCode ) ? "Email succesfully send to the '$APPLICATION' server administrators" : "Problem sending email to the '$APPLICATION' server administrators";
  }

  # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

  if ($action eq 'sendView') {
    print <<HTML;
    <form action="$ENV{SCRIPT_NAME}" method="post" name="contact">
      <input type="hidden" name="pagedir"   value="$pagedir">
      <input type="hidden" name="pageset"   value="$pageset">
      <input type="hidden" name="debug"     value="$debug">
      <input type="hidden" name="CGISESSID" value="$sessionID">
      <input type="hidden" name="action"    value="$nextAction">
HTML
  }

  print <<HTML;
  <br>
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td><table border="0" cellspacing="0" cellpadding="0">
HTML

  if ($action eq 'sendView') {
  print <<HTML;
      <tr><td><b>Subject: </b>&nbsp;</td><td><input type="text" name="subject" value="$Csubject" size="108" maxlength="108"></td></tr>
      <tr><td valign="top"><b>Message: </b>&nbsp;</td><td><textarea name=message cols=84 rows=13>$Cmessage</textarea></td></tr>
      <tr align="left"><td align="right"><br><input type="submit" value="$submitButton"></td><td><br><input type="reset" value="Reset"></td></tr>
HTML
  } else {
    print "      <tr><td class=\"StatusItem\">$sendMessage</td></tr>\n";
  }

  print "    </table>\n      </td></tr></table>\n  <br>\n";
  print "      </form>" if ($action eq 'sendView');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

