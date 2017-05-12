#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, perfparse.pl for ASNMTAP::Asnmtap::Applications::CGI
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;
use Shell;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "perfparse.pl";
my $prgtext     = "Launch PerfParse";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir = (defined $cgi->param('pagedir')) ? $cgi->param('pagedir') : 'index'; $pagedir =~ s/\+/ /g;
my $pageset = (defined $cgi->param('pageset')) ? $cgi->param('pageset') : 'index-cv'; $pageset =~ s/\+/ /g;
my $debug   = (defined $cgi->param('debug'))   ? $cgi->param('debug')   : 'F';

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

my $htmlTitle = $APPLICATION .' - '. $ENVIRONMENT{$environment};

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'member', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "PerfParse", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID";

# Debug information
print "<pre>pagedir   : $pagedir<br>pageset   : $pageset<br>debug     : $debug<br>CGISESSID : $sessionID<br>URL ...   : $urlAccessParameters</pre>" if ( $debug eq 'T' );

unless ( defined $errorUserAccessControl ) {
  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
  print '<br>', "\n", '<table WIDTH="100%" border=0><tr><td class="HelpPluginFilename">', "\n";

  if ( ! defined $userType or $userType == 0 ) {
    print '<font size="+1">You don\'t have enough permissions!</font>', "\n";
  } else {
    print '<iframe src="'. ${HTTPSURL} . $PERFPARSECGI .'" width="100%" height="640" more="" ATTRIBUTES=""></iframe>', "\n";
  }

  print '</td></tr></table>', "\n";
  print '<BR>', "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
