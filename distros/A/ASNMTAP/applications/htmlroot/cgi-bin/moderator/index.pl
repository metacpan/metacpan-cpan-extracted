#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, index.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

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
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MODERATOR);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "index.pl";
my $prgtext     = "$APPLICATION Moderator";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir = (defined $cgi->param('pagedir')) ? $cgi->param('pagedir') : '<NIHIL>';   $pagedir =~ s/\+/ /g;
my $pageset = (defined $cgi->param('pageset')) ? $cgi->param('pageset') : 'moderator'; $pageset =~ s/\+/ /g;
my $debug   = (defined $cgi->param('debug'))   ? $cgi->param('debug')   : 'F';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'moderator', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Moderator Menu", undef);

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
	  <tr><td class="StatusItem"><font size="+1">Moderator</font></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="sessions.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Session Console (for the Display)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="runStatusOnDemand.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Status Console (for the Collector/Display/Import Data Through Catalog)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="trendlineCorrectionReports.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Trendline Correction Reports (for the Collector)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="pluginCrontabSchedulingReports.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Plugin Crontab Scheduling Reports (for the Collector)</a></td></tr>
	  <tr><td class="StatusItem"><a href="collectorCrontabSchedulingReports.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Collector Crontab Scheduling Reports (for the Collector)</a></td></tr>
	  <tr><td class="StatusItem"><a href="collectorDaemonSchedulingReports.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Collector Daemon Scheduling Reports (for the Collector)</a></td></tr>
	  <tr><td class="StatusItem">&nbsp;</td></tr>
	  <tr><td class="StatusItem"><a href="comments.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Comments (to set the comments for a group of related tests)</a></td></tr>
	  <tr><td class="StatusItem"><a href="downtimes.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Downtimes (to set the downtime for a group of related tests)</a></td></tr>
	  <tr><td class="StatusItem"><a href="plugins.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=F&amp;CGISESSID=$sessionID">Plugins (to edit short description, trendline, holiday bundle and uploading plugindoc)</a></td></tr>
	</table>
  </td></tr></table>
  <br>
HTML
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

