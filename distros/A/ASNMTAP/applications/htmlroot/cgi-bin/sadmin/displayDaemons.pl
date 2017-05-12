#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, displayDaemons.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :SADMIN :DBREADWRITE :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "displayDaemons.pl";
my $prgtext     = "Display Daemons";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : 'sadmin';  $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : 'F';
my $pageNo              = (defined $cgi->param('pageNo'))          ? $cgi->param('pageNo')          : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))      ? $cgi->param('pageOffset')      : 0;
my $orderBy             = (defined $cgi->param('orderBy'))         ? $cgi->param('orderBy')         : 'displayDaemon';
my $action              = (defined $cgi->param('action'))          ? $cgi->param('action')          : 'listView';
my $CcatalogID          = (defined $cgi->param('catalogID'))       ? $cgi->param('catalogID')       : $CATALOGID;
my $CcatalogIDreload    = (defined $cgi->param('catalogIDreload')) ? $cgi->param('catalogIDreload') : 0;
my $CdisplayDaemon      = (defined $cgi->param('displayDaemon'))   ? $cgi->param('displayDaemon')   : '';
my $CgroupName          = (defined $cgi->param('groupName'))       ? $cgi->param('groupName')       : '';
my $Cpagedir            = (defined $cgi->param('pagedirs'))        ? $cgi->param('pagedirs')        : 'none';
my $CserverID           = (defined $cgi->param('serverID'))        ? $cgi->param('serverID')        : 'none';
my $Cloop               = (defined $cgi->param('loop'))            ? $cgi->param('loop')            : 'T';
my $Ctrigger            = (defined $cgi->param('trigger'))         ? $cgi->param('trigger')         : 'F';
my $CdisplayTime        = (defined $cgi->param('displayTime'))     ? $cgi->param('displayTime')     : 'T';
my $ClockMySQL          = (defined $cgi->param('lockMySQL'))       ? $cgi->param('lockMySQL')       : 'F';
my $CdebugDaemon        = (defined $cgi->param('debugDaemon'))     ? $cgi->param('debugDaemon')     : 'F';
my $Cactivated          = (defined $cgi->param('activated'))       ? $cgi->param('activated')       : 'off';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Display Daemon", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&displayDaemon=$CdisplayDaemon&groupName=$CgroupName&pagedirs=$Cpagedir&serverID=$CserverID&loop=$Cloop&trigger=$Ctrigger&displayTime=$CdisplayTime&lockMySQL=$ClockMySQL&debugDaemon=$CdebugDaemon&activated=$Cactivated";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>page no           : $pageNo<br>page offset       : $pageOffset<br>order by          : $orderBy<br>action            : $action<br>catalog ID        : $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br>displayDaemon     : $CdisplayDaemon<br>groupName         : $CgroupName<br>pagedirs          : $Cpagedir<br>serverID          : $CserverID<br>loop              : $Cloop<br>trigger           : $Ctrigger<br>displayTime       : $CdisplayTime<br>lockMySQL         : $ClockMySQL<br>debugDaemon       : $CdebugDaemon<br>activated         : $Cactivated<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($catalogIDSelect, $pagedirsSelect, $serversSelect, $matchingDisplayDaemon, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;catalogID=$CcatalogID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledPrimaryKey = '';

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert Display Daemon";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
      $CcatalogID   = $CATALOGID if ($action eq 'insertView');
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Display Daemon $CdisplayDaemon from $CcatalogID exist before to insert";

      $sql = "select $SERVERTABLDISPLAYDMNS.pagedir from $SERVERTABLDISPLAYDMNS, $SERVERTABLPAGEDIRS where $SERVERTABLDISPLAYDMNS.catalogID = '$CcatalogID' and $SERVERTABLDISPLAYDMNS.pagedir = '$Cpagedir' and $SERVERTABLDISPLAYDMNS.displayDaemon = '$CdisplayDaemon' and $SERVERTABLDISPLAYDMNS.catalogID = $SERVERTABLPAGEDIRS.catalogID and $SERVERTABLDISPLAYDMNS.pagedir = $SERVERTABLPAGEDIRS.pagedir";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle  = "Pagedir $Cpagedir from $CcatalogID used already";
        $nextAction = "insertView";
      } else {
        $sql = "select displayDaemon from $SERVERTABLDISPLAYDMNS WHERE catalogID='$CcatalogID' and displayDaemon='$CdisplayDaemon'";
        ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

  	    if ( $numberRecordsIntoQuery ) {
          $htmlTitle  = "Display Daemon $CdisplayDaemon from $CcatalogID exist already";
          $nextAction = "insertView";
        } else {
          $htmlTitle  = "Display Daemon $CdisplayDaemon from $CcatalogID inserted";
          my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
          $sql = 'INSERT INTO ' .$SERVERTABLDISPLAYDMNS. ' SET catalogID="' .$CcatalogID. '", displayDaemon="' .$CdisplayDaemon. '", groupName="' .$CgroupName. '", pagedir="' . $Cpagedir. '", serverID="' .$CserverID. '", `loop`="' .$Cloop. '", `trigger`="' .$Ctrigger. '", displayTime="' .$CdisplayTime. '", lockMySQL="' .$ClockMySQL. '", debugDaemon="' .$CdebugDaemon. '", activated="' .$dummyActivated. '"';
          $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          $nextAction   = "listView" if ($rv);
        }
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Delete Display Daemon $CdisplayDaemon from $CcatalogID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $sql = "select uKey, displayGroupID from $SERVERTABLVIEWS where catalogID = '$CcatalogID' and displayDaemon = '$CdisplayDaemon' order by displayDaemon, uKey";
      ($rv, $matchingDisplayDaemon) = check_record_exist ($rv, $dbh, $sql, 'Views from ' .$CcatalogID, 'Unique Key', 'Display Daemon', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ($matchingDisplayDaemon eq '') {
        $htmlTitle = "Display Daemon $CdisplayDaemon from $CcatalogID deleted";
        $sql = 'DELETE FROM ' .$SERVERTABLDISPLAYDMNS. ' WHERE catalogID="' .$CcatalogID. '" and displayDaemon="' .$CdisplayDaemon. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction = "listView" if ($rv);
      } else {
        $htmlTitle = "Display Daemon $CdisplayDaemon from $CcatalogID not deleted, still used by";
      }

      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'displayView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Display Display Daemon $CdisplayDaemon from $CcatalogID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Edit Display Daemon $CdisplayDaemon from $CcatalogID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $htmlTitle    = "Display Daemon $CdisplayDaemon from $CcatalogID updated";
      my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLDISPLAYDMNS. ' SET catalogID="' .$CcatalogID. '", displayDaemon="' .$CdisplayDaemon. '", groupName="' .$CgroupName. '", pagedir="' . $Cpagedir. '", serverID="' .$CserverID. '", `loop`="' .$Cloop. '", `trigger`="' .$Ctrigger. '", displayTime="' .$CdisplayTime. '", lockMySQL="' .$ClockMySQL. '", debugDaemon="' .$CdebugDaemon. '", activated="' .$dummyActivated. '" WHERE catalogID="' .$CcatalogID. '" and displayDaemon="' .$CdisplayDaemon. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'listView') {
      $htmlTitle    = "All Display Daemons listed";

      if ( $CcatalogIDreload ) {
        $pageNo = 1;
        $pageOffset = 0;
      }

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select SQL_NO_CACHE count(displayDaemon) from $SERVERTABLDISPLAYDMNS where catalogID = '$CcatalogID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID&amp;orderBy=$orderBy");

      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLDISPLAYDMNS, 'displayDaemon', "catalogID = '$CcatalogID'", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select catalogID, serverID, displayDaemon, groupName, activated from $SERVERTABLDISPLAYDMNS where catalogID = '$CcatalogID' order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID desc, displayDaemon asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID asc, displayDaemon asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverID desc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> serverID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverID asc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=displayDaemon desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Display Daemon <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=displayDaemon asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Group Name <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingDisplayDaemon, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Display Daemon', 'catalogID|displayDaemon', '0|2', '', '', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select catalogID, displayDaemon, groupName, pagedir, serverID, `loop`, `trigger`, displayTime, lockMySQL, debugDaemon, activated from $SERVERTABLDISPLAYDMNS where catalogID = '$CcatalogID' and displayDaemon='$CdisplayDaemon'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcatalogID, $CdisplayDaemon, $CgroupName, $Cpagedir, $CserverID, $Cloop, $Ctrigger, $CdisplayTime, $ClockMySQL, $CdebugDaemon, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $CcatalogID = $CATALOGID if ($action eq 'duplicateView');
        $Cactivated = ($Cactivated == 1) ? 'on' : 'off';
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      $sql = "select pagedir, groupName from $SERVERTABLPAGEDIRS where catalogID = '$CcatalogID' order by groupName";
      ($rv, $pagedirsSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $Cpagedir, 'pagedirs', 'none', '-Select-', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select serverID, serverTitle from $SERVERTABLSERVERS where catalogID = '$CcatalogID' order by serverTitle";
      ($rv, $serversSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CserverID, 'serverID', 'none', '-Select-', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
    }
	
    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
HTML

      if ($action eq 'duplicateView' or $action eq 'insertView') {
        print <<HTML;

  var objectRegularExpressionDisplayDaemonFormat = /\^[a-zA-Z0-9-]\+\$/;

  if ( document.displayDaemon.displayDaemon.value == null || document.displayDaemon.displayDaemon.value == '' ) {
    document.displayDaemon.displayDaemon.focus();
    alert('Please enter a display daemon!');
    return false;
  } else {
    if ( ! objectRegularExpressionDisplayDaemonFormat.test(document.displayDaemon.displayDaemon.value) ) {
      document.displayDaemon.displayDaemon.focus();
      alert('Please re-enter display daemon: Bad display daemon format!');
      return false;
    }
  }
HTML
      }

      print <<HTML;

  if( document.displayDaemon.pagedirs.options[document.displayDaemon.pagedirs.selectedIndex].value == 'none' ) {
    document.displayDaemon.pagedirs.focus();
    alert('Please create/select one of the pagedirs!');
    return false;
  }

  if( document.displayDaemon.serverID.options[document.displayDaemon.serverID.selectedIndex].value == 'none' ) {
    document.displayDaemon.serverID.focus();
    alert('Please create/select one of the servers!');
    return false;
  }

  if ( document.displayDaemon.groupName.value == null || document.displayDaemon.groupName.value == '' ) {
    document.displayDaemon.groupName.focus();
    alert('Please enter a group name!');
    return false;
  }

  var objectRegularExpressionLoopValue = /\^[F|T]\$/;

  if ( document.displayDaemon.loop.value == null || document.displayDaemon.loop.value == '' ) {
    document.displayDaemon.loop.focus();
    alert('Please enter a loop!');
    return false;
  } else {
    if ( ! objectRegularExpressionLoopValue.test(document.displayDaemon.loop.value) ) {
      document.displayDaemon.loop.focus();
      alert('Please re-enter loop: Bad loop value!');
      return false;
    }
  }

  var objectRegularExpressionTriggerValue = /\^[F|T]\$/;

  if ( document.displayDaemon.trigger.value == null || document.displayDaemon.trigger.value == '' ) {
    document.displayDaemon.trigger.focus();
    alert('Please enter a trigger!');
    return false;
  } else {
    if ( ! objectRegularExpressionTriggerValue.test(document.displayDaemon.trigger.value) ) {
      document.displayDaemon.trigger.focus();
      alert('Please re-enter trigger: Bad trigger value!');
      return false;
    }
  }

  var objectRegularExpressionDisplayTimeValue = /\^[F|T]\$/;

  if ( document.displayDaemon.displayTime.value == null || document.displayDaemon.displayTime.value == '' ) {
    document.displayDaemon.displayTime.focus();
    alert('Please enter a display time!');
    return false;
  } else {
    if ( ! objectRegularExpressionDisplayTimeValue.test(document.displayDaemon.displayTime.value) ) {
      document.displayDaemon.displayTime.focus();
      alert('Please re-enter displayTime: Bad displaytime value!');
      return false;
    }
  }

  var objectRegularExpressionLockMySQLValue = /\^[F|T]\$/;

  if ( document.displayDaemon.lockMySQL.value == null || document.displayDaemon.lockMySQL.value == '' ) {
    document.displayDaemon.lockMySQL.focus();
    alert('Please enter a lock MySQL!');
    return false;
  } else {
    if ( ! objectRegularExpressionLockMySQLValue.test(document.displayDaemon.lockMySQL.value) ) {
      document.displayDaemon.lockMySQL.focus();
      alert('Please re-enter lock MySQL: Bad lock MySQL value!');
      return false;
    }
  }


  var objectRegularExpressionDebugDaemonValue = /\^[F|T]\$/;

  if ( document.displayDaemon.debugDaemon.value == null || document.displayDaemon.debugDaemon.value == '' ) {
    document.displayDaemon.debugDaemon.focus();
    alert('Please enter a debug daemon value!');
    return false;
  } else {
    if ( ! objectRegularExpressionDebugDaemonValue.test(document.displayDaemon.debugDaemon.value) ) {
      document.displayDaemon.debugDaemon.focus();
      alert('Please re-enter debug daemon value: Bad debug daemon value!');
      return false;
    }
  }

  if ( document.displayDaemon.groupName.value == null || document.displayDaemon.groupName.value == '' ) {
    document.displayDaemon.groupName.focus();
    alert('Please enter a group name!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="displayDaemon" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'listView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.displayDaemon.catalogIDreload.value = 1;
  document.displayDaemon.submit();
  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="displayDaemon">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"displayDaemon\">\n";
      $pageNo = 1; $pageOffset = 0;
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    }

    if ($action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView' or $action eq 'listView') {
      print <<HTML;
  <input type="hidden" name="pagedir"         value="$pagedir">
  <input type="hidden" name="pageset"         value="$pageset">
  <input type="hidden" name="debug"           value="$debug">
  <input type="hidden" name="CGISESSID"       value="$sessionID">
  <input type="hidden" name="pageNo"          value="$pageNo">
  <input type="hidden" name="pageOffset"      value="$pageOffset">
  <input type="hidden" name="action"          value="$nextAction">
  <input type="hidden" name="orderBy"         value="$orderBy">
  <input type="hidden" name="catalogIDreload" value="0">
HTML
    } else {
      print "<br>\n";
    }

    print "  <input type=\"hidden\" name=\"catalogID\" value=\"$CcatalogID\">\n  <input type=\"hidden\" name=\"displayDaemon\" value=\"$CdisplayDaemon\">\n" if ($formDisabledPrimaryKey ne '' and $action ne 'displayView');

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=insertView&amp;orderBy=$orderBy">[Insert Display Daemon]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=listView&amp;orderBy=$orderBy">[List all Display Daemons]</a></td>
	  </tr></table>
	</td></tr>
HTML

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      my $activatedChecked = ($Cactivated eq 'on') ? ' checked' : '';

      print <<HTML;
      <tr><td>&nbsp;</td></tr>
      <tr><td>
	    <table border="0" cellspacing="0" cellpadding="0">
          <tr><td><b>Catalog ID: </b></td><td>
            <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled>
          </td></tr>
          <tr><td><b>Display Daemon: </b></td><td>
            <input type="text" name="displayDaemon" value="$CdisplayDaemon" size="64" maxlength="64" $formDisabledPrimaryKey>
          <tr><td><b>Group Name: </b></td><td>
            <input type="text" name="groupName" value="$CgroupName" size="64" maxlength="64" $formDisabledAll>
          <tr><td><b>Pagedir: </b></td><td>
            $pagedirsSelect
          <tr><td><b>Server ID: </b></td><td>
            $serversSelect
          <tr><td><b>Loop: </b></td><td>
            <input type="text" name="loop" value="$Cloop" size="1" maxlength="1" $formDisabledAll> value: F(alse) or T(rue)
          <tr><td><b>Trigger: </b></td><td>
            <input type="text" name="trigger" value="$Ctrigger" size="1" maxlength="1" $formDisabledAll> value: F(alse) or T(rue)
          <tr><td><b>Display Time: </b></td><td>
            <input type="text" name="displayTime" value="$CdisplayTime" size="1" maxlength="1" $formDisabledAll> value: F(alse) or T(rue)
          <tr><td><b>Lock MySQL: </b></td><td>
            <input type="text" name="lockMySQL" value="$ClockMySQL" size="1" maxlength="1" $formDisabledAll> value: F(alse) or T(rue)
          <tr><td><b>Debug Daemon: </b></td><td>
            <input type="text" name="debugDaemon" value="$CdebugDaemon" size="1" maxlength="1" $formDisabledAll> value: F(alse) or T(rue)
          <tr><td><b>Activated: </b></td><td>
            <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
          </td></tr>
HTML

      print "    <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "    <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Unique Key: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingDisplayDaemon</td></tr>" if (defined $matchingDisplayDaemon and $matchingDisplayDaemon ne '');
    } else {
      print "    <tr><td><br><table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='#333344'><tr><td align=\"left\"><b>Catalog ID: </b></td><td>$catalogIDSelect</td></tr></table></td></tr>";
      print "    <tr><td align=\"center\"><br>$matchingDisplayDaemon</td></tr>";
    }

    print "  </table>\n";

    if ($action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView' or $action eq 'listView') {
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

