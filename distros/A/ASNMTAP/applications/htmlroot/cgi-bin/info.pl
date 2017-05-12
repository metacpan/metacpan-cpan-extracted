#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, info.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI $ASNMTAPMANUAL);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "info.pl";
my $prgtext     = "$APPLICATION Info";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir = (defined $cgi->param('pagedir')) ? $cgi->param('pagedir') : 'index';    $pagedir =~ s/\+/ /g;
my $pageset = (defined $cgi->param('pageset')) ? $cgi->param('pageset') : 'index-cv'; $pageset =~ s/\+/ /g;
my $debug   = (defined $cgi->param('debug'))   ? $cgi->param('debug')   : 'F';

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

my $htmlTitle = $APPLICATION .' - '. $ENVIRONMENT{$environment};

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (0, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Info Menu", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

  print <<HTML;
  <br>
  <table width="100%" border="0" cellspacing="0" cellpadding="0"><tr align="center"><td>
	<table border="0" cellspacing="0" cellpadding="0">
	  <tr><td class="StatusItem"><a href="$HTTPSURL/cgi-bin/users.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Change your account settings</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="$HTTPSURL/cgi-bin/contact.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Contact server administrators</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="$PDPHELPURL/$ASNMTAPMANUAL" target="_blank">'$APPLICATION' manual</a></td></tr>
	</table>
  </td></tr></table>
  <br>
HTML
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

