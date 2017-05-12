#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, generateConfig.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;
use File::stat;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.002.003;
use ASNMTAP::Time qw(&get_csvfiledate &get_csvfiletime);

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :SADMIN :DBREADWRITE :DBTABLES $DIFFCOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "generateConfig.pl";
my $prgtext     = "Generate Config";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir = (defined $cgi->param('pagedir')) ? $cgi->param('pagedir') : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset = (defined $cgi->param('pageset')) ? $cgi->param('pageset') : 'admin';   $pageset =~ s/\+/ /g;
my $debug   = (defined $cgi->param('debug'))   ? $cgi->param('debug')   : 'F';
my $action  = (defined $cgi->param('action'))  ? $cgi->param('action')  : 'menuView';
my $Cauto   = (defined $cgi->param('auto'))    ? $cgi->param('auto')    : 0;

my ($Cplugin, $ChelpPluginFilename, $Ctodo);

if ($action eq 'updateView' or $action eq 'update') {
  $Cplugin             = (defined $cgi->param('plugin'))             ? $cgi->param('plugin')             : '';
  $ChelpPluginFilename = (defined $cgi->param('helpPluginFilename')) ? $cgi->param('helpPluginFilename') : '';
  $Ctodo               = (defined $cgi->param('todo'))               ? $cgi->param('todo')               : '';
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $numberCentralServers, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);
my (@matchingAsnmtapCollectorCTscript, @matchingAsnmtapDisplayCTscript, %ASNMTAP_PATH);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Generate Config", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&action=$action&auto=$Cauto";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>action            : $action<br>auto              : $Cauto<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID";

  my ($compareView, $installView, $initializeGenerateView, $matchingWarnings, $countWarnings, $matchingErrors, $countErrors, $matchingArchiveCT, $matchingCollectorCT, $matchingAsnmtapCollectorCTscript, $matchingDisplayCT, $matchingAsnmtapDisplayCTscript, $matchingRsyncMirror);
  $compareView = $installView = $initializeGenerateView = $matchingWarnings = $matchingErrors = $matchingArchiveCT = $matchingCollectorCT = $matchingAsnmtapCollectorCTscript = $matchingDisplayCT = $matchingAsnmtapDisplayCTscript = $matchingRsyncMirror = '';
  $countWarnings = $countErrors = 0;

  if ($action eq 'checkView') {
    $htmlTitle = "Check Configuration";
  } elsif ($action eq 'generateView') {
    $htmlTitle = "Generate Configuration";
  } elsif ($action eq 'compareView') {
    $htmlTitle = "Compare Configurations";
  } elsif ($action eq 'installView') {
    $htmlTitle = ( ( $Cauto == 1 ) ? "Install" : "Dry Run" ) ." Configuration";
  } elsif ($action eq 'install') {
    $htmlTitle = "Configuration Installed";
  } elsif ($action eq 'updateView') {
    $htmlTitle = "Update Configuration";
  } elsif ($action eq 'update') {
    $htmlTitle = "Configuration Updated";
  } else {
    $action    = "menuView";
    $htmlTitle = "Configuration Menu";
  }

  # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  my $onload = ( ( $action =~ /^(check|generate|compare|install)View$/ ) ? "ONLOAD=\"if (document.images) document.Progress.src='".$IMAGESURL."/spacer.gif';\"" : '' );
  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, $onload, 'F', '', $sessionID);
  print "        <br>\n";
  print "<IMG SRC=\"".$IMAGESURL."/gears.gif\" HSPACE=\"0\" VSPACE=\"0\" BORDER=\"0\" NAME=\"Progress\" title=\"Please Wait ...\" alt=\"Please Wait ...\">" if ( $onload );

  $rv  = 1;

  if ($action eq 'checkView' or $action eq 'generateView') {
    # open connection to database and query data
    $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);

    if ($dbh and $rv) {
      my ($serverID, $displayDaemon, $collectorDaemon, $resultsdir, $groupTitle, $pagedirs, $catalogID, $uKey, $test, $interval, $title, $helpPluginFilename, $environment, $trendline, $minute, $hour, $dayOfTheMonth, $monthOfTheYear, $dayOfTheWeek, $argumentsCommon, $argumentsCrontab, $noOffline);
      my ($prevServerID, $prevTypeMonitoring, $prevTypeServers, $prevTypeActiveServer, $prevMasterFQDN, $prevMasterASNMTAP_PATH, $prevMasterRSYNC_PATH, $prevMasterSSH_PATH, $prevSlaveFQDN, $prevSlaveASNMTAP_PATH, $prevSlaveRSYNC_PATH, $prevSlaveSSH_PATH, $prevDisplayDaemon, $prevCollectorDaemon, $prevResultsdir, $prevGroupTitle, $prevPagedir, $prevUniqueKey);
      my ($centralServerID, $centralTypeMonitoring, $centralTypeServers, $centralTypeActiveServer, $centralMasterFQDN, $centralMasterASNMTAP_PATH, $centralMasterRSYNC_PATH, $centralMasterSSH_PATH, $centralMasterDatabaseFQDN, $centralSlaveFQDN, $centralSlaveASNMTAP_PATH, $centralSlaveRSYNC_PATH, $centralSlaveSSH_PATH, $centralSlaveDatabaseFQDN);

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      my ($warning, $error, $count, $sqlTmp, $sthTmp, $actionItem);

      $matchingWarnings .= "<table width=\"100%\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th colspan=\"3\">Warnings:</th></tr>";
      $matchingErrors .= "<table width=\"100%\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th colspan=\"3\">Errors:</th></tr>";

      # displayDaemons <-> views  - - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Display Daemons <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Display Daemon</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLDISPLAYDMNS.displayDaemon, count($SERVERTABLVIEWS.displayDaemon) FROM $SERVERTABLDISPLAYDMNS LEFT JOIN $SERVERTABLVIEWS ON $SERVERTABLDISPLAYDMNS.catalogID = $SERVERTABLVIEWS.catalogID and $SERVERTABLDISPLAYDMNS.displayDaemon = $SERVERTABLVIEWS.displayDaemon where $SERVERTABLDISPLAYDMNS.catalogID = '$CATALOGID' and $SERVERTABLDISPLAYDMNS.activated = 1 group by $SERVERTABLDISPLAYDMNS.displayDaemon";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLDISPLAYDMNS but is not used into $SERVERTABLVIEWS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Display Daemons <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Display Daemon</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLVIEWS.displayDaemon, count($SERVERTABLDISPLAYDMNS.displayDaemon) FROM $SERVERTABLVIEWS LEFT JOIN $SERVERTABLDISPLAYDMNS ON $SERVERTABLVIEWS.catalogID = $SERVERTABLDISPLAYDMNS.catalogID and $SERVERTABLVIEWS.displayDaemon = $SERVERTABLDISPLAYDMNS.displayDaemon where $SERVERTABLVIEWS.catalogID = '$CATALOGID' and $SERVERTABLVIEWS.activated = 1 group by $SERVERTABLVIEWS.displayDaemon";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLVIEWS but don't exist anymore into $SERVERTABLDISPLAYDMNS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # displayGroups <-> views - - - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Display Daemons <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Display Group</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLDISPLAYGRPS.groupTitle, count($SERVERTABLVIEWS.displayGroupID) FROM $SERVERTABLDISPLAYGRPS LEFT JOIN $SERVERTABLVIEWS ON $SERVERTABLDISPLAYGRPS.catalogID = $SERVERTABLVIEWS.catalogID and $SERVERTABLDISPLAYGRPS.displayGroupID = $SERVERTABLVIEWS.displayGroupID where $SERVERTABLDISPLAYGRPS.catalogID = '$CATALOGID' and $SERVERTABLDISPLAYGRPS.activated = 1 group by $SERVERTABLDISPLAYGRPS.displayGroupID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLDISPLAYGRPS but is not used into $SERVERTABLVIEWS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Display Daemons <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Display Group</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLVIEWS.displayGroupID, count($SERVERTABLDISPLAYGRPS.displayGroupID) FROM $SERVERTABLVIEWS LEFT JOIN $SERVERTABLDISPLAYGRPS ON $SERVERTABLVIEWS.catalogID = $SERVERTABLDISPLAYGRPS.catalogID and $SERVERTABLVIEWS.displayGroupID = $SERVERTABLDISPLAYGRPS.displayGroupID where $SERVERTABLVIEWS.catalogID = '$CATALOGID' and $SERVERTABLVIEWS.activated = 1 group by $SERVERTABLVIEWS.displayGroupID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLVIEWS but don't exist anymore into $SERVERTABLDISPLAYGRPS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # collectorDaemons <-> crontabs - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Collector Daemons <-> Crontabs</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Collector Daemon</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLCLLCTRDMNS.collectorDaemon, count($SERVERTABLCRONTABS.collectorDaemon) FROM $SERVERTABLCLLCTRDMNS LEFT JOIN $SERVERTABLCRONTABS ON $SERVERTABLCLLCTRDMNS.catalogID = $SERVERTABLCRONTABS.catalogID and $SERVERTABLCLLCTRDMNS.collectorDaemon = $SERVERTABLCRONTABS.collectorDaemon where $SERVERTABLCLLCTRDMNS.catalogID = '$CATALOGID' and $SERVERTABLCLLCTRDMNS.activated = 1 group by $SERVERTABLCLLCTRDMNS.collectorDaemon";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLCLLCTRDMNS but is not used into $SERVERTABLCRONTABS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Collector Daemons <-> Crontabs</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Collector Daemon</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLCRONTABS.collectorDaemon, count($SERVERTABLCLLCTRDMNS.collectorDaemon) FROM $SERVERTABLCRONTABS LEFT JOIN $SERVERTABLCLLCTRDMNS ON $SERVERTABLCRONTABS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLCRONTABS.collectorDaemon = $SERVERTABLCLLCTRDMNS.collectorDaemon where $SERVERTABLCRONTABS.catalogID = '$CATALOGID' and $SERVERTABLCRONTABS.activated = 1 group by $SERVERTABLCRONTABS.collectorDaemon";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLCRONTABS but don't exist anymore into $SERVERTABLCLLCTRDMNS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # pagedirs <-> displayDaemons - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Display Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLPAGEDIRS.pagedir, count($SERVERTABLDISPLAYDMNS.pagedir) FROM $SERVERTABLPAGEDIRS LEFT JOIN $SERVERTABLDISPLAYDMNS ON $SERVERTABLPAGEDIRS.catalogID = $SERVERTABLDISPLAYDMNS.catalogID and $SERVERTABLPAGEDIRS.pagedir = $SERVERTABLDISPLAYDMNS.pagedir where $SERVERTABLPAGEDIRS.catalogID = '$CATALOGID' and $SERVERTABLPAGEDIRS.activated = 1 group by $SERVERTABLPAGEDIRS.pagedir";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPAGEDIRS but is not used into $SERVERTABLDISPLAYDMNS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Display Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLDISPLAYDMNS.pagedir, count($SERVERTABLPAGEDIRS.pagedir) FROM $SERVERTABLDISPLAYDMNS LEFT JOIN $SERVERTABLPAGEDIRS ON $SERVERTABLDISPLAYDMNS.catalogID = $SERVERTABLPAGEDIRS.catalogID and $SERVERTABLDISPLAYDMNS.pagedir = $SERVERTABLPAGEDIRS.pagedir where $SERVERTABLDISPLAYDMNS.catalogID = '$CATALOGID' and $SERVERTABLDISPLAYDMNS.activated = 1 group by $SERVERTABLDISPLAYDMNS.pagedir";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLDISPLAYDMNS but don't exist anymore into $SERVERTABLPAGEDIRS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # pagedirs <-> plugins  - - - - - - - - - - - - - - - - - - - - - -
      $sqlTmp = "drop temporary table if exists tmp$SERVERTABLPLUGINS";
      $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);

        $sqlTmp = "create temporary table `tmp$SERVERTABLPLUGINS`(`catalogID` varchar(5) NOT NULL default '$CATALOGID', `pagedir` varchar(11) default '') TYPE=InnoDB";
        $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);

        if ( $rv ) {
          $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

          $sql = "SELECT $SERVERTABLPLUGINS.pagedir FROM $SERVERTABLPLUGINS where catalogID = '$CATALOGID'";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$pagedirs ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

          if ( $rv ) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                chop ($pagedirs);
                $pagedirs = substr($pagedirs, 1);
                my @pagedirs = split (/\//, $pagedirs);

                foreach my $pagedirTmp (@pagedirs) {
                  $sqlTmp = "insert into tmp$SERVERTABLPLUGINS set catalogID = '$CATALOGID', pagedir = '$pagedirTmp'";
                  $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
                  $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
                  $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          }

          $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Plugins</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
          $sql = "SELECT $SERVERTABLPAGEDIRS.pagedir, count(tmp$SERVERTABLPLUGINS.pagedir) FROM $SERVERTABLPAGEDIRS LEFT JOIN tmp$SERVERTABLPLUGINS ON $SERVERTABLPAGEDIRS.catalogID = tmp$SERVERTABLPLUGINS.catalogID and $SERVERTABLPAGEDIRS.pagedir = tmp$SERVERTABLPLUGINS.pagedir where $SERVERTABLPAGEDIRS.catalogID = '$CATALOGID' and $SERVERTABLPAGEDIRS.activated = 1 group by $SERVERTABLPAGEDIRS.pagedir";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

          if ($rv) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                if ($count == 0) {
                  $countWarnings++;
                  $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPAGEDIRS but is not used into $SERVERTABLPLUGINS</td><td>&nbsp;</td></tr>";
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          }

          $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Plugins</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
          $sql = "SELECT tmp$SERVERTABLPLUGINS.pagedir, count($SERVERTABLPAGEDIRS.pagedir) FROM tmp$SERVERTABLPLUGINS LEFT JOIN $SERVERTABLPAGEDIRS ON tmp$SERVERTABLPLUGINS.catalogID = $SERVERTABLPAGEDIRS.catalogID and tmp$SERVERTABLPLUGINS.pagedir = $SERVERTABLPAGEDIRS.pagedir where $SERVERTABLPAGEDIRS.catalogID = '$CATALOGID' and $SERVERTABLPAGEDIRS.activated = 1 group by tmp$SERVERTABLPLUGINS.pagedir";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

          if ($rv) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                if ($count == 0) {
                  $countErrors++;
                  $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLPLUGINS but don't exist anymore into $SERVERTABLPAGEDIRS</td><td>&nbsp;</td></tr>";
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          }

          $sqlTmp = "drop temporary table tmp$SERVERTABLPLUGINS";
          $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
          $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
        }
      }

      # pagedirs <-> users  - - - - - - - - - - - - - - - - - - - - - - -
      $sqlTmp = "drop temporary table if exists tmp$SERVERTABLUSERS";
      $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);

        $sqlTmp = "create temporary table `tmp$SERVERTABLUSERS`(`catalogID` varchar(5) NOT NULL default '$CATALOGID', `pagedir` varchar(11) default '') TYPE=InnoDB";
        $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);

        if ( $rv ) {
          $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

          $sql = "SELECT $SERVERTABLUSERS.pagedir FROM $SERVERTABLUSERS where catalogID = '$CATALOGID'";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$pagedirs ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

          if ( $rv ) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                chop ($pagedirs);
                $pagedirs = substr($pagedirs, 1);
                my @pagedirs = split (/\//, $pagedirs);

                foreach my $pagedirTmp (@pagedirs) {
                  $sqlTmp = "insert into tmp$SERVERTABLUSERS set catalogID = '$CATALOGID', pagedir = '$pagedirTmp'";
                  $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
                  $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
                  $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          }

          $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Users</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
          $sql = "SELECT $SERVERTABLPAGEDIRS.pagedir, count(tmp$SERVERTABLUSERS.pagedir) FROM $SERVERTABLPAGEDIRS LEFT JOIN tmp$SERVERTABLUSERS ON $SERVERTABLPAGEDIRS.catalogID = tmp$SERVERTABLUSERS.catalogID and $SERVERTABLPAGEDIRS.pagedir = tmp$SERVERTABLUSERS.pagedir where $SERVERTABLPAGEDIRS.catalogID = '$CATALOGID' and $SERVERTABLPAGEDIRS.activated = 1 group by $SERVERTABLPAGEDIRS.pagedir";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

          if ($rv) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                if ($count == 0) {
                  $countWarnings++;
                  $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPAGEDIRS but is not used into $SERVERTABLUSERS</td><td>&nbsp;</td></tr>";
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          }

          $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Pagedirs <-> Users</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Pagedir</td><td>Message</td><td align=\"center\">Action</td></tr>";
          $sql = "SELECT tmp$SERVERTABLUSERS.pagedir, count($SERVERTABLPAGEDIRS.pagedir) FROM tmp$SERVERTABLUSERS LEFT JOIN $SERVERTABLPAGEDIRS ON tmp$SERVERTABLUSERS.catalogID = $SERVERTABLPAGEDIRS.catalogID and tmp$SERVERTABLUSERS.pagedir = $SERVERTABLPAGEDIRS.pagedir where $SERVERTABLPAGEDIRS.catalogID = '$CATALOGID' and $SERVERTABLPAGEDIRS.activated = 1 group by tmp$SERVERTABLUSERS.pagedir";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

          if ($rv) {
            if ( $sth->rows ) {
              while( $sth->fetch() ) {
                if ($count == 0) {
                  $countErrors++;
                  $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLUSERS but don't exist anymore into $SERVERTABLPAGEDIRS</td><td>&nbsp;</td></tr>";
                }
              }
            }

            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          }

          $sqlTmp = "drop temporary table tmp$SERVERTABLUSERS";
          $sthTmp = $dbh->prepare( $sqlTmp ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          $sthTmp->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
          $sthTmp->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlTmp", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
        }
      }

      # plugins <-> comments  - - - - - - - - - - - - - - - - - - - - - -
      # $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Comments</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      # $sql = "SELECT $SERVERTABLPLUGINS.uKey, count($SERVERTABLCOMMENTS.uKey) FROM $SERVERTABLPLUGINS LEFT JOIN $SERVERTABLCOMMENTS ON $SERVERTABLPLUGINS.catalogID = $SERVERTABLCOMMENTS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLCOMMENTS.uKey where $SERVERTABLPLUGINS.catalogID = '$CATALOGID' and $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.production = 1 group by $SERVERTABLPLUGINS.uKey";
      # $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      # $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      # $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      # if ($rv) {
      #   if ( $sth->rows ) {
      #     while( $sth->fetch() ) {
      #     if ($count == 0) {
      #       $countWarnings++;
      #       $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPLUGINS but is not used into $SERVERTABLCOMMENTS</td><td>&nbsp;</td></tr>";
      #       }
      #     }
      #   }
      #
      #   $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      # }

      # $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Comments</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      # $sql = "SELECT $SERVERTABLCOMMENTS.uKey, count($SERVERTABLPLUGINS.uKey) FROM $SERVERTABLCOMMENTS LEFT JOIN $SERVERTABLPLUGINS ON $SERVERTABLCOMMENTS.catalogID = $SERVERTABLPLUGINS.catalogID and $SERVERTABLCOMMENTS.uKey = $SERVERTABLPLUGINS.uKey where $SERVERTABLCOMMENTS.catalogID = '$CATALOGID' and $SERVERTABLCOMMENTS.activated = 1 group by $SERVERTABLCOMMENTS.uKey";
      # $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      # $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      # $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      # if ($rv) {
      #   if ( $sth->rows ) {
      #     while( $sth->fetch() ) {
      #       if ($count == 0) {
      #         $countErrors++;
      #         $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLCOMMENTS but don't exist anymore into $SERVERTABLPLUGINS</td><td>&nbsp;</td></tr>";
      #       }
      #     }
      #   }
      #
      #   $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      # }

      # plugins <-> crontabs  - - - - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Crontabs</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLPLUGINS.uKey, count($SERVERTABLCRONTABS.uKey) FROM $SERVERTABLPLUGINS LEFT JOIN $SERVERTABLCRONTABS ON $SERVERTABLPLUGINS.uKey = $SERVERTABLCRONTABS.uKey where $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.production = 1 group by $SERVERTABLPLUGINS.uKey";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPLUGINS but is not used into $SERVERTABLCRONTABS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Crontabs</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLCRONTABS.uKey, count($SERVERTABLPLUGINS.uKey) FROM $SERVERTABLCRONTABS LEFT JOIN $SERVERTABLPLUGINS ON  $SERVERTABLCRONTABS.catalogID = $SERVERTABLPLUGINS.catalogID and $SERVERTABLCRONTABS.uKey = $SERVERTABLPLUGINS.uKey where $SERVERTABLCRONTABS.catalogID = '$CATALOGID' and $SERVERTABLCRONTABS.activated = 1 group by $SERVERTABLCRONTABS.uKey";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLCRONTABS but don't exist anymore into $SERVERTABLPLUGINS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # plugins <-> views - - - - - - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLPLUGINS.uKey, count($SERVERTABLVIEWS.uKey) FROM $SERVERTABLPLUGINS LEFT JOIN $SERVERTABLVIEWS ON $SERVERTABLPLUGINS.catalogID = $SERVERTABLVIEWS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLVIEWS.uKey where $SERVERTABLPLUGINS.catalogID = '$CATALOGID' and $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.production = 1 group by $SERVERTABLPLUGINS.uKey";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLPLUGINS but is not used into $SERVERTABLVIEWS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Views</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLVIEWS.uKey, count($SERVERTABLPLUGINS.uKey) FROM $SERVERTABLVIEWS LEFT JOIN $SERVERTABLPLUGINS ON $SERVERTABLVIEWS.catalogID = $SERVERTABLPLUGINS.catalogID and  $SERVERTABLVIEWS.uKey = $SERVERTABLPLUGINS.uKey where $SERVERTABLVIEWS.catalogID = '$CATALOGID' and $SERVERTABLVIEWS.activated = 1 group by $SERVERTABLVIEWS.uKey";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLVIEWS but don't exist anymore into $SERVERTABLPLUGINS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # resultsdir <-> plugins  - - - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Resultsdir <-> Plugins</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Resultsdir</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLRESULTSDIR.resultsdir, count($SERVERTABLPLUGINS.resultsdir) FROM $SERVERTABLRESULTSDIR LEFT JOIN $SERVERTABLPLUGINS ON  $SERVERTABLRESULTSDIR.catalogID = $SERVERTABLPLUGINS.catalogID and $SERVERTABLRESULTSDIR.resultsdir = $SERVERTABLPLUGINS.resultsdir where $SERVERTABLPLUGINS.catalogID = '$CATALOGID' and $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.production = 1 group by $SERVERTABLRESULTSDIR.resultsdir";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLRESULTSDIR but is not used into $SERVERTABLPLUGINS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Resultsdir <-> Plugins</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Resultsdir</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLPLUGINS.resultsdir, count($SERVERTABLRESULTSDIR.resultsdir) FROM $SERVERTABLPLUGINS LEFT JOIN $SERVERTABLRESULTSDIR ON $SERVERTABLPLUGINS.catalogID = $SERVERTABLRESULTSDIR.catalogID and $SERVERTABLPLUGINS.resultsdir = $SERVERTABLRESULTSDIR.resultsdir where $SERVERTABLPLUGINS.catalogID = '$CATALOGID' and $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.production = 1 group by $SERVERTABLPLUGINS.resultsdir";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLPLUGINS but don't exist anymore into $SERVERTABLRESULTSDIR</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # servers <-> collectorDaemons  - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Servers <-> Collector Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Server ID</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLSERVERS.serverID, count($SERVERTABLCLLCTRDMNS.serverID) FROM $SERVERTABLSERVERS LEFT JOIN $SERVERTABLCLLCTRDMNS ON $SERVERTABLSERVERS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLSERVERS.serverID = $SERVERTABLCLLCTRDMNS.serverID where $SERVERTABLSERVERS.catalogID = '$CATALOGID' and $SERVERTABLSERVERS.activated = 1 group by $SERVERTABLSERVERS.serverID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLSERVERS but is not used into $SERVERTABLCLLCTRDMNS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Servers <-> Collector Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Server ID</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLCLLCTRDMNS.serverID, count($SERVERTABLSERVERS.serverID) FROM $SERVERTABLCLLCTRDMNS LEFT JOIN $SERVERTABLSERVERS ON $SERVERTABLCLLCTRDMNS.catalogID = $SERVERTABLSERVERS.catalogID and $SERVERTABLCLLCTRDMNS.serverID = $SERVERTABLSERVERS.serverID where $SERVERTABLCLLCTRDMNS.catalogID = '$CATALOGID' and $SERVERTABLCLLCTRDMNS.activated = 1 group by $SERVERTABLCLLCTRDMNS.serverID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLCLLCTRDMNS but don't exist anymore into $SERVERTABLSERVERS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # servers <-> displayDaemons  - - - - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Servers <-> Display Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Server ID</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLSERVERS.serverID, count($SERVERTABLDISPLAYDMNS.serverID) FROM $SERVERTABLSERVERS LEFT JOIN $SERVERTABLDISPLAYDMNS ON $SERVERTABLSERVERS.catalogID = $SERVERTABLDISPLAYDMNS.catalogID and $SERVERTABLSERVERS.serverID = $SERVERTABLDISPLAYDMNS.serverID where $SERVERTABLSERVERS.catalogID = '$CATALOGID' and $SERVERTABLSERVERS.activated = 1 group by $SERVERTABLSERVERS.serverID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countWarnings++;
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>exists into $SERVERTABLSERVERS but is not used into $SERVERTABLDISPLAYDMNS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Servers <-> Display Daemons</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Server ID</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT $SERVERTABLDISPLAYDMNS.serverID, count($SERVERTABLSERVERS.serverID) FROM $SERVERTABLDISPLAYDMNS LEFT JOIN $SERVERTABLSERVERS ON $SERVERTABLDISPLAYDMNS.catalogID = $SERVERTABLSERVERS.catalogID and $SERVERTABLDISPLAYDMNS.serverID = $SERVERTABLSERVERS.serverID where $SERVERTABLDISPLAYDMNS.catalogID = '$CATALOGID' and $SERVERTABLDISPLAYDMNS.activated = 1 group by $SERVERTABLDISPLAYDMNS.serverID";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$error, \$count) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if ($count == 0) {
              $countErrors++;
              $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$error</td><td>still used into $SERVERTABLDISPLAYDMNS but don't exist anymore into $SERVERTABLSERVERS</td><td>&nbsp;</td></tr>";
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # servers <-> servers - - - - - - - - - - - - - - - - - - - - - - -
      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Servers <-> Servers</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Central Monitoring Servers</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT count(typeMonitoring) FROM $SERVERTABLSERVERS where catalogID = '$CATALOGID' and typeMonitoring = 0 and activated = 1 group by typeMonitoring";
      ($rv, $numberCentralServers) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      unless ( defined $numberCentralServers ) {
        $countErrors++;
        $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>0</td><td>there is no activated central monitoring server</td><td>&nbsp;</td></tr>";
      } elsif ( $numberCentralServers != 1 ) {
        $countErrors++;
        $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$numberCentralServers</td><td>there can be only one activated central monitoring server</td><td>&nbsp;</td></tr>";
      } else {
        $sql = "SELECT serverID, typeMonitoring, typeServers, typeActiveServer, masterFQDN, masterASNMTAP_PATH, masterRSYNC_PATH, masterSSH_PATH, masterDatabaseFQDN, slaveFQDN, slaveASNMTAP_PATH, slaveRSYNC_PATH, slaveSSH_PATH, slaveDatabaseFQDN FROM $SERVERTABLSERVERS where catalogID = '$CATALOGID' and typeMonitoring = 0 and activated = 1";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

        if ($rv) {
          if ( $sth->rows ) { ($centralServerID, $centralTypeMonitoring, $centralTypeServers, $centralTypeActiveServer, $centralMasterFQDN, $centralMasterASNMTAP_PATH, $centralMasterRSYNC_PATH, $centralMasterSSH_PATH, $centralMasterDatabaseFQDN, $centralSlaveFQDN, $centralSlaveASNMTAP_PATH, $centralSlaveRSYNC_PATH, $centralSlaveSSH_PATH, $centralSlaveDatabaseFQDN) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID); }
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
        }

        $centralSlaveDatabaseFQDN = $centralMasterDatabaseFQDN unless ( $centralTypeServers );
      }

      # catalog <-> catalog - - - - - - - - - - - - - - - - - - - - - - -
      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Catalog <-> Catalog</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Central Monitoring Servers into the Catalog</td><td>Message</td><td align=\"center\">Action</td></tr>";

      my ($numberCatalogCentralServers);

      $sql = "SELECT count(catalogType) FROM $SERVERTABLCATALOG where catalogID = '$CATALOGID' and catalogType = 'Central' and activated = 1 group by catalogType";
      ($rv, $numberCatalogCentralServers) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      unless ( defined $numberCatalogCentralServers ) {
        $countErrors++;
        $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>0</td><td>there is no activated central monitoring server into the catalog with catalogID '$CATALOGID'</td><td>&nbsp;</td></tr>";
      } else {
        $sql = "SELECT count(catalogType) FROM $SERVERTABLCATALOG where catalogType = 'Central' and activated = 1 group by catalogType";
        ($rv, $numberCatalogCentralServers) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	    if ( defined $numberCatalogCentralServers and $numberCatalogCentralServers != 1 ) {
          $countErrors++;
          $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$numberCatalogCentralServers</td><td>there can be only one activated central monitoring server into the catalog</td><td>&nbsp;</td></tr>";
        }
      }

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{TABLE}\"><td align=\"center\" colspan=\"3\">&nbsp;</td></tr>";

      # plugins uploaded <-> plugins configurated - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins Uploaded <-> Plugins Configurated</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Plugin</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT DISTINCT test FROM $SERVERTABLPLUGINS where catalogID = '$CATALOGID' and activated = 1";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$test) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          my @plugins = glob("$PLUGINPATH/*.pl");

          while( $sth->fetch() ) {
            my $teller = 0;

            foreach my $plugin (@plugins) {
              if ( defined $plugin and defined $test and $plugin eq "$PLUGINPATH/$test" ) {
                $plugins[$teller] = undef;
                last;
              }

              $teller++
            }
          }

          foreach my $pluginPath (@plugins) {
            if (defined $pluginPath) {
		      (undef, my $plugin) = split (/^$PLUGINPATH\//, $pluginPath);
              $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;plugin=$plugin&amp;todo=delete\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{delete}\" title=\"Delete Plugin\" alt=\"Delete Plugin\" border=\"0\"></a>";
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$plugin</td><td>plugin uploaded without plugin configuration</td><td align=\"center\">$actionItem</td></tr>";
              $countWarnings++;
			}
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # plugins configurated <-> plugins uploaded - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins Configurated <-> Plugins Uploaded</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Plugin</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins Configurated <-> Plugins Uploaded</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Plugin</td><td>Message</td><td align=\"center\">Action</td></tr>";

      $sql = "SELECT DISTINCT test FROM $SERVERTABLPLUGINS where catalogID = '$CATALOGID' and activated = 1";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$test) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if (! -e "$PLUGINPATH/$test") {
              $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;plugin=$test&amp;todo=edit\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Plugin\" alt=\"Edit Plugin\" border=\"0\"></a>";
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$test</td><td>plugin configuration without plugin uploaded</td><td align=\"center\">$actionItem</td></tr>";
              $countWarnings++;
            } else {
               my $sb = stat("$PLUGINPATH/$test");

               unless ( $sb->mode == 33261 or $sb->mode == 33256 ) { # 0755 = 33261 & 0750 = 33256 
                $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;plugin=$test&amp;todo=maintenance\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{maintenance}\" title=\"Rights Plugin\" alt=\"Rights Plugin\" border=\"0\"></a>";
                $matchingErrors .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$test</td><td>plugin configuration with plugin uploaded but without wanted excecution rights</td><td align=\"center\">$actionItem</td></tr>";
                $countErrors++;
              }
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{TABLE}\"><td align=\"center\" colspan=\"3\">&nbsp;</td></tr>";

      # help plugin filenames <-> plugin  - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Help Plugin Filenames <-> Plugin</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Help Plugin Filename</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT DISTINCT helpPluginFilename FROM $SERVERTABLPLUGINS WHERE catalogID = '$CATALOGID' and helpPluginFilename != '<NIHIL>'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$helpPluginFilename) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          my @helpPluginFilenames = glob("$PDPHELPPATH/*");

          while( $sth->fetch() ) {
            my $teller = 0;

            foreach my $helpPluginPathFilename (@helpPluginFilenames) {
              if ( $helpPluginPathFilename eq "$PDPHELPPATH/$helpPluginFilename" ) {
                $helpPluginFilenames[$teller] = undef;
                last;
              }

              $teller++
            }
          }

          foreach my $helpPluginPathFilename (@helpPluginFilenames) {
            if (defined $helpPluginPathFilename) {
		      (undef, $helpPluginFilename) = split (/^$PDPHELPPATH\//, $helpPluginPathFilename);
              $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;helpPluginFilename=$helpPluginFilename&amp;todo=delete\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{delete}\" title=\"Delete Help Plugin Filename\" alt=\"Delete Help Plugin Filename\" border=\"0\"></a>";
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$helpPluginFilename</td><td>help plugin filename without plugin reference</td><td align=\"center\">$actionItem</td></tr>";
              $countWarnings++;
			}
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # plugins <-> help plugin filename  - - - - - - - - - - - - - - - -
      $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td align=\"center\" colspan=\"3\">Plugins <-> Help Plugin Filename</td></tr><tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>Unique Key</td><td>Message</td><td align=\"center\">Action</td></tr>";
      $sql = "SELECT uKey, LTRIM(SUBSTRING_INDEX(title, ']', -1)) as shortTitle, helpPluginFilename FROM $SERVERTABLPLUGINS WHERE catalogID = '$CATALOGID' and activated = 1 order by shortTitle";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$warning, \$title, \$helpPluginFilename) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ( $rv ) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            if (! defined $helpPluginFilename or $helpPluginFilename eq '<NIHIL>') {
              $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;helpPluginFilename=<NIHIL>&amp;todo=duplicate\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{duplicate}\" title=\"Add Help Plugin Filename\" alt=\"Add Help Plugin Filename\" border=\"0\"></a>";
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>'$title' plugin without help plugin filename defined</td><td align=\"center\">$actionItem</td></tr>";
              $countWarnings++;
            } elsif ($helpPluginFilename !~ /^http(s)?\:\/\// and ! -e "$PDPHELPPATH/$helpPluginFilename") {
              $actionItem = "<a href=\"$urlWithAccessParameters&amp;action=updateView&amp;helpPluginFilename=$helpPluginFilename&amp;todo=edit\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Help Plugin Filename\" alt=\"Edit Help Plugin Filename\" border=\"0\"></a>";
              $matchingWarnings .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$warning</td><td>'$title' plugin with missing help plugin filename '<b>$helpPluginFilename</b>'</td><td align=\"center\">$actionItem</td></tr>";
              $countWarnings++;
            }
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      }

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      $matchingErrors .= "</table>\n";
      $matchingWarnings .= "</table>\n";

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      if ($action eq 'generateView') {
        my ($rvOpen, $typeMonitoringCharDorC, $typeMonitoring, $typeServers, $typeActiveServer, $masterFQDN, $masterASNMTAP_PATH, $masterRSYNC_PATH, $masterSSH_PATH, $slaveFQDN, $slaveASNMTAP_PATH, $slaveRSYNC_PATH, $slaveSSH_PATH, $mode, $dumphttp, $status, $loop, $trigger, $displayTime, $lockMySQL, $debugDaemon, $debugAllScreen, $debugAllFile, $debugNokFile);

        $initializeGenerateView .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><th>Initialize Generate Configs</th></tr>";

        $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp", $debug);
        $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR", $debug);
        $initializeGenerateView .= system_call ("rm -rf", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated", $debug);
        $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR/generated", $debug);

        unless (-d "$APPLICATIONPATH/tmp/$CONFIGDIR/installed") {
          $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR/installed", $debug);
        }

        if ( defined $numberCentralServers and $numberCentralServers == 1) {
          $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CM-$centralTypeActiveServer-$centralMasterFQDN", $debug);
          $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CM-$centralTypeActiveServer-$centralMasterFQDN/etc", $debug);
          $initializeGenerateView .= system_call ("mkdir",  "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CM-$centralTypeActiveServer-$centralMasterFQDN/master", $debug);

		  if ( $centralTypeServers ) {
            $initializeGenerateView .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CS-$centralTypeActiveServer-$centralSlaveFQDN", $debug);
            $initializeGenerateView .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CS-$centralTypeActiveServer-$centralSlaveFQDN/etc", $debug);
            $initializeGenerateView .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CS-$centralTypeActiveServer-$centralSlaveFQDN/master", $debug);
          }
        }

        $initializeGenerateView .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/\" target=\"_blank\">Browse directory list with all config files</a></td></tr>\n      </table>";

        my $configDateTime = get_csvfiledate .' '. get_csvfiletime;
        $rvOpen = 0;

        # ArchiveCT - - - - - - - - - - - - - - - - - - - - - - - - - - -
        $sql = "select distinct $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.typeActiveServer, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.masterASNMTAP_PATH, $SERVERTABLSERVERS.masterRSYNC_PATH, $SERVERTABLSERVERS.masterSSH_PATH, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLSERVERS.slaveASNMTAP_PATH, $SERVERTABLSERVERS.slaveRSYNC_PATH, $SERVERTABLSERVERS.slaveSSH_PATH, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLCRONTABS.catalogID, $SERVERTABLCRONTABS.uKey, $SERVERTABLPLUGINS.test from $SERVERTABLSERVERS, $SERVERTABLCLLCTRDMNS, $SERVERTABLCRONTABS, $SERVERTABLPLUGINS where $SERVERTABLSERVERS.catalogID = '$CATALOGID' and $SERVERTABLSERVERS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLSERVERS.serverID = $SERVERTABLCLLCTRDMNS.serverID and $SERVERTABLSERVERS.activated = 1 and $SERVERTABLCLLCTRDMNS.catalogID = $SERVERTABLCRONTABS.catalogID and $SERVERTABLCLLCTRDMNS.collectorDaemon = $SERVERTABLCRONTABS.collectorDaemon and $SERVERTABLCLLCTRDMNS.activated = 1 and $SERVERTABLCRONTABS.catalogID = $SERVERTABLPLUGINS.catalogID and $SERVERTABLCRONTABS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLCRONTABS.activated = 1 and $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.production = 1 order by $SERVERTABLSERVERS.serverID, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLCRONTABS.uKey";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$typeActiveServer, \$masterFQDN, \$masterASNMTAP_PATH, \$masterRSYNC_PATH, \$masterSSH_PATH, \$slaveFQDN, \$slaveASNMTAP_PATH, \$slaveRSYNC_PATH, \$slaveSSH_PATH, \$collectorDaemon, \$resultsdir, \$catalogID, \$uKey, \$test ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

        if ( $rv ) {
          $matchingArchiveCT .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

          if ( $sth->rows ) {
            $prevTypeServers = $prevTypeActiveServer = 0;
            $prevServerID = $prevMasterFQDN = $prevMasterASNMTAP_PATH = $prevMasterRSYNC_PATH = $prevMasterSSH_PATH = $prevSlaveFQDN = $prevSlaveASNMTAP_PATH = $prevSlaveRSYNC_PATH = $prevSlaveSSH_PATH = $prevResultsdir = '';

            while( $sth->fetch() ) {
              if ($prevServerID ne $serverID) {
                if ($prevServerID ne '') {
                  if ($rvOpen) {
                    print ArchiveCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde ArchiveCT - $prevServerID\n";
                    close(ArchiveCT);
                    $rvOpen = 0;

                    if ($prevTypeServers) {
                      $typeMonitoringCharDorC = ($prevTypeMonitoring) ? 'D' : 'C';
                      $matchingArchiveCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$prevTypeActiveServer-$prevMasterFQDN/etc/ArchiveCT $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$prevTypeActiveServer-$prevSlaveFQDN/etc/ArchiveCT", $debug);
                    }

                    $matchingArchiveCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>ArchiveCT - $prevServerID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
                  }
                }

                $matchingArchiveCT .= "\n        <tr><th>ArchiveCT - $serverID</th></tr>";

                $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
                $matchingArchiveCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN", $debug);
                $matchingArchiveCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc", $debug);

                if ($typeServers) {
                  $matchingArchiveCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN", $debug);
                  $matchingArchiveCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/etc", $debug);
                }

                $rvOpen = open(ArchiveCT, ">$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc/ArchiveCT");

                if ($rvOpen) {
                  $matchingArchiveCT .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc/ArchiveCT\" target=\"_blank\">ArchiveCT</a></td></tr>";
                  print ArchiveCT "# ArchiveCT - $serverID, generated on $configDateTime, ASNMTAP v$version or higher\n#\n# <resultsdir>#[<catalogID>_]<uniqueKey>#check_nnn[|[<catalogID>_]<uniqueKey>#check_mmm]\n#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n#\n_ASNMTAP#_ASNMTAP#collectorDaemonSchedulingReports.pl\n";
                }
              }

              if ($rvOpen) {
                print ArchiveCT "#\n" if ( $prevResultsdir ne $resultsdir );
                my $catalogID_uKey = ( ( $catalogID eq 'CID' ) ? '' : $catalogID .'_' ) . $uKey;
                print ArchiveCT "$resultsdir#$catalogID_uKey#$test\n";
              }

              $prevServerID           = $serverID;
              $prevTypeMonitoring     = $typeMonitoring;
              $prevTypeServers        = $typeServers;
              $prevTypeActiveServer   = $typeActiveServer;
              $prevMasterFQDN         = $masterFQDN;
              $prevMasterASNMTAP_PATH = $masterASNMTAP_PATH;
              $prevMasterRSYNC_PATH   = $masterRSYNC_PATH;
              $prevMasterSSH_PATH     = $masterSSH_PATH;
              $prevSlaveFQDN          = $slaveFQDN;
              $prevSlaveASNMTAP_PATH  = $slaveASNMTAP_PATH;
              $prevSlaveRSYNC_PATH    = $slaveRSYNC_PATH;
              $prevSlaveSSH_PATH      = $slaveSSH_PATH;
              $prevResultsdir         = $resultsdir;
            }

            if ($rvOpen) {
              print ArchiveCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde ArchiveCT - $serverID\n";
              close(ArchiveCT);
              $rvOpen = 0;

              if ($typeServers) {
                $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
                $matchingArchiveCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc/ArchiveCT $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/etc/ArchiveCT", $debug);
              }

              $matchingArchiveCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>ArchiveCT - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
            }
          } else {
            $matchingArchiveCT .= "\n        <tr><td>No records found for any ArchiveCT</td></tr>";
          }

          $matchingArchiveCT .= "\n      </table>";
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        }

        # DisplayCT - - - - - - - - - - - - - - - - - - - - - - - - - - -
        $sql = "select distinct $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.typeActiveServer, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.masterASNMTAP_PATH, $SERVERTABLSERVERS.masterRSYNC_PATH, $SERVERTABLSERVERS.masterSSH_PATH, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLSERVERS.slaveASNMTAP_PATH, $SERVERTABLSERVERS.slaveRSYNC_PATH, $SERVERTABLSERVERS.slaveSSH_PATH from $SERVERTABLSERVERS where $SERVERTABLSERVERS.catalogID = '$CATALOGID' and $SERVERTABLSERVERS.typeMonitoring = 0";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$typeActiveServer, \$masterFQDN, \$masterASNMTAP_PATH, \$masterRSYNC_PATH, \$masterSSH_PATH, \$slaveFQDN, \$slaveASNMTAP_PATH, \$slaveRSYNC_PATH, \$slaveSSH_PATH ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

        if ( $rv ) {
          $sth->fetch();
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);

          $sql = "select distinct $SERVERTABLDISPLAYDMNS.displayDaemon, $SERVERTABLDISPLAYDMNS.pagedir, $SERVERTABLDISPLAYDMNS.loop, $SERVERTABLDISPLAYDMNS.trigger, $SERVERTABLDISPLAYDMNS.displayTime, $SERVERTABLDISPLAYDMNS.lockMySQL, $SERVERTABLDISPLAYDMNS.debugDaemon, $SERVERTABLPLUGINS.step, $SERVERTABLDISPLAYGRPS.groupTitle, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLVIEWS.catalogID, $SERVERTABLVIEWS.uKey, concat( $SERVERTABLPLUGINS.title, ' {', $SERVERTABLCLLCTRDMNS.serverID, '}'), $SERVERTABLPLUGINS.test, $SERVERTABLPLUGINS.environment, $SERVERTABLPLUGINS.trendline, $SERVERTABLPLUGINS.helpPluginFilename from $SERVERTABLSERVERS, $SERVERTABLDISPLAYDMNS, $SERVERTABLVIEWS, $SERVERTABLPLUGINS, $SERVERTABLDISPLAYGRPS, $SERVERTABLCLLCTRDMNS, $SERVERTABLCRONTABS, $SERVERTABLCATALOG ";
          $sql .= "where $SERVERTABLSERVERS.catalogID = $SERVERTABLCATALOG.catalogID and $SERVERTABLCATALOG.activated = 1 and $SERVERTABLSERVERS.catalogID = $SERVERTABLDISPLAYDMNS.catalogID and $SERVERTABLSERVERS.serverID = $SERVERTABLDISPLAYDMNS.serverID and $SERVERTABLSERVERS.activated = 1 and $SERVERTABLDISPLAYDMNS.catalogID = $SERVERTABLVIEWS.catalogID and $SERVERTABLDISPLAYDMNS.displayDaemon = $SERVERTABLVIEWS.displayDaemon and $SERVERTABLDISPLAYDMNS.activated = 1 and $SERVERTABLVIEWS.catalogID = $SERVERTABLPLUGINS.catalogID and $SERVERTABLVIEWS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLVIEWS.activated = 1 and $SERVERTABLVIEWS.catalogID = $SERVERTABLDISPLAYGRPS.catalogID and $SERVERTABLVIEWS.displayGroupID = $SERVERTABLDISPLAYGRPS.displayGroupID and $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.production = 1 and $SERVERTABLDISPLAYGRPS.activated = 1 and $SERVERTABLPLUGINS.catalogID = $SERVERTABLCRONTABS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLCRONTABS.uKey and $SERVERTABLCRONTABS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLCRONTABS.collectorDaemon = $SERVERTABLCLLCTRDMNS.collectorDaemon and $SERVERTABLCRONTABS.activated = 1 and $SERVERTABLCLLCTRDMNS.activated = 1 order by $SERVERTABLDISPLAYDMNS.displayDaemon, $SERVERTABLDISPLAYGRPS.groupTitle, $SERVERTABLPLUGINS.title, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLVIEWS.uKey";
          $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$displayDaemon, \$pagedirs, \$loop, \$trigger, \$displayTime, \$lockMySQL, \$debugDaemon, \$interval, \$groupTitle, \$resultsdir, \$catalogID, \$uKey, \$title, \$test, \$environment, \$trendline, \$helpPluginFilename ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

          if ( $rv ) {
            $matchingDisplayCT .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

            if ( $sth->rows ) {
              $prevDisplayDaemon = $prevGroupTitle = '';

              while( $sth->fetch() ) {
                if ( $prevDisplayDaemon ne $displayDaemon ) {
	  			  if ( $prevDisplayDaemon ne '' ) {
                    if ($rvOpen) {
                      print DisplayCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde DisplayCT-$prevDisplayDaemon - $serverID\n";
                      close(DisplayCT);
                      $rvOpen = 0;
                      $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
                      $matchingDisplayCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc/DisplayCT-$prevDisplayDaemon $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/etc/DisplayCT-$prevDisplayDaemon", $debug) if ($typeServers);
                      $matchingDisplayCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>DisplayCT-$prevDisplayDaemon, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
                    }
                  }

                  $matchingDisplayCT .= "\n        <tr><th>DisplayCT - $serverID</th></tr>" if ( $prevDisplayDaemon ne $displayDaemon );

                  $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
                  $matchingDisplayCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN", $debug);
                  $matchingDisplayCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc", $debug);
                  $matchingDisplayCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/master", $debug);
                  $matchingDisplayCT .= createDisplayCTscript ($typeMonitoringCharDorC, 'M', $typeActiveServer, $masterFQDN, $masterASNMTAP_PATH, $masterRSYNC_PATH, $masterSSH_PATH, $centralMasterDatabaseFQDN, "master", $displayDaemon, $pagedirs, $loop, $trigger, $displayTime, $lockMySQL, $debugDaemon, $debug);

                  if ( $typeServers ) {
                    $matchingDisplayCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN", $debug);
                    $matchingDisplayCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave", $debug);
                    $matchingDisplayCT .= createDisplayCTscript ($typeMonitoringCharDorC, 'S', $typeActiveServer, $slaveFQDN, $slaveASNMTAP_PATH, $slaveRSYNC_PATH, $slaveSSH_PATH, $centralSlaveDatabaseFQDN, "slave", $displayDaemon, $pagedirs, $loop, $trigger, $displayTime, $lockMySQL, $debugDaemon, $debug);
                  }

                  $rvOpen = open(DisplayCT, ">$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc/DisplayCT-$displayDaemon");

                  if ($rvOpen) {
                    $matchingDisplayCT .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc/DisplayCT-$displayDaemon\" target=\"_blank\">DisplayCT-$displayDaemon</a></td></tr>";
                    print DisplayCT "# DisplayCT-$displayDaemon - $serverID, generated on $configDateTime, ASNMTAP v$version or higher\n#\n# <interval>#<groep title>#<resultsdir>#[<catalogID>_]<uniqueKey>#<titel nnn>#check_nnn#<help 0|1>[|[<catalogID>_]<uniqueKey>#<titel mmm>#check_mmm#<help 0|1>]\n#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n#\n";
                  }
                } else {
                  print DisplayCT "#\n" if ( $prevGroupTitle ne $groupTitle and $prevGroupTitle ne '' );
                }

                if ($rvOpen) {
                  my $catalogID_uKey = ( ( $catalogID eq 'CID' ) ? '' : $catalogID .'_' ) . $uKey;
                  print DisplayCT "$interval#$groupTitle#$resultsdir#$catalogID_uKey#$title#$test --environment=$environment --trendline=$trendline#";
                  (! defined $helpPluginFilename or $helpPluginFilename eq '<NIHIL>') ? print DisplayCT "0" : print DisplayCT "1";
                  print DisplayCT "\n";
                }

                $prevDisplayDaemon      = $displayDaemon;
                $prevGroupTitle         = $groupTitle;
              }

              if ($rvOpen) {
                print DisplayCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde DisplayCT-$displayDaemon - $serverID\n";
                close(DisplayCT);
                $rvOpen = 0;
                $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
                $matchingDisplayCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc/DisplayCT-$displayDaemon $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/etc/DisplayCT-$displayDaemon", $debug) if ($typeServers);
                $matchingDisplayCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>DisplayCT-$displayDaemon, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
              }
            } else {
              $matchingDisplayCT .= "        <tr><td>No records found for any DisplayCT</td></tr>\n";
            }

            $matchingDisplayCT .= "      </table>\n";
            $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
          }
        }

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # Display Start/Stop scripts
        $sql = "select $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.typeActiveServer, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.masterASNMTAP_PATH, $SERVERTABLSERVERS.masterRSYNC_PATH, $SERVERTABLSERVERS.masterSSH_PATH, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLSERVERS.slaveASNMTAP_PATH, $SERVERTABLSERVERS.slaveRSYNC_PATH, $SERVERTABLSERVERS.slaveSSH_PATH, $SERVERTABLDISPLAYDMNS.displayDaemon from $SERVERTABLSERVERS, $SERVERTABLDISPLAYDMNS where $SERVERTABLSERVERS.catalogID = '$CATALOGID' and $SERVERTABLSERVERS.activated = 1 and $SERVERTABLSERVERS.catalogID = $SERVERTABLDISPLAYDMNS.catalogID and $SERVERTABLSERVERS.serverID = $SERVERTABLDISPLAYDMNS.serverID and $SERVERTABLDISPLAYDMNS.activated = 1 order by $SERVERTABLSERVERS.serverID, $SERVERTABLDISPLAYDMNS.displayDaemon";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$typeActiveServer, \$masterFQDN, \$masterASNMTAP_PATH, \$masterRSYNC_PATH, \$masterSSH_PATH, \$slaveFQDN, \$slaveASNMTAP_PATH, \$slaveRSYNC_PATH, \$slaveSSH_PATH, \$displayDaemon ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

        if ( $rv ) {
          $matchingAsnmtapDisplayCTscript .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

          if ( $sth->rows ) {
            $prevTypeServers = $prevTypeActiveServer = 0;
            $prevServerID = $prevMasterFQDN = $prevMasterASNMTAP_PATH = $prevMasterRSYNC_PATH = $prevMasterSSH_PATH = $prevSlaveFQDN = $prevSlaveASNMTAP_PATH = $prevSlaveRSYNC_PATH = $prevSlaveSSH_PATH = '';

            while( $sth->fetch() ) {
              if ( $prevServerID ne $serverID ) {
                if ( $prevServerID ne '' ) {
                  $matchingAsnmtapDisplayCTscript .= createAsnmtapDisplayCTscript ($prevTypeMonitoring, 'M', $prevTypeActiveServer, $prevMasterFQDN, $prevMasterASNMTAP_PATH, $prevMasterRSYNC_PATH, $prevMasterSSH_PATH, "master", $debug);
                  $matchingAsnmtapDisplayCTscript .= createAsnmtapDisplayCTscript ($prevTypeMonitoring, 'S', $prevTypeActiveServer, $prevSlaveFQDN, $prevSlaveASNMTAP_PATH, $prevSlaveRSYNC_PATH, $prevSlaveSSH_PATH, "slave", $debug) if ( $prevTypeServers );
                  $matchingAsnmtapDisplayCTscript .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Display Start/Stop scripts - $prevServerID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
                  delete @matchingAsnmtapDisplayCTscript[0..@matchingAsnmtapDisplayCTscript];
                }

                $matchingAsnmtapDisplayCTscript .= "\n        <tr><th>Display Start/Stop scripts - $serverID</th></tr>";
              }

              push (@matchingAsnmtapDisplayCTscript, "DisplayCT-$displayDaemon.sh");
              $prevServerID           = $serverID;
              $prevTypeMonitoring     = $typeMonitoring;
              $prevTypeServers        = $typeServers;
              $prevTypeActiveServer   = $typeActiveServer;
              $prevMasterFQDN         = $masterFQDN;
              $prevMasterASNMTAP_PATH = $masterASNMTAP_PATH;
              $prevMasterRSYNC_PATH   = $masterRSYNC_PATH;
              $prevMasterSSH_PATH     = $masterSSH_PATH;
              $prevSlaveFQDN          = $slaveFQDN;
              $prevSlaveASNMTAP_PATH  = $slaveASNMTAP_PATH;
              $prevSlaveRSYNC_PATH    = $slaveRSYNC_PATH;
              $prevSlaveSSH_PATH      = $slaveSSH_PATH;
            }

            $matchingAsnmtapDisplayCTscript .= createAsnmtapDisplayCTscript ($typeMonitoring, 'M', $typeActiveServer, $masterFQDN, $masterASNMTAP_PATH, $masterRSYNC_PATH, $masterSSH_PATH, "master", $debug);
            $matchingAsnmtapDisplayCTscript .= createAsnmtapDisplayCTscript ($typeMonitoring, 'S', $typeActiveServer, $slaveFQDN, $slaveASNMTAP_PATH, $slaveRSYNC_PATH, $slaveSSH_PATH, "slave", $debug) if ( $typeServers );
            $matchingAsnmtapDisplayCTscript .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Display Start/Stop scripts - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
          } else {
            $matchingAsnmtapDisplayCTscript .= "        <tr><td>No records found for any DisplayCT</td></tr>\n";
          }

          $matchingAsnmtapDisplayCTscript .= "      </table>\n";
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        }

        # CollectorCT - - - - - - - - - - - - - - - - - - - - - - - - - -
        $sql = "select $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.typeActiveServer, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.masterASNMTAP_PATH, $SERVERTABLSERVERS.masterRSYNC_PATH, $SERVERTABLSERVERS.masterSSH_PATH, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLSERVERS.slaveASNMTAP_PATH, $SERVERTABLSERVERS.slaveRSYNC_PATH, $SERVERTABLSERVERS.slaveSSH_PATH, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLCLLCTRDMNS.mode, $SERVERTABLCLLCTRDMNS.dumphttp, $SERVERTABLCLLCTRDMNS.status, $SERVERTABLCLLCTRDMNS.debugDaemon, $SERVERTABLCLLCTRDMNS.debugAllScreen, $SERVERTABLCLLCTRDMNS.debugAllFile, $SERVERTABLCLLCTRDMNS.debugNokFile, $SERVERTABLCRONTABS.minute, $SERVERTABLCRONTABS.hour, $SERVERTABLCRONTABS.dayOfTheMonth, $SERVERTABLCRONTABS.monthOfTheYear, $SERVERTABLCRONTABS.dayOfTheWeek, $SERVERTABLPLUGINS.step, $SERVERTABLPLUGINS.catalogID, $SERVERTABLPLUGINS.uKey, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLPLUGINS.title, $SERVERTABLPLUGINS.test, $SERVERTABLPLUGINS.environment, $SERVERTABLPLUGINS.arguments, $SERVERTABLCRONTABS.arguments, $SERVERTABLPLUGINS.trendline, $SERVERTABLCRONTABS.noOffline from $SERVERTABLSERVERS, $SERVERTABLCLLCTRDMNS, $SERVERTABLCRONTABS, $SERVERTABLPLUGINS where $SERVERTABLSERVERS.catalogID = '$CATALOGID' and $SERVERTABLSERVERS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLSERVERS.serverID = $SERVERTABLCLLCTRDMNS.serverID and $SERVERTABLSERVERS.activated = 1 and $SERVERTABLCLLCTRDMNS.catalogID = $SERVERTABLCRONTABS.catalogID and $SERVERTABLCLLCTRDMNS.collectorDaemon = $SERVERTABLCRONTABS.collectorDaemon and $SERVERTABLCLLCTRDMNS.activated = 1 and $SERVERTABLCRONTABS.catalogID = $SERVERTABLPLUGINS.catalogID and $SERVERTABLCRONTABS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLCRONTABS.activated = 1 and $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.production = 1 order by $SERVERTABLSERVERS.serverID, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLCRONTABS.uKey, $SERVERTABLCRONTABS.linenumber";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$typeActiveServer, \$masterFQDN, \$masterASNMTAP_PATH, \$masterRSYNC_PATH, \$masterSSH_PATH, \$slaveFQDN, \$slaveASNMTAP_PATH, \$slaveRSYNC_PATH, \$slaveSSH_PATH, \$collectorDaemon, \$mode, \$dumphttp, \$status, \$debugDaemon, \$debugAllScreen, \$debugAllFile, \$debugNokFile, \$minute, \$hour, \$dayOfTheMonth, \$monthOfTheYear, \$dayOfTheWeek, \$interval, \$catalogID, \$uKey, \$resultsdir, \$title, \$test, \$environment, \$argumentsCommon, \$argumentsCrontab, \$trendline, \$noOffline ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

        if ( $rv ) {
          $matchingCollectorCT .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

          if ( $sth->rows ) {
            $prevTypeServers = $prevTypeActiveServer = 0;
            $prevServerID = $prevMasterFQDN = $prevMasterASNMTAP_PATH = $prevMasterRSYNC_PATH = $prevMasterSSH_PATH = $prevSlaveFQDN = $prevSlaveASNMTAP_PATH = $prevSlaveRSYNC_PATH = $prevSlaveSSH_PATH = $prevCollectorDaemon = $prevUniqueKey = '';

            while( $sth->fetch() ) {
              if ( $prevServerID ne $serverID or $prevCollectorDaemon ne $collectorDaemon ) {
				if ( $prevCollectorDaemon ne '' ) {
                  if ($rvOpen) {
                    print CollectorCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde CollectorCT-$prevCollectorDaemon - $prevServerID";
                    close(CollectorCT);
                    $rvOpen = 0;
                    $typeMonitoringCharDorC = ($prevTypeMonitoring) ? 'D' : 'C';

                    if ($prevTypeServers) {
                      $matchingCollectorCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$prevTypeActiveServer-$prevMasterFQDN/etc/CollectorCT-$prevCollectorDaemon $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$prevTypeActiveServer-$prevSlaveFQDN/etc/CollectorCT-$prevCollectorDaemon", $debug);

                      my ($hostnameAdminCollector, undef) = split (/\./, $prevMasterFQDN, 2);

                      if ( $prevCollectorDaemon eq $hostnameAdminCollector ) {
                        unlink ("$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$prevTypeActiveServer-$prevSlaveFQDN/etc/CollectorCT-$prevCollectorDaemon");
                      } else {
                        my ($hostnameAdminCollector, undef) = split (/\./, $prevSlaveFQDN, 2);
                        unlink ("$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$prevTypeActiveServer-$prevMasterFQDN/etc/CollectorCT-$prevCollectorDaemon") if ( $prevCollectorDaemon eq $hostnameAdminCollector );
                      }
                    }

                    $matchingCollectorCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>CollectorCT-$prevCollectorDaemon - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
                  }
                }

                $matchingCollectorCT .= "\n        <tr><th>CollectorCT - $serverID</th></tr>" if ( $prevServerID ne $serverID and $prevCollectorDaemon ne $collectorDaemon );

                $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
                $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN", $debug);
                $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc", $debug);
                $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/master", $debug);
                $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/slave", $debug) if ($typeMonitoring);
                $matchingCollectorCT .= createCollectorCTscript ($typeMonitoringCharDorC, 'M', $typeActiveServer, $masterFQDN, $slaveFQDN, $masterASNMTAP_PATH, $masterRSYNC_PATH, $masterSSH_PATH, $centralMasterDatabaseFQDN, "master", $collectorDaemon, $mode, $dumphttp, $status, $debugDaemon, $debugAllScreen, $debugAllFile, $debugNokFile, $debug);

                if ( $typeServers ) {                          # Failover
                  $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN", $debug);
                  $matchingCollectorCT .= system_call ("mkdir", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave", $debug);
                  $matchingCollectorCT .= createCollectorCTscript ($typeMonitoringCharDorC, 'S', $typeActiveServer, $slaveFQDN, $masterFQDN, $slaveASNMTAP_PATH, $slaveRSYNC_PATH, $slaveSSH_PATH, $centralSlaveDatabaseFQDN, "slave", $collectorDaemon, $mode, $dumphttp, $status, $debugDaemon, $debugAllScreen, $debugAllFile, $debugNokFile, $debug);
                }

                $rvOpen = open(CollectorCT, ">$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc/CollectorCT-$collectorDaemon");

                if ($rvOpen) {
                  $matchingCollectorCT .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc/CollectorCT-$collectorDaemon\" target=\"_blank\">CollectorCT-$collectorDaemon</a></td></tr>";
                  print CollectorCT "# CollectorCT-$collectorDaemon - $serverID, generated on $configDateTime, ASNMTAP v$version or higher\n#\n# <minute (0-59)> <hour (0-23)> <day of the month (1-31)> <month of the year (1-12)> <day of the week (0-6 with 0=Sunday)> <interval (1-30 min)> [<catalogID>_]<uniqueKey>#<resultsdir>#<titel nnn>#check_nnn[#noOFFLINE|multiOFFLINE|noTEST]][|[<catalogID>_]<uniqueKey>#<resultsdir>#<titel mmm>#check_mmm[#noOFFLINE|multiOFFLINE|noTEST]]\n#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n#\n";

                }
              } else {
                print CollectorCT "#\n" if ( $prevUniqueKey ne $uKey and $prevUniqueKey ne '');
              }

              if ($rvOpen) {
                my $catalogID_uKey = ( ( $catalogID eq 'CID' ) ? '' : $catalogID .'_' ) . $uKey;
                print CollectorCT "$minute $hour $dayOfTheMonth $monthOfTheYear $dayOfTheWeek $interval $catalogID_uKey#$resultsdir#$title#$test";
                print CollectorCT " --environment=$environment --trendline=$trendline";
                print CollectorCT " $argumentsCommon" if ( $argumentsCommon ne '' );
                print CollectorCT " $argumentsCrontab" if ( $argumentsCrontab ne '' );
                print CollectorCT "#$noOffline" if ( $noOffline ne '' );
                print CollectorCT "\n";
              }

              $prevServerID           = $serverID;
              $prevTypeMonitoring     = $typeMonitoring;
              $prevTypeServers        = $typeServers;
              $prevTypeActiveServer   = $typeActiveServer;
              $prevMasterFQDN         = $masterFQDN;
              $prevMasterASNMTAP_PATH = $masterASNMTAP_PATH;
              $prevMasterRSYNC_PATH   = $masterRSYNC_PATH;
              $prevMasterSSH_PATH     = $masterSSH_PATH;
              $prevSlaveFQDN          = $slaveFQDN;
              $prevSlaveASNMTAP_PATH  = $slaveASNMTAP_PATH;
              $prevSlaveRSYNC_PATH    = $slaveRSYNC_PATH;
              $prevSlaveSSH_PATH      = $slaveSSH_PATH;
              $prevCollectorDaemon    = $collectorDaemon;
              $prevUniqueKey          = $uKey;
            }

            if ($rvOpen) {
              print CollectorCT "#\n# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n# Einde CollectorCT-$collectorDaemon - $serverID\n";
              close(CollectorCT);
              $rvOpen = 0;
              $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';

              if ($prevTypeServers) {
                $matchingCollectorCT .= system_call ("cp", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc/CollectorCT-$collectorDaemon $APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/etc/CollectorCT-$collectorDaemon", $debug);

                my ($hostnameAdminCollector, undef) = split (/\./, $masterFQDN, 2);

                if ( $collectorDaemon eq $hostnameAdminCollector ) {
                  unlink ("$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/etc/CollectorCT-$collectorDaemon");
                } else {
                  my ($hostnameAdminCollector, undef) = split (/\./, $slaveFQDN, 2);
                  unlink ("$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/etc/CollectorCT-$collectorDaemon") if ( $collectorDaemon eq $hostnameAdminCollector );
                }
              }

              $matchingCollectorCT .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>CollectorCT-$collectorDaemon - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
            }
          } else {
            $matchingCollectorCT .= "        <tr><td>No records found for any CollectorCT</td></tr>\n";
          }

          $matchingCollectorCT .= "      </table>\n";
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        }

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # Collector Start/Stop scripts
        $sql = "select DISTINCT $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.typeActiveServer, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.masterASNMTAP_PATH, $SERVERTABLSERVERS.masterRSYNC_PATH, $SERVERTABLSERVERS.masterSSH_PATH, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLSERVERS.slaveASNMTAP_PATH, $SERVERTABLSERVERS.slaveRSYNC_PATH, $SERVERTABLSERVERS.slaveSSH_PATH, $SERVERTABLCLLCTRDMNS.collectorDaemon from $SERVERTABLSERVERS, $SERVERTABLCLLCTRDMNS, $SERVERTABLCRONTABS, $SERVERTABLPLUGINS where $SERVERTABLSERVERS.catalogID = '$CATALOGID' and $SERVERTABLSERVERS.activated = 1 and $SERVERTABLSERVERS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLSERVERS.serverID = $SERVERTABLCLLCTRDMNS.serverID and $SERVERTABLCLLCTRDMNS.activated = 1 AND $SERVERTABLCLLCTRDMNS.catalogID = $SERVERTABLCRONTABS.catalogID AND $SERVERTABLCLLCTRDMNS.collectorDaemon = $SERVERTABLCRONTABS.collectorDaemon AND $SERVERTABLCRONTABS.activated = 1 AND $SERVERTABLCRONTABS.catalogID = $SERVERTABLPLUGINS.catalogID AND $SERVERTABLCRONTABS.uKey = $SERVERTABLPLUGINS.uKey AND $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.production = 1 order by $SERVERTABLSERVERS.serverID, $SERVERTABLCLLCTRDMNS.collectorDaemon";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$typeActiveServer, \$masterFQDN, \$masterASNMTAP_PATH, \$masterRSYNC_PATH, \$masterSSH_PATH, \$slaveFQDN, \$slaveASNMTAP_PATH, \$slaveRSYNC_PATH, \$slaveSSH_PATH, \$collectorDaemon ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

        if ( $rv ) {
          $matchingAsnmtapCollectorCTscript .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

          if ( $sth->rows ) {
            $prevTypeServers = $prevTypeActiveServer = 0;
            $prevServerID = $prevMasterFQDN = $prevMasterASNMTAP_PATH = $prevMasterRSYNC_PATH = $prevMasterSSH_PATH = $prevSlaveFQDN = $prevSlaveASNMTAP_PATH = $prevSlaveRSYNC_PATH = $prevSlaveSSH_PATH = '';

            while( $sth->fetch() ) {
              if ( $prevServerID ne $serverID ) {
                if ( $prevServerID ne '' ) {
                  $matchingAsnmtapCollectorCTscript .= createAsnmtapCollectorCTscript ($prevTypeMonitoring, 'M', $prevTypeActiveServer, $prevMasterFQDN, $prevSlaveFQDN, $prevMasterASNMTAP_PATH, $prevMasterRSYNC_PATH, $prevMasterSSH_PATH, "master", $debug);
                  $matchingAsnmtapCollectorCTscript .= createAsnmtapCollectorCTscript ($prevTypeMonitoring, 'S', $prevTypeActiveServer, $prevSlaveFQDN, $prevMasterFQDN, $prevSlaveASNMTAP_PATH, $prevSlaveRSYNC_PATH, $prevSlaveSSH_PATH, "slave", $debug) if ( $prevTypeServers );
                  $matchingAsnmtapCollectorCTscript .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Collector Start/Stop scripts - $prevServerID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
                  delete @matchingAsnmtapCollectorCTscript[0..@matchingAsnmtapCollectorCTscript];
                }

                $matchingAsnmtapCollectorCTscript .= "\n        <tr><th>Collector Start/Stop scripts - $serverID</th></tr>";
              }

              push (@matchingAsnmtapCollectorCTscript, "CollectorCT-$collectorDaemon.sh");
              $prevServerID           = $serverID;
              $prevTypeMonitoring     = $typeMonitoring;
              $prevTypeServers        = $typeServers;
              $prevTypeActiveServer   = $typeActiveServer;
              $prevMasterFQDN         = $masterFQDN;
              $prevMasterASNMTAP_PATH = $masterASNMTAP_PATH;
              $prevMasterRSYNC_PATH   = $masterRSYNC_PATH;
              $prevMasterSSH_PATH     = $masterSSH_PATH;
              $prevSlaveFQDN          = $slaveFQDN;
              $prevSlaveASNMTAP_PATH  = $slaveASNMTAP_PATH;
              $prevSlaveRSYNC_PATH    = $slaveRSYNC_PATH;
              $prevSlaveSSH_PATH      = $slaveSSH_PATH;
            }

            $matchingAsnmtapCollectorCTscript .= createAsnmtapCollectorCTscript ($typeMonitoring, 'M', $typeActiveServer, $masterFQDN, $slaveFQDN, $masterASNMTAP_PATH, $masterRSYNC_PATH, $masterSSH_PATH, "master", $debug);
            $matchingAsnmtapCollectorCTscript .= createAsnmtapCollectorCTscript ($typeMonitoring, 'S', $typeActiveServer, $slaveFQDN, $masterFQDN, $slaveASNMTAP_PATH, $slaveRSYNC_PATH, $slaveSSH_PATH, "slave", $debug) if ( $typeServers );
            $matchingAsnmtapCollectorCTscript .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Collector Start/Stop scripts - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
          } else {
            $matchingAsnmtapCollectorCTscript .= "        <tr><td>No records found for any CollectorCT</td></tr>\n";
          }

          $matchingAsnmtapCollectorCTscript .= "      </table>\n";
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        }

        # rsync-mirror  - - - - - - - - - - - - - - - - - - - - - - - - -
        $sql = "select distinct $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.typeActiveServer, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.masterASNMTAP_PATH, $SERVERTABLSERVERS.masterRSYNC_PATH, $SERVERTABLSERVERS.masterSSH_PATH, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLSERVERS.slaveASNMTAP_PATH, $SERVERTABLSERVERS.slaveRSYNC_PATH, $SERVERTABLSERVERS.slaveSSH_PATH, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLPLUGINS.resultsdir from $SERVERTABLSERVERS, $SERVERTABLCLLCTRDMNS, $SERVERTABLCRONTABS, $SERVERTABLPLUGINS where $SERVERTABLSERVERS.catalogID = '$CATALOGID' and $SERVERTABLSERVERS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLSERVERS.serverID = $SERVERTABLCLLCTRDMNS.serverID and $SERVERTABLSERVERS.activated = 1 and $SERVERTABLCLLCTRDMNS.catalogID = $SERVERTABLCRONTABS.catalogID and $SERVERTABLCLLCTRDMNS.collectorDaemon = $SERVERTABLCRONTABS.collectorDaemon and $SERVERTABLCLLCTRDMNS.activated = 1 and $SERVERTABLCRONTABS.catalogID = $SERVERTABLPLUGINS.catalogID and $SERVERTABLCRONTABS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLCRONTABS.activated = 1 and $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.production = 1 order by $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.serverID, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLPLUGINS.resultsdir";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
        $sth->bind_columns( \$serverID, \$typeMonitoring, \$typeServers, \$typeActiveServer, \$masterFQDN, \$masterASNMTAP_PATH, \$masterRSYNC_PATH, \$masterSSH_PATH, \$slaveFQDN, \$slaveASNMTAP_PATH, \$slaveRSYNC_PATH, \$slaveSSH_PATH, \$collectorDaemon, \$resultsdir ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

        if ( $rv ) {
          $matchingRsyncMirror .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";

          if ( $sth->rows ) {
            my ($matchingRsyncMirrorConfigFailover, $matchingRsyncMirrorConfigDistributedMaster, $matchingRsyncMirrorConfigDistributedSlave);
            $matchingRsyncMirrorConfigFailover = $matchingRsyncMirrorConfigDistributedMaster = $matchingRsyncMirrorConfigDistributedSlave = '';

            my ($sameServerID, $firstCollectorDaemon) = (0, 0);
            $prevTypeMonitoring = $prevTypeServers = $prevTypeActiveServer = 0;
            $prevServerID = $prevMasterFQDN = $prevMasterASNMTAP_PATH = $prevMasterRSYNC_PATH = $prevMasterSSH_PATH = $prevSlaveFQDN = $prevSlaveASNMTAP_PATH = $prevSlaveRSYNC_PATH = $prevSlaveSSH_PATH = $prevCollectorDaemon = $prevResultsdir = '';

            while( $sth->fetch() ) {
              $sameServerID = ( $prevServerID eq $serverID ) ? 1 : 0;
              $firstCollectorDaemon = ( $sameServerID and $prevCollectorDaemon ne $collectorDaemon ) ? 1 : 0;

              if ((! $sameServerID) or $firstCollectorDaemon) {
                if ($prevServerID ne '' and $prevCollectorDaemon ne '') {
                  $matchingRsyncMirror .= createRsyncMirrorScriptsFailover ($prevServerID, $prevTypeMonitoring, $prevTypeServers, $prevTypeActiveServer, $prevMasterFQDN, $prevMasterASNMTAP_PATH, $prevMasterRSYNC_PATH, $prevMasterSSH_PATH, $prevSlaveFQDN, $prevSlaveASNMTAP_PATH, $prevSlaveRSYNC_PATH, $prevSlaveSSH_PATH, $prevCollectorDaemon, $matchingRsyncMirrorConfigFailover, $debug);
                  $matchingRsyncMirror .= createRsyncMirrorScriptsDistributed ($prevServerID, $prevTypeMonitoring, $prevTypeServers, $prevTypeActiveServer, $prevMasterFQDN, $prevMasterASNMTAP_PATH, $prevMasterRSYNC_PATH, $prevMasterSSH_PATH, $prevSlaveFQDN, $prevSlaveASNMTAP_PATH, $prevSlaveRSYNC_PATH, $prevSlaveSSH_PATH, $centralTypeMonitoring, $centralTypeServers, $centralTypeActiveServer, $centralMasterFQDN, $centralMasterASNMTAP_PATH, $centralMasterRSYNC_PATH, $centralMasterSSH_PATH, $centralSlaveFQDN, $centralSlaveASNMTAP_PATH, $centralSlaveRSYNC_PATH, $centralSlaveSSH_PATH, $prevCollectorDaemon, $matchingRsyncMirrorConfigDistributedMaster, $matchingRsyncMirrorConfigDistributedSlave, $debug);
                  $matchingRsyncMirror .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Rsync Mirror Scripts - $prevServerID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>" unless ($sameServerID);
                  $matchingRsyncMirrorConfigFailover = $matchingRsyncMirrorConfigDistributedMaster = $matchingRsyncMirrorConfigDistributedSlave = '';
                }

                $matchingRsyncMirror .= "\n        <tr><th>Rsync Mirroring Setup - $serverID</th></tr>" unless ($sameServerID);
              }

              if ($typeServers) {
                my ($hostnameAdminCollector, undef) = split (/\./, $slaveFQDN, 2);

                if ( $collectorDaemon eq $hostnameAdminCollector ) {
                  $matchingRsyncMirrorConfigFailover .= "$SSHLOGONNAME\@$slaveFQDN:$slaveASNMTAP_PATH/results/$resultsdir/ $masterASNMTAP_PATH/results/$resultsdir/ -v -c -z --exclude=*-all.txt --exclude=*-nok.txt --exclude=*-KnownError --exclude=*.tmp --exclude=*.sql\n";
                } else {
                  $matchingRsyncMirrorConfigFailover .= "$SSHLOGONNAME\@$masterFQDN:$masterASNMTAP_PATH/results/$resultsdir/ $slaveASNMTAP_PATH/results/$resultsdir/ -v -c -z --exclude=*-all.txt --exclude=*-nok.txt --exclude=*-KnownError --exclude=*.tmp --exclude=*.sql\n";
                }
              }

              if ($typeMonitoring) {
                $matchingRsyncMirrorConfigDistributedMaster .= "$masterASNMTAP_PATH/results/$resultsdir/ $SSHLOGONNAME\@$centralMasterFQDN:$centralMasterASNMTAP_PATH/results/$resultsdir/ -v -c -z --exclude=*-all.txt --exclude=*-nok.txt --exclude=*-KnownError --exclude=*.tmp --exclude=*.sql\n";
                $matchingRsyncMirrorConfigDistributedSlave  .= "$slaveASNMTAP_PATH/results/$resultsdir/ $SSHLOGONNAME\@$centralMasterFQDN:$centralMasterASNMTAP_PATH/results/$resultsdir/ -v -c -z --exclude=*-all.txt --exclude=*-nok.txt --exclude=*-KnownError --exclude=*.tmp --exclude=*.sql\n";

                if ( defined $centralSlaveFQDN and $centralSlaveFQDN ) { # and $centralTypeServers ?
                  $matchingRsyncMirrorConfigDistributedMaster .= "$masterASNMTAP_PATH/results/$resultsdir/ $SSHLOGONNAME\@$centralSlaveFQDN:$centralSlaveASNMTAP_PATH/results/$resultsdir/ -v -c -z --exclude=*-all.txt --exclude=*-nok.txt --exclude=*-KnownError --exclude=*.tmp --exclude=*.sql\n";
                  $matchingRsyncMirrorConfigDistributedSlave  .= "$slaveASNMTAP_PATH/results/$resultsdir/ $SSHLOGONNAME\@$centralSlaveFQDN:$centralSlaveASNMTAP_PATH/results/$resultsdir/ -v -c -z --exclude=*-all.txt --exclude=*-nok.txt --exclude=*-KnownError --exclude=*.tmp --exclude=*.sql\n";
                }
              }

              $prevServerID           = $serverID;
              $prevTypeMonitoring     = $typeMonitoring;
              $prevTypeServers        = $typeServers;
              $prevTypeActiveServer   = $typeActiveServer;
              $prevMasterFQDN         = $masterFQDN;
              $prevMasterASNMTAP_PATH = $masterASNMTAP_PATH;
              $prevMasterRSYNC_PATH   = $masterRSYNC_PATH;
              $prevMasterSSH_PATH     = $masterSSH_PATH;
              $prevSlaveFQDN          = $slaveFQDN;
              $prevSlaveASNMTAP_PATH  = $slaveASNMTAP_PATH;
              $prevSlaveRSYNC_PATH    = $slaveRSYNC_PATH;
              $prevSlaveSSH_PATH      = $slaveSSH_PATH;
              $prevCollectorDaemon    = $collectorDaemon;
              $prevResultsdir         = $resultsdir;
            }

            $matchingRsyncMirror .= createRsyncMirrorScriptsFailover ($serverID, $typeMonitoring, $typeServers, $typeActiveServer, $masterFQDN, $masterASNMTAP_PATH, $masterRSYNC_PATH, $masterSSH_PATH, $slaveFQDN, $slaveASNMTAP_PATH, $slaveRSYNC_PATH, $slaveSSH_PATH, $collectorDaemon, $matchingRsyncMirrorConfigFailover, $debug);
            $matchingRsyncMirror .= createRsyncMirrorScriptsDistributed ($serverID, $typeMonitoring, $typeServers, $typeActiveServer, $masterFQDN, $masterASNMTAP_PATH, $masterRSYNC_PATH, $masterSSH_PATH, $slaveFQDN, $slaveASNMTAP_PATH, $slaveRSYNC_PATH, $slaveSSH_PATH, $centralTypeMonitoring, $centralTypeServers, $centralTypeActiveServer, $centralMasterFQDN, $centralMasterASNMTAP_PATH, $centralMasterRSYNC_PATH, $centralMasterSSH_PATH, $centralSlaveFQDN, $centralSlaveASNMTAP_PATH, $centralSlaveRSYNC_PATH, $centralSlaveSSH_PATH, $collectorDaemon, $matchingRsyncMirrorConfigDistributedMaster, $matchingRsyncMirrorConfigDistributedSlave, $debug);

            $matchingRsyncMirror .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>Rsync Mirror Scripts - $serverID, generated on $configDateTime, ASNMTAP v$version or higher</td></tr>";
          } else {
            $matchingRsyncMirror .= "\n        <tr><td>No records found for any RsyncMirror</td></tr>";
          }

          $matchingRsyncMirror .= "\n      </table>";
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
        }

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      }

      $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
    }
  } elsif ($action eq 'compareView') {
    # open connection to database and query data
    $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);

    if ($dbh and $rv) {
      my ( $masterFQDN, $masterASNMTAP_PATH, $masterRSYNC_PATH, $masterSSH_PATH, $slaveFQDN, $slaveASNMTAP_PATH, $slaveRSYNC_PATH, $slaveSSH_PATH );
      $sql = "SELECT masterFQDN, masterASNMTAP_PATH, masterRSYNC_PATH, masterSSH_PATH, slaveFQDN, slaveASNMTAP_PATH, slaveRSYNC_PATH, slaveSSH_PATH FROM $SERVERTABLSERVERS where catalogID = '$CATALOGID' and activated = 1";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$masterFQDN, \$masterASNMTAP_PATH, \$masterRSYNC_PATH, \$masterSSH_PATH, \$slaveFQDN, \$slaveASNMTAP_PATH, \$slaveRSYNC_PATH, \$slaveSSH_PATH ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            $ASNMTAP_PATH { 'M' } { $masterFQDN } = $masterASNMTAP_PATH if ( defined $masterFQDN and $masterFQDN and defined $masterASNMTAP_PATH and $masterASNMTAP_PATH );
            $ASNMTAP_PATH { 'S'} { $slaveFQDN } = $slaveASNMTAP_PATH if ( defined $slaveFQDN and $slaveFQDN and defined $slaveASNMTAP_PATH and $slaveASNMTAP_PATH );
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      }

      $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
    }

    $compareView .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";
    $compareView .= "\n        <tr><th>Compare Configurations</th></tr>";

    my $compareDiff = system_call ("$DIFFCOMMAND -braq -I 'generated on 20[0-9][0-9]/[0-9][0-9]/[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]'", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated $APPLICATIONPATH/tmp/$CONFIGDIR/installed", $debug);

    if ($compareDiff eq '') {
      $compareView .= "\n		   <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>The generated and installed configurations are identical.</td></tr>";
    } else {
      $compareView .= "\n		   $compareDiff";
    }

    $compareView .= "\n      </table>";
  } elsif ($action eq 'installView') {
    # open connection to database and query data
    $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);

    if ($dbh and $rv) {
      my ( $masterFQDN, $masterASNMTAP_PATH, $masterRSYNC_PATH, $masterSSH_PATH, $slaveFQDN, $slaveASNMTAP_PATH, $slaveRSYNC_PATH, $slaveSSH_PATH );
      $sql = "SELECT masterFQDN, masterASNMTAP_PATH, masterRSYNC_PATH, masterSSH_PATH, slaveFQDN, slaveASNMTAP_PATH, slaveRSYNC_PATH, slaveSSH_PATH FROM $SERVERTABLSERVERS where catalogID = '$CATALOGID' and activated = 1";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      $sth->bind_columns( \$masterFQDN, \$masterASNMTAP_PATH, \$masterRSYNC_PATH, \$masterSSH_PATH, \$slaveFQDN, \$slaveASNMTAP_PATH, \$slaveRSYNC_PATH, \$slaveSSH_PATH ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;

      if ($rv) {
        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            $ASNMTAP_PATH { 'M' } { $masterFQDN } = $masterASNMTAP_PATH if ( defined $masterFQDN and $masterFQDN and defined $masterASNMTAP_PATH and $masterASNMTAP_PATH );
            $ASNMTAP_PATH { 'S'} { $slaveFQDN } = $slaveASNMTAP_PATH if ( defined $slaveFQDN and $slaveFQDN and defined $slaveASNMTAP_PATH and $slaveASNMTAP_PATH );
          }
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID) if $rv;
      }

      $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, -1, '', $sessionID);
    }

    $installView .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";
    $installView .= "\n        <tr><th>Install Configuration</th></tr>";

    if ( -e "$APPLICATIONPATH/tmp/$CONFIGDIR/generated" ) {
      my $compareDiff = system_call ("$DIFFCOMMAND -braq -E 'generated on 20[0-9][0-9]/[0-9][0-9]/[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]'", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated $APPLICATIONPATH/tmp/$CONFIGDIR/installed", $debug);

      if ($compareDiff eq '') {
        $installView .= "\n		   <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>The generated and installed configurations are identical.</td></tr>";
      } else {
        $installView .= "\n        <tr><td align=\"center\"><b>Under construction:</b></td></tr>";
        $installView .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{NOBLOCK}\">$compareDiff</table></td></tr>";
        $installView .= "\n        <tr><td align=\"center\">&nbsp;</td></tr>";
        $installView .= "\n        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>We only are allowed to press the <b>MOVE</b> button when all commands are successfully executed!</td></tr>" if ( $Cauto == 1 );
        $installView .= "\n        <tr align=\"left\"><td align=\"right\"><input type=\"submit\" value=\"". ( ( $Cauto == 1 ) ? 'MOVE' : 'INSTALL' ) ."\"> <input type=\"reset\" value=\"Reset\"></td></tr>\n";
      }
    } else {
      $installView .= "\n        <tr><td>The generated configuration doesn't exist.</td></tr>";
    }

    $installView .= "\n      </table>";
  } elsif ($action eq 'install') {
    $installView .= "\n      <table width=\"100%\" align=\"center\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">";
    $installView .= "\n        <tr><th>Configuration Installed</th></tr>";

    if ( -e "$APPLICATIONPATH/tmp/$CONFIGDIR/generated" ) {
      $installView .= system_call ("rm -rf", "$APPLICATIONPATH/tmp/$CONFIGDIR/installed", $debug);
      $installView .= system_call ("mv", "$APPLICATIONPATH/tmp/$CONFIGDIR/generated $APPLICATIONPATH/tmp/$CONFIGDIR/installed", $debug);
      $installView .= "\n        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>We <b>moved</b> $APPLICATIONPATH/tmp/$CONFIGDIR/generated to $APPLICATIONPATH/tmp/$CONFIGDIR/installed</td></tr>";
    } else {
      $installView .= "\n        <tr><td>The generated configuration doesn't exist.</td></tr>";
    }

    $installView .= "\n      </table>";
  }

  if ( $rv ) {
    if ($action eq 'installView') {
      print "        <form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"generateConfig\">\n";
      my $_action = ( ( $Cauto == 1 ) ? 'install' : $action );

      print <<HTML;
        <input type="hidden" name="pagedir"   value="$pagedir">
        <input type="hidden" name="pageset"   value="$pageset">
        <input type="hidden" name="debug"     value="$debug">
        <input type="hidden" name="CGISESSID" value="$sessionID">
        <input type="hidden" name="action"    value="$_action">
        <input type="hidden" name="auto"      value="1">
HTML

    }

    if ($action eq 'updateView' or $action eq 'update') {
      print "  <table width=\"100%\"><tr align=\"center\"><td>\n";
      print "    <table bgcolor=\"$COLORSTABLE{TABLE}\" border=\"0\" cellspacing=\"1\" cellpadding=\"1\"\n";
      print "      <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\" colspan=\"2\" align=\"center\"> <b>$action: Under Construction</b> </td></tr>\n";
      print "      <tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\"> plugin </td><td> $Cplugin </td></tr>\n";
      print "      <tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\"> help plugin filename </td><td> $ChelpPluginFilename </td></tr>\n";
      print "      <tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\"> todo </td><td> $Ctodo </td></tr>\n";
      print "    </table>\n";
      print "  </td></tr></table>\n";
    } else {
      print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=checkView&amp;auto=0">[Check Configuration]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=generateView&amp;auto=0">[Generate Configuration]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=compareView&amp;auto=0">[Compare Configurations]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=installView&amp;auto=0">[Dry Run Generated Configuration]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=installView&amp;auto=1">[Install Generated Configuration]</a></td>
  	  </tr></table>
	</td></tr>
HTML
    }

    if ($action ne "menuView") {
      print "  <tr align=\"center\"><td>\n  <table>\n";

      if ($action eq 'checkView' or $action eq 'generateView') {
        print "    <tr align=\"center\"><td>&nbsp;</td></tr>\n    <tr align=\"center\"><td>$matchingWarnings</td></tr>\n" if ($countWarnings);
        print "    <tr align=\"center\"><td>&nbsp;</td></tr>\n    <tr align=\"center\"><td>$matchingErrors</td></tr>\n" if ($countErrors);
        print "    <tr align=\"center\"><td>&nbsp;</td></tr>\n    <tr align=\"center\"><td>Warning: $countWarnings, Errors: $countErrors</td></tr>\n";
      }

      if ($action eq 'generateView') {
        if ($countErrors == 0) {
          print <<HTML;
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$initializeGenerateView</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingArchiveCT</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingDisplayCT</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingAsnmtapDisplayCTscript</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingCollectorCT</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingAsnmtapCollectorCTscript</td></tr>
    <tr align="center"><td>&nbsp;</td></tr>
    <tr align="center"><td>$matchingRsyncMirror</td></tr>
HTML
        } else {
          print "    <tr align=\"center\"><td>&nbsp;</td></tr>\n    <tr align=\"center\"><td>Errors: $countErrors, first solve them PLEASE</td></tr>\n";
        }
      } elsif ($action eq 'compareView') {
        print <<HTML;
    <tr align=\"center\"><td>&nbsp;</td></tr>
    <tr align=\"center\"><td>$compareView</td></tr>
HTML
      } elsif ($action eq 'installView' or $action eq 'install') {
        print <<HTML;
    <tr align=\"center\"><td>&nbsp;</td></tr>
    <tr align=\"center\"><td>$installView</td></tr>
HTML
      }

      print "  </table>\n  </td></tr>\n";
    }

    print "  </table>\n";
	
    if ($action eq 'installView') {
      print "</form>\n";
    } else {
      print "<br>\n";
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createCollectorCTscript {
  my ($typeMonitoringCharDorC, $typeServersCharMorS, $typeActiveServer, $serverFQDN, $serverAdminCollectorFQDN, $serverASNMTAP_PATH , $serverRSYNC_PATH , $serverSSH_PATH, $databaseFQDN, $subdir, $collectorDaemon, $mode, $dumphttp, $status, $debugDaemon, $debugAllScreen, $debugAllFile, $debugNokFile, $debug) = @_;

  my ($hostnameAdminCollector, undef) = split (/\./, $serverAdminCollectorFQDN, 2);
  return ('') if ( "CollectorCT-$collectorDaemon.sh" eq "CollectorCT-${hostnameAdminCollector}.sh" );

  my $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/CollectorCT-$collectorDaemon.sh";
  my $command  = "cat $APPLICATIONPATH/tools/templates/CollectorCT-template.sh >> $filename";

  my $rvOpen = open(CollectorCT, ">$filename");

  if ($rvOpen) {
    print CollectorCT <<STARTUPFILE;
#!/bin/bash
# ---------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ---------------------------------------------------------------
# This shell script takes care of starting and stopping

AMNAME=\"Collector ASNMTAP $collectorDaemon\"
AMPATH=$serverASNMTAP_PATH/applications
AMCMD=collector.pl
AMPARA=\"--hostname=$databaseFQDN --mode=$mode --collectorlist=CollectorCT-$collectorDaemon --dumphttp=$dumphttp --status=$status --debug=$debugDaemon --screenDebug=$debugAllScreen --allDebug=$debugAllFile --nokDebug=$debugNokFile\"
PIDPATH=$serverASNMTAP_PATH/pid
PIDNAME=CollectorCT-$collectorDaemon.pid

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

if [ -f "\$AMPATH/sbin/bash_stop_root.sh" ]; then
  source "\$AMPATH/sbin/bash_stop_root.sh"
fi

STARTUPFILE

    close (CollectorCT);
  }

  my $statusMessage = do_system_call ($command, $debug);
  $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/CollectorCT-$collectorDaemon.sh\" target=\"_blank\">CollectorCT-$collectorDaemon.sh ($subdir)</a></td></tr>";
  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createAsnmtapCollectorCTscript {
  my ($typeMonitoring, $typeServersCharMorS, $typeActiveServer, $serverFQDN, $serverAdminCollectorFQDN, $serverASNMTAP_PATH , $serverRSYNC_PATH , $serverSSH_PATH, $subdir, $debug) = @_;

  my $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';

  my $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/root-collector.sh";
  my $rvOpen = open(AsnmtapCollectorCTscript, ">$filename");

  if ($rvOpen) {
    print AsnmtapCollectorCTscript <<STARTUPFILE;
#!/bin/sh

su - $SSHLOGONNAME -c "cd $serverASNMTAP_PATH/applications/$subdir; ./asnmtap-collector.sh \$1"
exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
STARTUPFILE

    close (AsnmtapCollectorCTscript);
  }

  my $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/root-collector.sh\" target=\"_blank\">root-collector.sh ($subdir)</a></td></tr>";

  $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/asnmtap-collector.sh";
  $rvOpen = open(AsnmtapCollectorCTscript, ">$filename");

  if ($rvOpen) {
    print AsnmtapCollectorCTscript <<STARTUPFILE;
#!/bin/sh
# ---------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ---------------------------------------------------------------
# This shell script takes care of starting and stopping

AMNAME=\"All ASNMTAP Collectors\"
AMPATH=$serverASNMTAP_PATH/applications/$subdir

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STARTUPFILE

    foreach my $choise ('start', 'stop', 'reload', 'restart', 'status') {
      print AsnmtapCollectorCTscript <<STARTUPFILE;
$choise() {
  # $choise daemons
  echo "\u$choise: '\$AMNAME' ..."
  cd \$AMPATH
STARTUPFILE

      my ($hostname, undef) = split (/\./, $serverFQDN, 2);
      my ($hostnameAdminCollector, undef) = split (/\./, $serverAdminCollectorFQDN, 2);

      if ( $typeServersCharMorS eq $typeActiveServer or $choise eq 'stop' ) {
        foreach my $matchingAsnmtapCollectorCTscript (@matchingAsnmtapCollectorCTscript) {
          unless ( $matchingAsnmtapCollectorCTscript eq "CollectorCT-${hostnameAdminCollector}.sh" ) {
            print AsnmtapCollectorCTscript "  ./$matchingAsnmtapCollectorCTscript $choise\n"; 
          }
        }
      } else {
        print AsnmtapCollectorCTscript "  ./CollectorCT-${hostname}.sh $choise\n";
      }

      print AsnmtapCollectorCTscript <<STARTUPFILE;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STARTUPFILE
    }

    print AsnmtapCollectorCTscript <<STARTUPFILE;
# See how we were called.
case "\$1" in
  start)
           start
           ;;
  stop)
           stop
           ;;
  reload)
           reload
           ;;
  restart)
           restart
           ;;
  status)
           status
           ;;
  *)
           echo "Usage: '\$AMNAME' {start|stop|reload|restart|status}"
           exit 1
