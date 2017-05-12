#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, timeperiods.pl for ASNMTAP::Asnmtap::Applications::CGI
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
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :ADMIN :DBREADWRITE :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "timeperiods.pl";
my $prgtext     = "Timeperiods";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir          = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset          = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : 'admin';   $pageset =~ s/\+/ /g;
my $debug            = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : 'F';
my $pageNo           = (defined $cgi->param('pageNo'))          ? $cgi->param('pageNo')          : 1;
my $pageOffset       = (defined $cgi->param('pageOffset'))      ? $cgi->param('pageOffset')      : 0;
my $orderBy          = (defined $cgi->param('orderBy'))         ? $cgi->param('orderBy')         : 'timeperiodName';
my $action           = (defined $cgi->param('action'))          ? $cgi->param('action')          : 'listView';
my $CcatalogID       = (defined $cgi->param('catalogID'))       ? $cgi->param('catalogID')       : $CATALOGID;
my $CcatalogIDreload = (defined $cgi->param('catalogIDreload')) ? $cgi->param('catalogIDreload') : 0;
my $CtimeperiodID    = (defined $cgi->param('timeperiodID'))    ? $cgi->param('timeperiodID')    : 'new';
my $CtimeperiodAlias = (defined $cgi->param('timeperiodAlias')) ? $cgi->param('timeperiodAlias') : '';
my $CtimeperiodName  = (defined $cgi->param('timeperiodName'))  ? $cgi->param('timeperiodName')  : '';
my $Csunday          = (defined $cgi->param('sunday'))          ? $cgi->param('sunday')          : '';
my $Cmonday          = (defined $cgi->param('monday'))          ? $cgi->param('monday')          : '';
my $Ctuesday         = (defined $cgi->param('tuesday'))         ? $cgi->param('tuesday')         : '';
my $Cwednesday       = (defined $cgi->param('wednesday'))       ? $cgi->param('wednesday')       : '';
my $Cthursday        = (defined $cgi->param('thursday'))        ? $cgi->param('thursday')        : '';
my $Cfriday          = (defined $cgi->param('friday'))          ? $cgi->param('friday')          : '';
my $Csaturday        = (defined $cgi->param('saturday'))        ? $cgi->param('saturday')        : '';
my $Cactivated       = (defined $cgi->param('activated'))       ? $cgi->param('activated')       : 'off';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Timeperiods", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&timeperiodID=$CtimeperiodID&timeperiodAlias=$CtimeperiodAlias&timeperiodName=$CtimeperiodName&sunday=$Csunday&monday=$Cmonday&tuesday=$Ctuesday&wednesday=$Cwednesday&thursday=$Cthursday&friday=$Cfriday&saturday=$Csaturday&activated=$Cactivated";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>page no       : $pageNo<br>page offset   : $pageOffset<br>order by      : $orderBy<br>action        : $action<br>catalog ID       : $CcatalogID<br>catalog ID reload: $CcatalogIDreload<br>timeperiod ID    : $CtimeperiodID<br>timeperiod Alias : $CtimeperiodAlias<br>timeperiod Name  : $CtimeperiodName<br>sunday        : $Csunday<br>monday        : $Cmonday<br>tuesday       : $Ctuesday<br>wednesday     : $Cwednesday<br>thursday      : $Cthursday<br>friday        : $Cfriday<br>saturday      : $Csaturday<br>activated     : $Cactivated<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($catalogIDSelect, $matchingTimeperiods, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset&amp;catalogID=$CcatalogID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = ''; $formDisabledPrimaryKey = 'disabled';

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert Timeperiod";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
      $CcatalogID   = $CATALOGID if ($action eq 'insertView');
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Timeperiod $CtimeperiodID from $CcatalogID exist before to insert";

      $sql = "select timeperiodID from $SERVERTABLTIMEPERIODS WHERE catalogID='$CcatalogID' and timeperiodID='$CtimeperiodID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle    = "Timeperiod $CtimeperiodID from $CcatalogID exist already";
        $nextAction   = "insertView";
      } else {
        $htmlTitle    = "Timeperiod $CtimeperiodID from $CcatalogID inserted";
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLTIMEPERIODS. ' SET catalogID="' .$CcatalogID. '", timeperiodID="' .$CtimeperiodID. '", timeperiodAlias="' .$CtimeperiodAlias. '", timeperiodName="' .$CtimeperiodName. '", sunday="' . $Csunday. '", monday="' . $Cmonday. '", tuesday="' . $Ctuesday. '", wednesday="' . $Cwednesday. '", thursday="' . $Cthursday. '", friday="' . $Cfriday. '", saturday="' . $Csaturday. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledAll = 'disabled';
      $htmlTitle    = "Delete Timeperiod $CtimeperiodID from $CcatalogID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $sql = "select id, uKey from $SERVERTABLREPORTS where catalogID = '$CcatalogID' and timeperiodID = '$CtimeperiodID' order by id";
      ($rv, $matchingTimeperiods) = check_record_exist ($rv, $dbh, $sql, 'Reports from ' .$CcatalogID, 'ID', 'uKey', $matchingTimeperiods, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ($matchingTimeperiods eq '') {
        $sql = 'DELETE FROM ' .$SERVERTABLTIMEPERIODS. ' WHERE catalogID="' .$CcatalogID. '" and timeperiodID="' .$CtimeperiodID. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction = "listView" if ($rv);
        $htmlTitle = "Timeperiod $CtimeperiodID from $CcatalogID deleted";
      } else {
        $htmlTitle = "Timeperiod $CtimeperiodID from $CcatalogID not deleted, still used by";
      }
    } elsif ($action eq 'displayView') {
      $formDisabledAll = 'disabled';
      $htmlTitle    = "Display timeperiod $CtimeperiodID from $CcatalogID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $htmlTitle    = "Edit timeperiod $CtimeperiodID from $CcatalogID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $matchingTimeperiods = '';
      my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;

      unless ( $dummyActivated ) {
        $sql = "select id, uKey from $SERVERTABLREPORTS where from catalogID = '$CcatalogID' and timeperiodID = '$CtimeperiodID' order by id";
        ($rv, $matchingTimeperiods) = check_record_exist ($rv, $dbh, $sql, 'Reports from ' .$CcatalogID, 'ID', 'uKey', $matchingTimeperiods, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      }

	  if ($dummyActivated or $matchingTimeperiods eq '') {
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'UPDATE ' .$SERVERTABLTIMEPERIODS. ' SET catalogID="' .$CcatalogID. '", timeperiodID="' .$CtimeperiodID. '", timeperiodAlias="' .$CtimeperiodAlias. '", timeperiodName="' .$CtimeperiodName. '", sunday="' . $Csunday. '", monday="' . $Cmonday. '", tuesday="' . $Ctuesday. '", wednesday="' . $Cwednesday. '", thursday="' . $Cthursday. '", friday="' . $Cfriday. '", saturday="' . $Csaturday. '", activated="' .$dummyActivated. '" WHERE catalogID="' .$CcatalogID. '" and timeperiodID="' .$CtimeperiodID. '"';

        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
        $htmlTitle    = "Timeperiod $CtimeperiodID from $CcatalogID updated";
      } else {
        $htmlTitle    = "Timeperiod $CtimeperiodID from $CcatalogID not deactivated and updated, still used by";
      }
    } elsif ($action eq 'listView') {
      $formDisabledPrimaryKey = '';
      $htmlTitle    = "All timeperiods listed";

      if ( $CcatalogIDreload ) {
        $pageNo = 1;
        $pageOffset = 0;
      }

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select SQL_NO_CACHE count(timeperiodID) from $SERVERTABLTIMEPERIODS where catalogID = '$CcatalogID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID&amp;orderBy=$orderBy");
 
      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLTIMEPERIODS, 'timeperiodName', "catalogID = '$CcatalogID'", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select catalogID, timeperiodID, timeperiodName, activated from $SERVERTABLTIMEPERIODS where $SERVERTABLTIMEPERIODS.catalogID = '$CcatalogID' order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID desc, timeperiodID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID asc, timeperiodID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=timeperiodID desc, catalogID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Timeperiod ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=timeperiodID asc, catalogID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=timeperiodName desc, catalogID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Timeperiod Name <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=timeperiodName asc, catalogID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, timeperiodName asc, catalogID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, timeperiodName asc, catalogID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingTimeperiods, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Timeperiod', 'catalogID|timeperiodID', '0|1', '', '', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select catalogID, timeperiodID, timeperiodAlias, timeperiodName, sunday, monday, tuesday, wednesday, thursday, friday, saturday, activated from $SERVERTABLTIMEPERIODS where catalogID = '$CcatalogID' and timeperiodID = '$CtimeperiodID'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcatalogID, $CtimeperiodID, $CtimeperiodAlias, $CtimeperiodName, $Csunday, $Cmonday, $Ctuesday, $Cwednesday, $Cthursday, $Cfriday, $Csaturday, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);

        if ($action eq 'duplicateView') {
          $CcatalogID    = $CATALOGID;
          $CtimeperiodID = 'new';
        }

        $Cactivated = ($Cactivated == 1) ? 'on' : 'off';
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }
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
  var objectRegularExpressionTimeFormat = /\^\\d\\d:\\d\\d-\\d\\d:\\d\\d(,\\d\\d:\\d\\d-\\d\\d:\\d\\d){0,2}\$/;
  var objectRegularExpressionTimeValue  = /\^(([0-1]\\d|2[0-3]):[0-5]\\d|24:00)-(([0-1]\\d|2[0-3]):[0-5]\\d|24:00)(,(([0-1]\\d|2[0-3]):[0-5]\\d|24:00)-(([0-1]\\d|2[0-3]):[0-5]\\d|24:00)){0,3}\$/;

  if ( document.timeperiods.timeperiodAlias.value == null || document.timeperiods.timeperiodAlias.value == '' ) {
    document.timeperiods.timeperiodAlias.focus();
    alert('Please enter a timeperiod alias!');
    return false;
  }

  if ( document.timeperiods.timeperiodName.value == null || document.timeperiods.timeperiodName.value == '' ) {
    document.timeperiods.timeperiodName.focus();
    alert('Please enter a timeperiod name!');
    return false;
  }

  if ( document.timeperiods.sunday.value != null && document.timeperiods.sunday.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.timeperiods.sunday.value) ) {
      document.timeperiods.sunday.focus();
      alert('Please re-enter sunday time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.timeperiods.sunday.value) ) {
      document.timeperiods.sunday.focus();
      alert('Please re-enter sunday time: Bad time value!');
      return false;
    }
  }

  if ( document.timeperiods.monday.value != null && document.timeperiods.monday.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.timeperiods.monday.value) ) {
      document.timeperiods.monday.focus();
      alert('Please re-enter monday time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.timeperiods.monday.value) ) {
      document.timeperiods.monday.focus();
      alert('Please re-enter monday time: Bad time value!');
      return false;
    }
  }

  if ( document.timeperiods.tuesday.value != null && document.timeperiods.tuesday.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.timeperiods.tuesday.value) ) {
      document.timeperiods.tuesday.focus();
      alert('Please re-enter tuesday time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.timeperiods.tuesday.value) ) {
      document.timeperiods.tuesday.focus();
      alert('Please re-enter tuesday time: Bad time value!');
      return false;
    }
  }

  if ( document.timeperiods.wednesday.value != null && document.timeperiods.wednesday.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.timeperiods.wednesday.value) ) {
      document.timeperiods.wednesday.focus();
      alert('Please re-enter wednesday time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.timeperiods.wednesday.value) ) {
      document.timeperiods.wednesday.focus();
      alert('Please re-enter wednesday time: Bad time value!');
      return false;
    }
  }

  if ( document.timeperiods.thursday.value != null && document.timeperiods.thursday.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.timeperiods.thursday.value) ) {
      document.timeperiods.thursday.focus();
      alert('Please re-enter thursday time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.timeperiods.thursday.value) ) {
      document.timeperiods.thursday.focus();
      alert('Please re-enter thursday time: Bad time value!');
      return false;
    }
  }

  if ( document.timeperiods.friday.value != null && document.timeperiods.friday.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.timeperiods.friday.value) ) {
      document.timeperiods.friday.focus();
      alert('Please re-enter friday time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.timeperiods.friday.value) ) {
      document.timeperiods.friday.focus();
      alert('Please re-enter friday time: Bad time value!');
      return false;
    }
  }

  if ( document.timeperiods.saturday.value != null && document.timeperiods.saturday.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.timeperiods.saturday.value) ) {
      document.timeperiods.saturday.focus();
      alert('Please re-enter saturday time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.timeperiods.saturday.value) ) {
      document.timeperiods.saturday.focus();
      alert('Please re-enter saturday time: Bad time value!');
      return false;
    }
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="timeperiods" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'listView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.timeperiods.catalogIDreload.value = 1;
  document.timeperiods.submit();
  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="timeperiods">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"timeperiods\">\n";
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

    print "  <input type=\"hidden\" name=\"catalogID\" value=\"$CcatalogID\">\n  <input type=\"hidden\" name=\"timeperiodID\" value=\"$CtimeperiodID\">\n" if ($formDisabledPrimaryKey ne '' and $action ne 'displayView');

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
      <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;orderBy=$orderBy">[Insert timeperiod]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all timeperiods]</a></td>
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
        </td></tr><tr><td><b>Timeperiod ID: </b></td><td>
          <input type="text" name="timeperiodID" value="$CtimeperiodID" size="2" maxlength="2" $formDisabledPrimaryKey>
        </td></tr><tr><td><b>Timeperiod Alias: </b></td><td>
          <input type="text" name="timeperiodAlias" value="$CtimeperiodAlias" size="24" maxlength="24" $formDisabledAll>
        </td></tr><tr><td><b>Timeperiod Name: </b></td><td>
          <input type="text" name="timeperiodName" value="$CtimeperiodName" size="64" maxlength="64" $formDisabledAll>
        </td></tr><tr><td><b>Sunday: </b></td><td>
          <input type="text" name="sunday" value="$Csunday" size="36" maxlength="36" $formDisabledAll> format: [00:00-24:00[,00:00-24:00]{0,2}]
        </td></tr><tr><td><b>Monday: </b></td><td>
          <input type="text" name="monday" value="$Cmonday" size="36" maxlength="36" $formDisabledAll> format: [00:00-24:00[,00:00-24:00]{0,2}]
        </td></tr><tr><td><b>Tuesday: </b></td><td>
          <input type="text" name="tuesday" value="$Ctuesday" size="36" maxlength="36" $formDisabledAll> format: [00:00-24:00[,00:00-24:00]{0,2}]
        </td></tr><tr><td><b>Wednesday: </b></td><td>
          <input type="text" name="wednesday" value="$Cwednesday" size="36" maxlength="36" $formDisabledAll> format: [00:00-24:00[,00:00-24:00]{0,2}]
        </td></tr><tr><td><b>Thursday: </b></td><td>
          <input type="text" name="thursday" value="$Cthursday" size="36" maxlength="36" $formDisabledAll> format: [00:00-24:00[,00:00-24:00]{0,2}]
        </td></tr><tr><td><b>Friday: </b></td><td>
          <input type="text" name="friday" value="$Cfriday" size="36" maxlength="36" $formDisabledAll> format: [00:00-24:00[,00:00-24:00]{0,2}]
        </td></tr><tr><td><b>Saturday: </b></td><td>
          <input type="text" name="saturday" value="$Csaturday" size="36" maxlength="36" $formDisabledAll> format: [00:00-24:00[,00:00-24:00]{0,2}]
        </td></tr><tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Timeperiod: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingTimeperiods</td></tr>" if (defined $matchingTimeperiods and $matchingTimeperiods ne '');
    } else {
      print "    <tr><td><br><table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='#333344'><tr><td align=\"left\"><b>Catalog ID: </b></td><td>$catalogIDSelect</td></tr></table></td></tr>";
      print "    <tr><td align=\"center\"><br>$matchingTimeperiods</td></tr>";
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