esac

exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
STARTUPFILE

    close (AsnmtapCollectorCTscript);
  }

  $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/asnmtap-collector.sh\" target=\"_blank\">asnmtap-collector.sh ($subdir)</a></td></tr>";
  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createDisplayCTscript {
  my ($typeMonitoringCharDorC, $typeServersCharMorS, $typeActiveServer, $serverFQDN, $serverASNMTAP_PATH , $serverRSYNC_PATH , $serverSSH_PATH, $databaseFQDN, $subdir, $displayDaemon, $pagedirs, $loop, $trigger, $displayTime, $lockMySQL, $debugDaemon, $debug) = @_;

  my $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/DisplayCT-$displayDaemon.sh";
  my $command  = "cat $APPLICATIONPATH/tools/templates/DisplayCT-template.sh >> $filename";

  my $rvOpen = open(DisplayCT, ">$filename");

  if ($rvOpen) {
    print DisplayCT <<STARTUPFILE;
#!/bin/bash
# ---------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ---------------------------------------------------------------
# This shell script takes care of starting and stopping

AMNAME=\"Display ASNMTAP $displayDaemon\"
AMPATH=$serverASNMTAP_PATH/applications
AMCMD=display.pl
AMPARA=\"--hostname=$databaseFQDN --checklist=DisplayCT-$displayDaemon --pagedir=$pagedirs --loop=$loop --trigger=$trigger --displayTime=$displayTime --lockMySQL=$lockMySQL --debug=$debugDaemon\"
PIDPATH=$serverASNMTAP_PATH/pid
PIDNAME=DisplayCT-$displayDaemon.pid
SOUNDCACHENAME=DisplayCT-$displayDaemon-sound-status.cache

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

if [ -f "\$AMPATH/sbin/bash_stop_root.sh" ]; then
  source "\$AMPATH/sbin/bash_stop_root.sh"
fi

STARTUPFILE

    close (DisplayCT);
  }

  my $statusMessage = do_system_call ($command, $debug);
  $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/DisplayCT-$displayDaemon.sh\" target=\"_blank\">DisplayCT-$displayDaemon.sh ($subdir)</a></td></tr>";
  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createAsnmtapDisplayCTscript {
  my ($typeMonitoring, $typeServersCharMorS, $typeActiveServer, $serverFQDN, $serverASNMTAP_PATH , $serverRSYNC_PATH , $serverSSH_PATH, $subdir, $debug) = @_;

  my $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';

  my $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/root-display.sh";
  my $rvOpen = open(AsnmtapDisplayCTscript, ">$filename");

  if ($rvOpen) {
    print AsnmtapDisplayCTscript <<STARTUPFILE;
#!/bin/sh

su - $SSHLOGONNAME -c "cd $serverASNMTAP_PATH/applications/$subdir; ./asnmtap-display.sh \$1"

exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
STARTUPFILE

    close (AsnmtapDisplayCTscript);
  }

  my $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/root-display.sh\" target=\"_blank\">root-display.sh ($subdir)</a></td></tr>";

  $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/asnmtap-display.sh";
  $rvOpen = open(AsnmtapDisplayCTscript, ">$filename");

  if ($rvOpen) {
    print AsnmtapDisplayCTscript <<STARTUPFILE;
#!/bin/sh
# ---------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ---------------------------------------------------------------
# This shell script takes care of starting and stopping

AMNAME=\"All ASNMTAP Displays\"
AMPATH=$serverASNMTAP_PATH/applications/$subdir

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STARTUPFILE

    foreach my $choise ('start', 'stop', 'reload', 'restart', 'status') {
      print AsnmtapDisplayCTscript <<STARTUPFILE;
$choise() {
  # $choise daemons
  echo "\u$choise: '\$AMNAME' ..."
  cd \$AMPATH
STARTUPFILE

      if ($typeServersCharMorS eq $typeActiveServer or $choise eq 'stop') {
        foreach my $matchingAsnmtapDisplayCTscript (@matchingAsnmtapDisplayCTscript) { print AsnmtapDisplayCTscript "  ./$matchingAsnmtapDisplayCTscript $choise\n"; }
      }

      print AsnmtapDisplayCTscript <<STARTUPFILE;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

STARTUPFILE
    }

    print AsnmtapDisplayCTscript <<STARTUPFILE;
# See how we were called.
case "\$1" in
  start)
           start
           ;;
  stop)
           stop
           ;;
  reload)
           reload
           ;;
  restart)
           restart
           ;;
  status)
           status
           ;;
  *)
           echo "Usage: '\$AMNAME' {start|stop|reload|restart|status}"
           exit 1
esac

exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
STARTUPFILE

    close (AsnmtapDisplayCTscript);
  }

  $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/$typeMonitoringCharDorC$typeServersCharMorS-$typeActiveServer-$serverFQDN/$subdir/asnmtap-display.sh\" target=\"_blank\">asnmtap-display.sh ($subdir)</a></td></tr>";
  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createRsyncMirrorScriptsFailover {
  my ($serverID, $typeMonitoring, $typeServers, $typeActiveServer, $masterFQDN, $masterASNMTAP_PATH, $masterRSYNC_PATH, $masterSSH_PATH, $slaveFQDN, $slaveASNMTAP_PATH, $slaveRSYNC_PATH, $slaveSSH_PATH, $collectorDaemon, $matchingRsyncMirrorConfigFailover, $debug) = @_;

  my $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';
  my ($filename, $command, $rvOpen);
  my $statusMessage = '';

  if ( $typeServers ) {                                        # Failover
    # --------------------------------------------------------------------------
    # Failover between $masterFQDN and $slaveFQDN
    # --------------------------------------------------------------------------
    $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/master/rsync-wrapper-failover-$masterFQDN.sh";

    unless ( -e $filename ) {
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Failover between $masterFQDN and $slaveFQDN</td></tr>";
      $command  = "cat $APPLICATIONPATH/tools/templates/master/rsync-wrapper-failover-template.sh >> $filename";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
#!/usr/bin/env perl
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-wrapper-failover.sh for asnmtap, v$version, wrapper script for rsync
#   execution via ssh key for use with rsync-mirror-failover.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $masterASNMTAP_PATH/applications/tools/templates/master/rsync-wrapper-failover-example.sh
#   $masterASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-failover-example.sh
#   $masterASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-failover-example.conf
# ------------------------------------------------------------------------------

use strict;

# Chroot Dir
my \$chrootDir = ( \$ENV{ASNMTAP_PATH} ? \$ENV{ASNMTAP_PATH} : '$masterASNMTAP_PATH' ) . '/results/';

# Where to log successes and failures to set to /dev/null to turn off logging.
my \$filename = ( \$ENV{ASNMTAP_PATH} ? \$ENV{ASNMTAP_PATH} : '$masterASNMTAP_PATH' ) . '/log/rsync-wrapper-failover-$masterFQDN.log';

# What you want sent if access is denied.
my \$denyString = 'Access Denied! Sorry';

# The real path of rsync.
my \$rsyncPath = '$masterRSYNC_PATH/rsync'; # master

# 1 = rsync version 2.6.7 or higher or 0 = otherwise
my \$rsync_version_2_6_7_or_higher = 1;

# 1 = 'capture_exec("\$system_action")' or 0 = 'system ("\$system_action")'
my \$captureOutput = $CAPTUREOUTPUT;

RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= do_system_call ($command, $debug);
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/master/rsync-wrapper-failover-$masterFQDN.sh\" target=\"_blank\">rsync-wrapper-failover-$masterFQDN.sh (master)</a></td></tr>";
    }

    $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Failover Monitoring from $slaveFQDN for Collector Daemon '$collectorDaemon'</td></tr>";

    my ($hostnameAdminCollector, undef) = split (/\./, $slaveFQDN, 2);

    if ( $collectorDaemon eq $hostnameAdminCollector ) {
      # ------------------------------------------------------------------------
      # Failover between $slaveFQDN and $masterFQDN
      # ------------------------------------------------------------------------
      $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave/rsync-wrapper-failover-$slaveFQDN.sh";

      unless ( -e $filename ) {
        $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Failover between $slaveFQDN and $masterFQDN</td></tr>";
        $command  = "cat $APPLICATIONPATH/tools/templates/master/rsync-wrapper-failover-template.sh >> $filename";

        $rvOpen = open(RsyncMirror, ">$filename");

        if ($rvOpen) {
          print RsyncMirror <<RSYNCMIRRORFILE;
#!/usr/bin/env perl
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-wrapper-failover.sh for asnmtap, v$version, wrapper script for rsync
#   execution via ssh key for use with rsync-mirror-failover.sh
# ------------------------------------------------------------------------------

use strict;

# Chroot Dir
my \$chrootDir = ( \$ENV{ASNMTAP_PATH} ? \$ENV{ASNMTAP_PATH} : '$slaveASNMTAP_PATH' ) . '/results/';

# Where to log successes and failures to set to /dev/null to turn off logging.
my \$filename = ( \$ENV{ASNMTAP_PATH} ? \$ENV{ASNMTAP_PATH} : '$slaveASNMTAP_PATH' ) . '/log/rsync-wrapper-failover-$slaveFQDN.log';

# What you want sent if access is denied.
my \$denyString = 'Access Denied! Sorry';

# The real path of rsync.
my \$rsyncPath = '$slaveRSYNC_PATH/rsync'; # slave

# 1 = rsync version 2.6.7 or higher or 0 = otherwise
my \$rsync_version_2_6_7_or_higher = 1;

# 1 = 'capture_exec("\$system_action")' or 0 = 'system ("\$system_action")'
my \$captureOutput = $CAPTUREOUTPUT;

RSYNCMIRRORFILE

          close (RsyncMirror);
        }

        $statusMessage .= do_system_call ($command, $debug);
        $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave/rsync-wrapper-failover-$slaveFQDN.sh\" target=\"_blank\">rsync-wrapper-failover-$slaveFQDN.sh (slave)</a></td></tr>";
      }

      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Failover Monitoring from $masterFQDN for Admin Collector Daemon '$collectorDaemon'</td></tr>";

      my ($hostnameAdminCollector, undef) = split (/\./, $slaveFQDN, 2);
      return ($statusMessage) unless ( $collectorDaemon eq $hostnameAdminCollector );

      $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/master/rsync-mirror-failover-$masterFQDN-$collectorDaemon.sh";
      $command  = "cat $APPLICATIONPATH/tools/templates/slave/rsync-mirror-failover-template.sh >> $filename";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
#!/bin/bash
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-mirror-failover.sh for asnmtap, v$version, mirror script for rsync
#   execution via ssh key for use with rsync-wrapper-failover.sh
# ------------------------------------------------------------------------------

RMVersion='$RMVERSION'
echo "rsync-mirror-failover-$masterFQDN-$collectorDaemon.sh version \$RMVersion"

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

if [ ! "\$ASNMTAP_PATH" ]; then
  ASNMTAP_PATH=$masterASNMTAP_PATH
fi

PidPath="\$ASNMTAP_PATH/pid"
Rsync=$masterRSYNC_PATH/rsync                   # master
RsyncPath=$slaveRSYNC_PATH/rsync                # remote server
KeyRsync=$SSHKEYPATH/$SSHLOGONNAME/.ssh/$RSYNCIDENTITY
ConfFile=rsync-mirror-failover-$masterFQDN-$collectorDaemon.conf
ConfPath="\$ASNMTAP_PATH/applications/master"
Delete=' '
# AdditionalParams=''                            # --numeric-ids, -H, -v and -R
Reverse=no                                       # 'yes' -> from master to slave
                                                 # 'no'  -> from slave to master

RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= do_system_call ($command, $debug);
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/master/rsync-mirror-failover-$masterFQDN-$collectorDaemon.sh\" target=\"_blank\">rsync-mirror-failover-$masterFQDN-$collectorDaemon.sh (master)</a></td></tr>";

      $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/master/rsync-mirror-failover-$masterFQDN-$collectorDaemon.conf";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
# ------------------------------------------------------------------------------
# Copyright $COPYRIGHT Alex Peeters [alex.peeters\\\@citap.be]
# ------------------------------------------------------------------------------

$matchingRsyncMirrorConfigFailover
RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/master/rsync-mirror-failover-$masterFQDN-$collectorDaemon.conf\" target=\"_blank\">rsync-mirror-failover-$masterFQDN-$collectorDaemon.conf (master)</a></td></tr>";
      return ($statusMessage);
	}

    $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave/rsync-mirror-failover-$slaveFQDN-$collectorDaemon.sh";
    $command  = "cat $APPLICATIONPATH/tools/templates/slave/rsync-mirror-failover-template.sh >> $filename";

    $rvOpen = open(RsyncMirror, ">$filename");

    if ($rvOpen) {
      print RsyncMirror <<RSYNCMIRRORFILE;
#!/bin/bash
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-mirror-failover.sh for asnmtap, v$version, mirror script for rsync
#   execution via ssh key for use with rsync-wrapper-failover.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $slaveASNMTAP_PATH/applications/tools/templates/master/rsync-wrapper-failover-example.sh
#   $slaveASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-failover-example.sh
#   $slaveASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-failover-example.conf
# ------------------------------------------------------------------------------

RMVersion='$RMVERSION'
echo "rsync-mirror-failover-$slaveFQDN-$collectorDaemon.sh version \$RMVersion"

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

if [ ! "\$ASNMTAP_PATH" ]; then
  ASNMTAP_PATH=$slaveASNMTAP_PATH
fi

PidPath="\$ASNMTAP_PATH/pid"
Rsync=$slaveRSYNC_PATH/rsync                     # slave
RsyncPath=$masterRSYNC_PATH/rsync                # remote server
KeyRsync=$SSHKEYPATH/$SSHLOGONNAME/.ssh/$RSYNCIDENTITY
ConfFile=rsync-mirror-failover-$slaveFQDN-$collectorDaemon.conf
ConfPath="\$ASNMTAP_PATH/applications/slave"
Delete=' --delete --delete-after '
# AdditionalParams=''                            # --numeric-ids, -H, -v and -R
Reverse=no                                       # 'yes' -> from slave to master
                                                 # 'no'  -> from master to slave

RSYNCMIRRORFILE

      close (RsyncMirror);
    }

    $statusMessage .= do_system_call ($command, $debug);
    $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave/rsync-mirror-failover-$slaveFQDN-$collectorDaemon.sh\" target=\"_blank\">rsync-mirror-failover-$slaveFQDN-$collectorDaemon.sh (slave)</a></td></tr>";

    $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave/rsync-mirror-failover-$slaveFQDN-$collectorDaemon.conf";

    $rvOpen = open(RsyncMirror, ">$filename");

    if ($rvOpen) {
      print RsyncMirror <<RSYNCMIRRORFILE;
# ------------------------------------------------------------------------------
# Copyright $COPYRIGHT Alex Peeters [alex.peeters\\\@citap.be]
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $slaveASNMTAP_PATH/applications/tools/templates/master/rsync-wrapper-failover-example.sh
#   $slaveASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-failover-example.sh
#   $slaveASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-failover-example.conf
# ------------------------------------------------------------------------------

$matchingRsyncMirrorConfigFailover
RSYNCMIRRORFILE

      if ( $collectorDaemon eq 'test' ) {
        print RsyncMirror <<RSYNCMIRRORFILE;
# ------------------------------------------------------------------------------

$SSHLOGONNAME\@$masterFQDN:$masterASNMTAP_PATH/plugins/ $slaveASNMTAP_PATH/plugins/ -v -c -z

# ------------------------------------------------------------------------------
RSYNCMIRRORFILE
      }

      close (RsyncMirror);
    }

    $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave/rsync-mirror-failover-$slaveFQDN-$collectorDaemon.conf\" target=\"_blank\">rsync-mirror-failover-$slaveFQDN-$collectorDaemon.conf (slave)</a></td></tr>";
  }

  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub createRsyncMirrorScriptsDistributed {
  my ($serverID, $typeMonitoring, $typeServers, $typeActiveServer, $masterFQDN, $masterASNMTAP_PATH, $masterRSYNC_PATH, $masterSSH_PATH, $slaveFQDN, $slaveASNMTAP_PATH, $slaveRSYNC_PATH, $slaveSSH_PATH, $centralTypeMonitoring, $centralTypeServers, $centralTypeActiveServer, $centralMasterFQDN, $centralMasterASNMTAP_PATH, $centralMasterRSYNC_PATH, $centralMasterSSH_PATH, $centralSlaveFQDN, $centralSlaveASNMTAP_PATH, $centralSlaveRSYNC_PATH, $centralSlaveSSH_PATH, $collectorDaemon, $matchingRsyncMirrorConfigDistributedMaster, $matchingRsyncMirrorConfigDistributedSlave, $debug) = @_;

  my $typeMonitoringCharDorC = ($typeMonitoring) ? 'D' : 'C';

  my ($filename, $command, $rvOpen);
  my $statusMessage = '';

  if ( $typeMonitoring ) {                                 # Distributed
    $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CM-$centralTypeActiveServer-$centralMasterFQDN/master/rsync-wrapper-distributed-$centralMasterFQDN.sh";

    unless ( -e $filename ) {
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Distributed Monitoring destination $centralMasterFQDN</td></tr>";
      $command  = "cat $APPLICATIONPATH/tools/templates/master/rsync-wrapper-distributed-template.sh >> $filename";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
#!/usr/bin/env perl
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-wrapper-distributed.sh for asnmtap, v$version, wrapper script for rsync
#   execution via ssh key for use with rsync-mirror-distributed.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $centralMasterASNMTAP_PATH/applications/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $centralMasterASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $centralMasterASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

use strict;

# Chroot Dir
my \$chrootDir = ( \$ENV{ASNMTAP_PATH} ? \$ENV{ASNMTAP_PATH} : '$centralMasterASNMTAP_PATH' ) . '/results/';

# Where to log successes and failures to set to /dev/null to turn off logging.
my \$filename = ( \$ENV{ASNMTAP_PATH} ? \$ENV{ASNMTAP_PATH} : '$centralMasterASNMTAP_PATH' ) . '/log/rsync-wrapper-distributed-$centralMasterFQDN.log';

# What you want sent if access is denied.
my \$denyString = 'Access Denied! Sorry';

# The real path of rsync.
my \$rsyncPath = '$centralMasterRSYNC_PATH/rsync'; # central master

# 1 = rsync version 2.6.7 or higher or 0 = otherwise
my \$rsync_version_2_6_7_or_higher = 1;

# 1 = 'capture_exec("\$system_action")' or 0 = 'system ("\$system_action")'
my \$captureOutput = $CAPTUREOUTPUT;

RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= do_system_call ($command, $debug);
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/CM-$centralTypeActiveServer-$centralMasterFQDN/master/rsync-wrapper-distributed-$centralMasterFQDN.sh\" target=\"_blank\">rsync-wrapper-distributed-$centralMasterFQDN.sh (master)</a></td></tr>" if ( defined $centralSlaveFQDN and $centralSlaveFQDN );
    }

    if ( $centralTypeServers == $centralTypeServers ) {
      if ( defined $centralSlaveFQDN and $centralSlaveFQDN ) {
        $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/CS-$centralTypeActiveServer-$centralSlaveFQDN/master/rsync-wrapper-distributed-$centralSlaveFQDN.sh";

        unless ( -e $filename ) {
          $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Distributed Monitoring destination $centralSlaveFQDN</td></tr>";
          $command  = "cat $APPLICATIONPATH/tools/templates/master/rsync-wrapper-distributed-template.sh >> $filename";

          $rvOpen = open(RsyncMirror, ">$filename");

          if ($rvOpen) {
            print RsyncMirror <<RSYNCMIRRORFILE;
#!/usr/bin/env perl
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-wrapper-distributed.sh for asnmtap, v$version, wrapper script for rsync
#   execution via ssh key for use with rsync-mirror-distributed.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $centralSlaveASNMTAP_PATH/applications/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $centralSlaveASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $centralSlaveASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

use strict;

# Chroot Dir
my \$chrootDir = ( \$ENV{ASNMTAP_PATH} ? \$ENV{ASNMTAP_PATH} : '$centralSlaveASNMTAP_PATH' ) . '/results/';

# Where to log successes and failures to set to /dev/null to turn off logging.
my \$filename = ( \$ENV{ASNMTAP_PATH} ? \$ENV{ASNMTAP_PATH} : '$centralSlaveASNMTAP_PATH' ) . '/log/rsync-wrapper-distributed-$centralSlaveFQDN.log';

# What you want sent if access is denied.
my \$denyString = 'Access Denied! Sorry';

# The real path of rsync.
my \$rsyncPath = '$centralSlaveRSYNC_PATH/rsync'; # central slave

# 1 = rsync version 2.6.7 or higher or 0 = otherwise
my \$rsync_version_2_6_7_or_higher = 1;

# 1 = 'capture_exec("\$system_action")' or 0 = 'system ("\$system_action")'
my \$captureOutput = $CAPTUREOUTPUT;

RSYNCMIRRORFILE

            close (RsyncMirror);
          }

          $statusMessage .= do_system_call ($command, $debug);
          $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/CS-$centralTypeActiveServer-$centralSlaveFQDN/master/rsync-wrapper-distributed-$centralSlaveFQDN.sh\" target=\"_blank\">rsync-wrapper-distributed-$centralSlaveFQDN.sh (master)</a></td></tr>";
        }
      }

      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Distributed Monitoring from $masterFQDN for Collector Daemon '$collectorDaemon'</td></tr>";
      $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/slave/rsync-mirror-distributed-$masterFQDN-$collectorDaemon.sh";
      $command  = "cat $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-template.sh >> $filename";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
#!/bin/bash
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-mirror-distributed.sh for asnmtap, v$version, mirror script for rsync
#   execution via ssh key for use with rsync-wrapper-distributed.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $masterASNMTAP_PATH/applications/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $masterASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $masterASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

RMVersion='$RMVERSION'
echo "rsync-mirror-distributed-$masterFQDN-$collectorDaemon.sh version \$RMVersion"

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

if [ ! "\$ASNMTAP_PATH" ]; then
  ASNMTAP_PATH=$masterASNMTAP_PATH
fi

PidPath="\$ASNMTAP_PATH/pid"
Rsync=$masterRSYNC_PATH/rsync                    # master
RsyncPath=$centralMasterRSYNC_PATH/rsync         # remote server
KeyRsync=$SSHKEYPATH/$SSHLOGONNAME/.ssh/$RSYNCIDENTITY
ConfFile=rsync-mirror-distributed-$masterFQDN-$collectorDaemon.conf
ConfPath="\$ASNMTAP_PATH/applications/slave"
Delete=''
# AdditionalParams=''                            # --numeric-ids, -H, -v and -R
Reverse=no                                       # 'yes' -> from slave to master
                                                 # 'no'  -> from master to slave

RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= do_system_call ($command, $debug);
    }

    $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/slave/rsync-mirror-distributed-$masterFQDN-$collectorDaemon.sh\" target=\"_blank\">rsync-mirror-distributed-$masterFQDN-$collectorDaemon.sh (slave)</a></td></tr>";

    $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/slave/rsync-mirror-distributed-$masterFQDN-$collectorDaemon.conf";

    $rvOpen = open(RsyncMirror, ">$filename");

    if ($rvOpen) {
      print RsyncMirror <<RSYNCMIRRORFILE;
# ------------------------------------------------------------------------------
# Copyright $COPYRIGHT Alex Peeters [alex.peeters\\\@citap.be]
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $masterASNMTAP_PATH/applications/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $masterASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $masterASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

$matchingRsyncMirrorConfigDistributedMaster
# ------------------------------------------------------------------------------
RSYNCMIRRORFILE

      close (RsyncMirror);
    }

    $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "M-$typeActiveServer-$masterFQDN/slave/rsync-mirror-distributed-$masterFQDN-$collectorDaemon.conf\" target=\"_blank\">rsync-mirror-distributed-$masterFQDN-$collectorDaemon.conf (slave)</a></td></tr>";

    if ( $typeServers ) {
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>Distributed Monitoring from $slaveFQDN for Collector Daemon '$collectorDaemon'</td></tr>";
      $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave/rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.sh";
      $command  = "cat $APPLICATIONPATH/tools/templates/slave/rsync-mirror-distributed-template.sh >> $filename";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
#!/bin/bash
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# rsync-mirror-distributed.sh for asnmtap, v$version, mirror script for rsync
#   execution via ssh key for use with rsync-wrapper-distributed.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $slaveASNMTAP_PATH/applications/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $slaveASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $slaveASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

RMVersion='$RMVERSION'
echo "rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.sh version \$RMVersion"

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

if [ ! "\$ASNMTAP_PATH" ]; then
  ASNMTAP_PATH=$slaveASNMTAP_PATH
fi

PidPath="\$ASNMTAP_PATH/pid"
Rsync=$slaveRSYNC_PATH/rsync                     # slave
RsyncPath=$centralMasterRSYNC_PATH/rsync         # remote server
KeyRsync=$SSHKEYPATH/$SSHLOGONNAME/.ssh/$RSYNCIDENTITY
ConfFile=rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.conf
ConfPath="\$ASNMTAP_PATH/applications/slave"
Delete=''
# AdditionalParams=''                            # --numeric-ids, -H, -v and -R
Reverse=no                                       # 'yes' -> from slave to master
                                                 # 'no'  -> from master to slave

RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= do_system_call ($command, $debug);
      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave/rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.sh\" target=\"_blank\">rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.sh (slave)</a></td></tr>";
      $filename = "$APPLICATIONPATH/tmp/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave/rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.conf";

      $rvOpen = open(RsyncMirror, ">$filename");

      if ($rvOpen) {
        print RsyncMirror <<RSYNCMIRRORFILE;
# ------------------------------------------------------------------------------
# © Copyright $COPYRIGHT Alex Peeters [alex.peeters\@citap.be]
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
#   $slaveASNMTAP_PATH/applications/tools/templates/master/rsync-wrapper-distributed-example.sh
#   $slaveASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.sh
#   $slaveASNMTAP_PATH/applications/tools/templates/slave/rsync-mirror-distributed-example.conf
# ------------------------------------------------------------------------------

$matchingRsyncMirrorConfigDistributedSlave
# ------------------------------------------------------------------------------
RSYNCMIRRORFILE

        close (RsyncMirror);
      }

      $statusMessage .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><a href=\"/$CONFIGDIR/generated/" .$typeMonitoringCharDorC. "S-$typeActiveServer-$slaveFQDN/slave/rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.conf\" target=\"_blank\">rsync-mirror-distributed-$slaveFQDN-$collectorDaemon.conf (slave)</a></td></tr>";
    }
  }

  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub read_directory {
  my ($directory, $subDirectory, $htmlBefore, $htmlAfter, $debug) = @_;

  my $directoryAndFileList = ( $debug eq 'T' ) ? "$htmlBefore$directory$subDirectory$htmlAfter" : '';

  my $rvOpendir = opendir (DIR, "$directory$subDirectory");

  if ($rvOpendir) {
    while ($_ = readdir (DIR)) {
      next if ($_ eq "." or $_ eq ".." or $_ eq "HEADER.html" or $_ eq "FOOTER.html");

      if (-d "$directory$subDirectory/$_") {
        $directoryAndFileList .= read_directory("$directory", "$subDirectory/$_", $htmlBefore, $htmlAfter, $debug);
      } else {
        $directoryAndFileList .= "$htmlBefore$subDirectory/$_$htmlAfter";
      }
    }

    closedir DIR;
  }

  return ($directoryAndFileList);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub do_compare_view {
  my ($command, $details, $debug) = @_;

  sub do_compare_diff {
    my ($compareView, $type, $details, $debug) = @_;

    my ($path, $generated, $installed, $compareDiff);
    $path = $generated = $installed = '';

    if ($type == 1) {
      my (undef, $dummy) = split (/Only in generated\//, $compareView);
      ($path, $generated) = split (/: /, $dummy);
      $compareDiff = "$path/$generated added" if ( $debug eq 'T' );
    } elsif ($type == 2) {
      my (undef, $dummy) = split (/Only in installed\//, $compareView);
      ($path, $installed) = split (/: /, $dummy);
      $compareDiff = "$path/$installed removed" if ( $debug eq 'T' );
    } elsif ($type == 3) {
      my (undef, $dummy) = split (/Files /, $compareView);
      ($generated, $dummy) = split (/ and /, $dummy);
      ($installed, undef) = split (/ differ/, $dummy);
      $compareDiff = "$generated and $installed differ<BR>" if ( $debug eq 'T' );

      if ($details) {
        my $command = "$DIFFCOMMAND -bra -I 'generated on 20[0-9][0-9]/[0-9][0-9]/[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]' $APPLICATIONPATH/tmp/$CONFIGDIR/$generated $APPLICATIONPATH/tmp/$CONFIGDIR/$installed";
        my @compareDiff = `$command 2>&1`;
        foreach my $compareLine (@compareDiff) { $compareDiff .= "$compareLine<BR>"; };
      }
    }

    return ($path, $generated, $installed, $compareDiff);
  }

  my $statusMessage = '';

  my @compareView = `$command 2>&1`;

  my %commands;
  my $_id = 0;
  my $connectArguments = "-o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=$WWWKEYPATH/.ssh/known_hosts' -i '$WWWKEYPATH/.ssh/$SSHIDENTITY'";

  foreach my $compareView (@compareView) {
    chomp ($compareView);
    $compareView =~ s/^\s+//g;
    $compareView =~ s/$APPLICATIONPATH\/tmp\/$CONFIGDIR\///g;

    if ($compareView ne '') {
      my ($type, $activeServer, $server, $path, $subpath, $generated, $installed, $compareDiff, $compareText);
      my $todo = $type = 0;

      if ( $compareView =~ /^Only in generated\// ) {
        ($path, $generated, $installed, $compareDiff) = do_compare_diff ($compareView, 1, $details, $debug);

        if ($details) {
          $compareText = "File '$path/$generated' added to the generated configuration.";
        } else {
          ($type, $activeServer, $server) = split (/-/, $path, 3);
          my $active = ( ( $type =~ /^[CD]${activeServer}$/ ) ? 1 : 0 );

          ($server, $subpath) = split (/\//, $server, 2);
          $subpath .= ($subpath eq '') ? '' : '/';
          # Copy '/opt/asnmtap/applications/tmp/$CONFIGDIR/generated/DM-[MS]-distributed.citap.com/etc/DisplayCT-distributed' to 'distributed.citap.com:/opt/asnmtap/applications/etc/DisplayCT-distributed'
          #       $APPLICATIONPATH/tmp/      /generated/<------- $path -------->/<--- $generated ---->      <----- $server ----->:$APPLICATIONPATH/<---- $generated --->
          # or
          # Copy '/opt/asnmtap/applications/tmp/$CONFIGDIR/generated/CM-[MS]-asnmtap.citap.be/master/CollectorCT-index.sh' to 'asnmtap.citap.be:/opt/asnmtap/applications/master/CollectorCT-index.sh'
          #       $APPLICATIONPATH/tmp/      /generated/<------- $path -------->/<----------------- $generated ---------------->      <------ $server ----->:$APPLICATIONPATH/$subpath/<------------ $generated ----------->
          $commands {$server} {SCP} {++$_id} {auto} = 1;
          $commands {$server} {SCP} {$_id} {label} = '+a';
          $commands {$server} {SCP} {$_id} {active} = $active;
          $commands {$server} {SCP} {$_id} {command} = "$SCPCOMMAND $connectArguments $APPLICATIONPATH/tmp/$CONFIGDIR/generated/$path/$generated $SSHLOGONNAME\@$server:". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } ."/applications/$subpath$generated";
          $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {SCP} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

		  if (($generated =~ /^DisplayCT-[\w-]+.sh$/) or ($generated =~ /^CollectorCT-[\w-]+.sh$/)) {
            $commands {$server} {CHMOD} {++$_id} {auto} = 1;
            $commands {$server} {CHMOD} {$_id} {label} = '+b';
            $commands {$server} {CHMOD} {$_id} {active} = $active;
            $commands {$server} {CHMOD} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server chmod 755 ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } ."/applications/$subpath$generated";
            $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {CHMOD} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

            $commands {$server} {START} {++$_id} {auto} = 1;
            $commands {$server} {START} {$_id} {label} = '+c';
            $commands {$server} {START} {$_id} {active} = $active;
            $commands {$server} {START} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } ."/applications/$subpath$generated start";
            $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {START} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
          } elsif (($generated =~ /rsync-wrapper-distributed-[\w\-.]+.sh$/) or ($generated =~ /rsync-wrapper-failover-[\w\-.]+.sh$/)) {
            $commands {$server} {TODO} {++$_id} {auto} = 0;
            $commands {$server} {TODO} {$_id} {label} = '+d';
            $commands {$server} {TODO} {$_id} {active} = $active;
            $commands {$server} {TODO} {$_id} {command} = "'$generated' ?";
            $compareText .= '<br><FONT COLOR="yellow"> ['. $_id .'] '. $commands {$server} {TODO} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
            $todo = 1;
          } elsif (($generated =~ /rsync-mirror-failover-[\w\-.]+.sh$/) or ($generated =~ /rsync-mirror-distributed-[\w\-.]+.sh$/)) {
            $commands {$server} {TODO} {++$_id} {auto} = 0;
            $commands {$server} {TODO} {$_id} {label} = '+e';
            $commands {$server} {TODO} {$_id} {active} = $active;
            $commands {$server} {TODO} {$_id} {command} = "Add 'n-59/5 * * * * $APPLICATIONPATH/$path/$generated > /dev/null' to crontab ?";
            $compareText .= '<br><FONT COLOR="yellow"> ['. $_id .'] '. $commands {$server} {TODO} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
            $todo = 1;
          }
        }
      } elsif ( $compareView =~ /^Only in generated:/ ) {
        if ($details) {
          $compareText = "$compareView";
        } else {
          my (undef, $servername) = split (/: /, $compareView, 2);
          ($type, $activeServer, $server) = split (/-/, $servername, 3);
          my $active = ( ( $type =~ /^[CD]${activeServer}$/ ) ? 1 : 0 );

          $commands {$server} {SCP} {++$_id} {auto} = 1;
          $commands {$server} {SCP} {$_id} {label} = '+f';
          $commands {$server} {SCP} {$_id} {active} = $active;
          $commands {$server} {SCP} {$_id} {command} = "$SCPCOMMAND $connectArguments $APPLICATIONPATH/tmp/$CONFIGDIR/generated/$servername $SSHLOGONNAME\@$server ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications';
          $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {SCP} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

          $commands {$server} {TODO} {++$_id} {auto} = 0;
          $commands {$server} {TODO} {$_id} {label} = '+g';
          $commands {$server} {TODO} {$_id} {active} = $active;
          $commands {$server} {TODO} {$_id} {command} = read_directory ("$APPLICATIONPATH/tmp/$CONFIGDIR/generated/$servername", '', '', '<br>', $debug) ." ?";
          $compareText .= '<br><FONT COLOR="yellow"> ['. $_id .'] '. $commands {$server} {TODO} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

		  if ($type =~ /^[CD]${activeServer}$/) {
            $commands {$server} {TODO} {++$_id} {auto} = 0;
            $commands {$server} {TODO} {$_id} {label} = '+h';
            $commands {$server} {TODO} {$_id} {active} = $active;
            $commands {$server} {TODO} {$_id} {command} = "Now 'DisplayCT-*.sh start' and 'CollectorCT-*.sh start' and add 'rsync-mirror-*.sh' to crontab '$compareView' ?";
            $compareText .= '<br><FONT COLOR="yellow"> ['. $_id .'] '. $commands {$server} {TODO} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
          } else {
            $commands {$server} {TODO} {++$_id} {auto} = 0;
            $commands {$server} {TODO} {$_id} {label} = '+i';
            $commands {$server} {TODO} {$_id} {active} = $active;
            $commands {$server} {TODO} {$_id} {command} = "Now add 'rsync-mirror-*.sh' to crontab '$compareView' ?";
            $compareText .= '<br><FONT COLOR="yellow"> ['. $_id .'] '. $commands {$server} {TODO} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
          }

		  $todo = 1;
        }
      } elsif ( $compareView =~ /^Only in installed\// ) {
        ($path, $generated, $installed, $compareDiff) = do_compare_diff ($compareView, 2, $details, $debug);

        if ($details) {
          $compareText = "File '$path/$installed' removed from the generated configuration.";
        } else {
          my ($servername, $directory) = split (/\//, $path, 2);
          ($type, $activeServer, $server) = split (/-/, $servername, 3);
          my $active = ( ( $type =~ /^[CD]${activeServer}$/ ) ? 1 : 0 );

		  if (($installed =~ /^DisplayCT-[\w-]+.sh$/) or ($installed =~ /^CollectorCT-[\w-]+.sh$/)) {
            $commands {$server} {STOP} {++$_id} {auto} = 0;
            $commands {$server} {STOP} {$_id} {label} = '-a';
            $commands {$server} {STOP} {$_id} {active} = $active;
            $commands {$server} {STOP} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications'. ( (defined $directory) ? "/$directory" : '' ) ."/$installed stop";
            $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {STOP} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
          } elsif ((($type eq 'CS' or $type eq 'DS') and ($installed =~ /^rsync-mirror-failover-[\w\-.]+.sh$/))
                or (($type eq 'DM' or $type eq 'DS') and ($installed =~ /^rsync-mirror-distributed-[\w\-.]+.sh$/))) {
            $commands {$server} {CRONTAB} {++$_id} {auto} = 0;
            $commands {$server} {CRONTAB} {$_id} {label} = '-b';
            $commands {$server} {CRONTAB} {$_id} {active} = $active;
            $commands {$server} {CRONTAB} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server DELETE ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications'. ( (defined $directory) ? "/$directory" : '' ) ."/$installed";
            $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {CRONTAB} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

          # my ($installedConf, undef) = split (/.sh/, $installed);
          # $commands {$server} {REMOVE} {++$_id} {auto} = 0;
          # $commands {$server} {REMOVE} {$_id} {label} = '-c';
          # $commands {$server} {REMOVE} {$_id} {active} = $active;
          # $commands {$server} {REMOVE} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server rm ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications'. ( (defined $directory) ? "/$directory" : '' ) ."/$installedConf.conf";
          # $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {REMOVE} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
            $todo = 1;
          } elsif ((($type eq 'CM' or $type eq 'DM') and ($installed =~ /^rsync-wrapper-failover-[\w\-.]+.sh$/))
                or (($type eq 'CM' or $type eq 'CS') and ($installed =~ /^rsync-wrapper-distributed-[\w\-.]+.sh$/))) {
            $commands {$server} {TODO} {++$_id} {auto} = 0;
            $commands {$server} {TODO} {$_id} {label} = '-d';
            $commands {$server} {TODO} {$_id} {active} = $active;
            $commands {$server} {TODO} {$_id} {command} = "'$installed' ?";
            $compareText .= '<br><FONT COLOR="yellow"> ['. $_id .'] '. $commands {$server} {TODO} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
            $todo = 1;
          } else {
            $commands {$server} {TODO} {++$_id} {auto} = 0;
            $commands {$server} {TODO} {$_id} {label} = '-e';
            $commands {$server} {TODO} {$_id} {active} = $active;
            $commands {$server} {TODO} {$_id} {command} = "UNKNOWN '$path' ?";
            $compareText .= '<br><FONT COLOR="yellow"> ['. $_id .'] '. $commands {$server} {TODO} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
          }

          # Remove 'distributed.citap.com:/opt/asnmtap/applications/etc/DisplayCT-distributed-magweg'
          #         <----- $server ----->:$APPLICATIONPATH/<------- $installed ------->
          $commands {$server} {REMOVE} {++$_id} {auto} = 1;
          $commands {$server} {REMOVE} {$_id} {label} = '-f';
          $commands {$server} {REMOVE} {$_id} {active} = $active;
          $commands {$server} {REMOVE} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server rm ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications'. ( (defined $directory) ? "/$directory" : '' ) ."/$installed";
          $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {REMOVE} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
        }
      } elsif ( $compareView =~ /^Only in installed:/ ) {
        if ($details) {
          $compareText = "$compareView";
        } else {
          my (undef, $servername) = split (/: /, $compareView, 2);
          ($type, $activeServer, $server) = split (/-/, $servername, 3);
          my $active = ( ( $type =~ /^[CD]${activeServer}$/ ) ? 1 : 0 );

          $commands {$server} {TODO} {++$_id} {auto} = 0;
          $commands {$server} {TODO} {$_id} {label} = '-g';
          $commands {$server} {TODO} {$_id} {active} = $active;
          $commands {$server} {TODO} {$_id} {command} = read_directory ("$APPLICATIONPATH/tmp/$CONFIGDIR/installed", '', '', '', $debug) ." ?";
          $compareText .= '<br><FONT COLOR="yellow"> ['. $_id .'] '. $commands {$server} {TODO} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

          $commands {$server} {STOP} {++$_id} {auto} = 0;
          $commands {$server} {STOP} {$_id} {label} = '-h';
          $commands {$server} {STOP} {$_id} {active} = $active;
          $commands {$server} {STOP} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications/'. ( ($type eq 'CM' or $type eq 'DM') ? 'master' : 'slave' ) ."/asnmtap-collector.sh stop";
          $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {STOP} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

          $commands {$server} {REMOVE} {++$_id} {auto} = 0;
          $commands {$server} {REMOVE} {$_id} {label} = '-i';
          $commands {$server} {REMOVE} {$_id} {active} = $active;
          $commands {$server} {REMOVE} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server rm ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications/'. ( ($type eq 'CM' or $type eq 'DM') ? 'master' : 'slave' ) ."/CollectorCT-*";
          $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {REMOVE} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

          $commands {$server} {STOP} {++$_id} {auto} = 0;
          $commands {$server} {STOP} {$_id} {label} = '-j';
          $commands {$server} {STOP} {$_id} {active} = $active;
          $commands {$server} {STOP} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications/'. ( ($type eq 'CM' or $type eq 'DM') ? 'master' : 'slave' ) ."/asnmtap-display.sh stop";
          $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {STOP} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

          $commands {$server} {REMOVE} {++$_id} {auto} = 0;
          $commands {$server} {REMOVE} {$_id} {label} = '-k';
          $commands {$server} {REMOVE} {$_id} {active} = $active;
          $commands {$server} {REMOVE} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server rm ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications/'. ( ($type eq 'CM' or $type eq 'DM') ? 'master' : 'slave' ) ."/DisplayCT-*";
          $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {REMOVE} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

          $commands {$server} {CRONTAB} {++$_id} {auto} = 0;
          $commands {$server} {CRONTAB} {$_id} {label} = '-l';
          $commands {$server} {CRONTAB} {$_id} {active} = $active;
          $commands {$server} {CRONTAB} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server DELETE ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications/'. ( ($type eq 'CM' or $type eq 'DM') ? 'master' : 'slave' ) ."/rsync-mirror-failover-*.sh";
          $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {CRONTAB} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

          $commands {$server} {REMOVE} {++$_id} {auto} = 0;
          $commands {$server} {REMOVE} {$_id} {label} = '-m';
          $commands {$server} {REMOVE} {$_id} {active} = $active;
          $commands {$server} {REMOVE} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server rm ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications/'. ( ($type eq 'CM' or $type eq 'DM') ? 'master' : 'slave' ) ."/rsync-mirror-failover-*.sh";
          $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {REMOVE} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

          $commands {$server} {REMOVE} {++$_id} {auto} = 0;
          $commands {$server} {REMOVE} {$_id} {label} = '-n';
          $commands {$server} {REMOVE} {$_id} {active} = $active;
          $commands {$server} {REMOVE} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server rm ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications/'. ( ($type eq 'CM' or $type eq 'DM') ? 'master' : 'slave' ) ."/rsync-mirror-failover-*.conf";
          $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {REMOVE} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

          $todo = 1;
        }
      } elsif ( $compareView =~ /^Files generated\// ) {
        ($path, $generated, $installed, $compareDiff) = do_compare_diff ($compareView, 3, $details, $debug);

        if ($details) {
          $compareText = "File '$generated' changed into the generated configuration.";
        } else {
          my (undef, $servername, $filename) = split (/\//, $generated, 3);
          ($type, $activeServer, $server) = split (/-/, $servername, 3);
          my $active = ( ( $type =~ /^[CD]${activeServer}$/ ) ? 1 : 0 );

          # Replace 'distributed.citap.be:/opt/asnmtap/applications/slave/asnmtap-display.sh' with '/opt/asnmtap/applications/tmp/$CONFIGDIR/generated/DS-[SM]-distributed.citap.be/slave/asnmtap-display.sh'
          #          <----- $server ---->:$APPLICATIONPATH/<------ $filename ----->        $APPLICATIONPATH/tmp/      /<---------------------- $generated ---------------------->
          $commands {$server} {SCP} {++$_id} {auto} = 1;
          $commands {$server} {SCP} {$_id} {label} = '=a';
          $commands {$server} {SCP} {$_id} {active} = $active;
          $commands {$server} {SCP} {$_id} {command} = "$SCPCOMMAND $connectArguments $APPLICATIONPATH/tmp/$CONFIGDIR/$generated $SSHLOGONNAME\@$server:". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } ."/applications/$filename";
          $compareText .= '<FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {SCP} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );

		  if (($filename =~ /^etc\/DisplayCT-[\w-]+$/) or ($filename =~ /^etc\/CollectorCT-[\w-]+$/)) {
            $filename =~ s/etc\///g;
            $commands {$server} {RELOAD} {++$_id} {auto} = 1;
            $commands {$server} {RELOAD} {$_id} {label} = '=b';
            $commands {$server} {RELOAD} {$_id} {active} = $active;
            $commands {$server} {RELOAD} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications/'. ( ($type eq 'CM' or $type eq 'DM') ? 'master' : 'slave' ) ."/$filename.sh reload";
            $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {RELOAD} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
 		  } elsif (($filename =~ /^(slave|master)\/asnmtap-display.sh$/)   or ($filename =~ /^(slave|master)\/asnmtap-collector.sh$/)) {
            $commands {$server} {TODO} {++$_id} {auto} = 0;
            $commands {$server} {TODO} {$_id} {label} = '=c';
            $commands {$server} {TODO} {$_id} {active} = $active;
            $commands {$server} {TODO} {$_id} {command} = "'$filename' ?";
            $compareText .= '<br><FONT COLOR="yellow"> ['. $_id .'] '. $commands {$server} {TODO} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
		  } elsif (($filename =~ /^(slave|master)\/DisplayCT-[\w-]+\.sh$/) or ($filename =~ /^(slave|master)\/CollectorCT-[\w-]+\.sh$/)) {
            $commands {$server} {START} {++$_id} {auto} = 0;
            $commands {$server} {START} {$_id} {label} = '=d';
            $commands {$server} {START} {$_id} {active} = $active;
            $commands {$server} {START} {$_id} {command} = "$SSHCOMMAND $connectArguments $SSHLOGONNAME\@$server ". $ASNMTAP_PATH { substr ($type, -1, 1) } { $server } .'/applications/'. ( ($type eq 'CM' or $type eq 'DM') ? 'master' : 'slave' ) ."/$filename.sh restart";
            $compareText .= '<br><FONT COLOR="#99CC99"> ['. $_id .'] '. $commands {$server} {START} {$_id} {command} .'</FONT>' if ( $debug eq 'T' );
        # } elsif ( $filename =~ /^master\/rsync-mirror-failover-[\w\-.]+.conf$/ or $filename =~ /^slave\/rsync-mirror-failover-[\w\-.]+.conf$/) {
            # deze bestanden worden reeds gecopieerd door middel van bovenstaande SCP in deze sectie
          }
        }
      } elsif ( $compareView =~ /^diff: installed: No such file or directory/ ) {
        $compareText = "The installed configuration doesn't exist.";
      } elsif ( $compareView =~ /^diff: generated: No such file or directory/ ) {
        $compareText = "The generated configuration doesn't exist.";
      } else {
        $compareText = "<b>Under construction:</b> < $compareView >";
      }

      unless ( $details ) { $compareText = "<b>$compareText</b>" if (defined $compareText and ($todo or (defined $activeServer and $type =~ /^[CD]${activeServer}$/))); }

      $statusMessage .= "\n		   <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>$compareView</td></tr>" if ($details or $debug eq 'T');
      $statusMessage .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$compareDiff</td></tr>" if (defined $compareDiff);
      $statusMessage .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td>$compareText</td></tr>" if (defined $compareText);
    }
  }

  my ($commandsToExecute, $commandsExecuted, $commandsTODO) = ( $_id, 0 );

  foreach my $_servers ( sort keys %commands ) {
    my $_server = $commands {$_servers};
    $commandsTODO .= "\n        <tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td>$_servers</td></tr>";

    my $exitCurrentServer = 0;

    foreach my $type ( 'TODO', 'SCP', 'CHMOD', 'RELOAD', 'STOP', 'START', 'CRONTAB', 'REMOVE' ) {
      next if ( $exitCurrentServer );
      $commandsTODO .= "\n        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>$type</td></tr>";
      my $_type = $_server->{$type};

      foreach my $_id ( keys %$_type ) {
        next if ( $exitCurrentServer );
        my $auto    = ( ( exists $_type->{$_id}{auto} and $_type->{$_id}{auto} ) ? $_type->{$_id}{auto} : 0 );
        my $label   = ( ( exists $_type->{$_id}{label} and $_type->{$_id}{label} ) ? $_type->{$_id}{label} : '??' );
        my $active  = ( ( exists $_type->{$_id}{active} and $_type->{$_id}{active} ) ? $_type->{$_id}{active} : 0 );
        my $command = ( ( exists $_type->{$_id}{command} and $_type->{$_id}{command} ) ? $_type->{$_id}{command} : '' );

        unless ( defined $command ) {
          my $prefix = ( ( $debug eq 'T' ) ? "E) '$label' [$_id] " : '' );
          $commandsTODO .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><FONT COLOR=\"red\">${prefix}${command}</FONT></td></tr>";
        } elsif ( $type !~ /^(?:RELOAD|STOP|START)$/ or ( $type =~ /^(?:RELOAD|STOP|START)$/ and $active ) ) {
          if ( $Cauto == 1 and $auto == 1 ) {
            my $color = 'red';

            my @capture = `$command 2>&1`;
            my $exit_value  = $? >> 8;
            my $signal_num  = $? & 127;
            my $dumped_core = $? & 128;
            $commandsTODO .= "\n        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td><FONT COLOR=\"white\">$exit_value - $signal_num - $dumped_core - ". join('<br>', @capture) ."</FONT></td></tr>" if ( $debug eq 'T' );

            if ( $exit_value == 0 && $signal_num == 0 && $dumped_core == 0 ) {
              my ($lineNumber, $proccessNextLine) = (0, 0);

              foreach my $capture ( @capture ) {
                $capture =~ s/\r$//g;
                $capture =~ s/\n$//g;
                next unless ( defined $capture and ! $exitCurrentServer );

                $lineNumber++;
                $commandsTODO .= "\n        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td><FONT COLOR=\"cyaan\">$capture</FONT></td></tr>";

                if ( $lineNumber == 1 ) {
                  for ( $type ) {
                    /^SCP$/     && do { last; };
                    /^CHMOD$/   && do { last; };
                    /^RELOAD$/  && do {
                      $exitCurrentServer = ( ( $capture =~ /^Reload:(?:\s)*'(Collector|Display)(?:\s)*(.)*'(?:\s)*...$/ ) ? 0 : 1 );
                      last; };
                    /^STOP$/    && do {
                      $exitCurrentServer = ( ( $capture =~ /^(Stop:(?:\s)*'(Collector|Display)(?:\s)*(.)*'(?:\s)*...|'(Collector|Display)(?:\s)*(.)*'(?:\s)*already stopped)$/ ) ? 0 : 1 );
                      last; };
                    /^START$/   && do {
                      $exitCurrentServer = ( ( $capture =~ /^Start:(?:\s)*'(Collector|Display)(?:\s)*(.)*'(?:\s)*...$/ ) ? 0 : 1 );
                      $proccessNextLine++ unless ( $exitCurrentServer );
                      last; };
                    /^CRONTAB$/ && do { last; };
                    /^REMOVE$/  && do { last; };
                    $exitCurrentServer = 1;
                  }
                } elsif ( $proccessNextLine ) {
                  $commandsTODO .= "\n        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td><FONT COLOR=\"cyaan\">proccess next line: $proccessNextLine - $capture</FONT></td></tr>";
                } else {
                  my $match = 0;

                  if ( $debug eq 'T' ) {
                    for ( $capture ) {
                      /kill:(?:\s)*\((?:\d)*\)(?:\s)*-(?:\s)*No such process$/ && do { $match = 1; $exitCurrentServer = 1; last; };
                      /^cat:(?:\s)*cannot(?:\s)*open(?:\s)*(.)*\.pid$/         && do { $match = 2; $exitCurrentServer = 1; last; };
                    }
                  } else {
                    $exitCurrentServer = 1;
                  }

                  $commandsTODO .= "\n        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td><FONT COLOR=\"cyaan\">match rule: $match - $capture</FONT></td></tr>";
                }
              }

              $color = '#99CC99' unless ( $exitCurrentServer );
            } else {
              $exitCurrentServer = 1;

              foreach my $capture ( @capture ) {
                $capture =~ s/\r$//g;
                $capture =~ s/\n$//g;
                next unless ( defined $capture );

                my $match = '0';

                if ( $debug eq 'T' ) {
                  for ( $capture ) {
                    /^ksh:(?:\s)*(.)*:(?:\s)*not found$/                  && do { $match = 127; last; }; # exit_value = 127
                    /^ksh:(?:\s)*(.)*:(?:\s)*cannot execute$/             && do { $match = 126; last; }; # exit_value = 126
                    /^scp:(?:\s)*(.)*:(?:\s)*No such file or directory$/  && do { $match = 1;   last; }; # exit_value = 1
                    $match = '?';
                  }
                }

                $commandsTODO .= "\n        <tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td><FONT COLOR=\"cyaan\">match rule: $match = exit_value: $exit_value - $capture</FONT></td></tr>";
              }
            }

            my $prefix = ( ( $debug eq 'T' ) ? "A) '$label' [$_id] " : '' );
            $commandsTODO .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><b><FONT COLOR=\"$color\">${prefix}${command}</FONT></b></td></tr>";
          } else { # implementatie moet nog gebeuren
            my $color = ( ( $auto == 1 ) ? '#99CC99' : 'white');
            my $prefix = ( ( $debug eq 'T' ) ? "I) '$label' [$_id] " : '' );
            $commandsTODO .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><b><FONT COLOR=\"$color\">${prefix}${command}</FONT></b></td></tr>";
          }
        } else { # no action required
          my $prefix = ( ( $debug eq 'T' ) ? "N) '$label' [$_id] " : '' );
          $commandsTODO .= "\n        <tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td><FONT COLOR=\"#99CC99\">${prefix}${command}</FONT></td></tr>";
        }

        $commandsExecuted++ unless ( $exitCurrentServer );
      }
    }
  }

  $statusMessage .= $commandsTODO if (defined $commandsTODO);

# APE #
# unless ($details)
#   $action = 'errorView' unless ( $commandsToExecute eq $commandsExecuted );
# }

  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub do_system_call {
  my ($command, $debug) = @_;

  my ($stdout, $stderr, $exit_value, $signal_num, $dumped_core, $status, $statusMessage);

  if ($CAPTUREOUTPUT) {
    use IO::CaptureOutput qw(capture_exec);
   ($stdout, $stderr) = capture_exec("$command");
  } else {
    system ("$command"); $stdout = $stderr = '';
  }

  if ( $debug eq 'T' ) {
    $exit_value  = $? >> 8;
    $signal_num  = $? & 127;
    $dumped_core = $? & 128;

    $statusMessage  = "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>$command: ";
    $statusMessage .= ( $exit_value == 0 && $signal_num == 0 && $dumped_core == 0 && $stderr eq '' ) ? 'Success' : "Failed '$stderr'";
    $statusMessage .= "</td></tr>";
  } else {
    $statusMessage = '';
  }

  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub system_call {
  my ($command, $parameters, $debug) = @_;

  my $doSystemCall = 0;
  my $statusMessage = '';

  if ( $command eq "mkdir" ) {
    $doSystemCall = 1 unless ( -e "$parameters" );
  } elsif ( $command eq "rm -rf" ) {
    if ($parameters =~ /$APPLICATIONPATH\/tmp\/$CONFIGDIR\// and -e "$parameters") { $doSystemCall = 1; }
  } elsif ( $command eq "cp" ) {
    if ($parameters =~ /^$APPLICATIONPATH\/tmp\/$CONFIGDIR/) { $doSystemCall = 1; }
  } elsif ( $command eq "mv" ) {
    if ($parameters =~ /^$APPLICATIONPATH\/tmp\/$CONFIGDIR/) { $doSystemCall = 1; }
  } elsif ( $command =~ /diff -braq -I/ ) {
    if ($parameters =~ /^$APPLICATIONPATH\/tmp\/$CONFIGDIR\/generated $APPLICATIONPATH\/tmp\/$CONFIGDIR\/installed/) { $statusMessage = do_compare_view("$command $parameters", 1, $debug); }
  } elsif ( $command =~ /diff -braq -E/ ) {
    $command =~ s/diff -braq -E/diff -braq -I/g;
    if ($parameters =~ /^$APPLICATIONPATH\/tmp\/$CONFIGDIR\/generated $APPLICATIONPATH\/tmp\/$CONFIGDIR\/installed/) { $statusMessage = do_compare_view("$command $parameters", 0, $debug); }
  }

  if ( $doSystemCall ) {
    $statusMessage = do_system_call ("$command $parameters", $debug);

    if ( $command eq "mkdir" and $parameters =~ /^$APPLICATIONPATH\/tmp\/$CONFIGDIR/ ) {
      $statusMessage .= do_system_call ("cp $APPLICATIONPATH/tools/templates/HEADER.html $parameters/", $debug);
      $statusMessage .= do_system_call ("cp $APPLICATIONPATH/tools/templates/FOOTER.html $parameters/", $debug);
    }
  }

  return ($statusMessage);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
