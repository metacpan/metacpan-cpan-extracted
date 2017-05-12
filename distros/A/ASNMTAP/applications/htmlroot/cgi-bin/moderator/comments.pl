#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, comments.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;
use Time::Local;
use Date::Calc qw(Add_Delta_Days);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MODERATOR :DBREADWRITE :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "comments.pl";
my $prgtext     = "Comments";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir           = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset           = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : 'moderator';  $pageset =~ s/\+/ /g;
my $debug             = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : 'F';
my $pageNo            = (defined $cgi->param('pageNo'))          ? $cgi->param('pageNo')          : 1;
my $pageOffset        = (defined $cgi->param('pageOffset'))      ? $cgi->param('pageOffset')      : 0;
my $action            = (defined $cgi->param('action'))          ? $cgi->param('action')          : 'insertView';
my $CcatalogID        = (defined $cgi->param('catalogID'))       ? $cgi->param('catalogID')       : $CATALOGID;
my $CcatalogIDreload  = (defined $cgi->param('catalogIDreload')) ? $cgi->param('catalogIDreload') : 0;
my $Cenvironment      = (defined $cgi->param('environment'))     ? $cgi->param('environment')     : 'P';
my $CenvironIDreload  = (defined $cgi->param('environIDreload')) ? $cgi->param('environIDreload') : 0;
my @CatalogIDuKeyList = $cgi->param('selected');
my $Cid               = (defined $cgi->param('id'))              ? $cgi->param('id')              : '';
my $CuKey             = (defined $cgi->param('uKey'))            ? $cgi->param('uKey')            : 'none';
my $Ctitle            = (defined $cgi->param('title'))           ? $cgi->param('title')           : '';
my $Cinstability      = (defined $cgi->param('instability'))     ? $cgi->param('instability')     : 'off';
my $Cpersistent       = (defined $cgi->param('persistent'))      ? $cgi->param('persistent')      : 'off';
my $Cdowntime         = (defined $cgi->param('downtime'))        ? $cgi->param('downtime')        : 'off';
my $CactivationDate   = (defined $cgi->param('activationDate'))  ? $cgi->param('activationDate')  : '';
my $CactivationTime   = (defined $cgi->param('activationTime'))  ? $cgi->param('activationTime')  : '';
my $CsuspentionDate   = (defined $cgi->param('suspentionDate'))  ? $cgi->param('suspentionDate')  : '';
my $CsuspentionTime   = (defined $cgi->param('suspentionTime'))  ? $cgi->param('suspentionTime')  : '';
my $CproblemSolved    = (defined $cgi->param('problemSolved'))   ? $cgi->param('problemSolved')   : 0;
my $CremoteUser       = (defined $cgi->param('remoteUser'))      ? $cgi->param('remoteUser')      : 'none';
my $CcommentData      = (defined $cgi->param('commentData'))     ? $cgi->param('commentData')     : '';

$CcommentData =~ s/"/'/g;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $catalogID_uKey, $nextAction, $catalogIDSelect, $environmentSelect, $unselected_id, $remoteUsersSelect, $CatalogIDuKeyListStatus);

# User Session and Access Control
my ($sessionID, undef, undef, undef, undef, undef, undef, $errorUserAccessControl, $remoteUserLoggedOn, undef, undef, $givenNameLoggedOn, $familyNameLoggedOn, undef, undef, $userType, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'moderator', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Comments", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&action=$action&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&environment=$Cenvironment&environIDreload=$CenvironIDreload&id=$Cid&title=$Ctitle&activationDate=$CactivationDate&activationTime=$CactivationTime&suspentionDate=$CsuspentionDate&suspentionTime=$CsuspentionTime&instability=$Cinstability&persistent=$Cpersistent&downtime=$Cdowntime&remoteUser=$CremoteUser&commentData=$CcommentData";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>page no       : $pageNo<br>page offset   : $pageOffset<br>action        : $action<br>catalog ID    : $CcatalogID<br>cat.ID reload : $CcatalogIDreload<br>id            : $Cid<br>environment   : $Cenvironment<br>env. ID reload: $CenvironIDreload<br>title         : $Ctitle<br>activationDate: $CactivationDate<br>activationTime: $CactivationTime<br>suspentionDate: $CsuspentionDate<br>suspentionTime: $CsuspentionTime<br>instability   : $Cinstability<br>persistent    : $Cpersistent<br>downtime      : $Cdowntime<br>remoteUser    : $CremoteUser<br>commentData   : $CcommentData<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  unless ( defined $userType ) {
    print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    print "<br>\n<table WIDTH=\"100%\" border=0><tr><td class=\"HelpPluginFilename\">\n<font size=\"+1\">$errorUserAccessControl</font>\n</td></tr></table>\n<br>\n";
  } else {
    $action = 'insertView' if ( $CcatalogIDreload or $CenvironIDreload );

    my $urlWithAccessParameters = $ENV{SCRIPT_NAME} ."?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID";

    my $localYear    = sprintf ("%04d", (localtime)[5] );
    my $localMonth   = sprintf ("%02d", (localtime)[4] );
    my $currentYear  = sprintf ("%04d", (localtime)[5] + 1900 );
    my $currentMonth = sprintf ("%02d", (localtime)[4] + 1 );
    my $currentDay   = sprintf ("%02d", (localtime)[3] );
    my $currentHour  = sprintf ("%02d", (localtime)[2] );
    my $currentMin   = sprintf ("%02d", (localtime)[1] );
    my $currentSec   = sprintf ("%02d", (localtime)[0] );

    my ($CactivationTimeslot, $CsuspentionTimeslot, $tsec, $tmin, $thour, $tday, $tmonth, $tyear);

    if ($CactivationDate ne '' and $CactivationTime ne '') {
      ($tyear, $tmonth, $tday) = split(/\-/, $CactivationDate);
      $tyear -= 1900; $tmonth--;
      ($thour, $tmin, $tsec) = split(/:/, $CactivationTime);
      $CactivationTimeslot = timelocal($tsec, $tmin, $thour, $tday, $tmonth, $tyear);
    } else {
      $CactivationTimeslot = '';
    }

    if ($CsuspentionDate ne '' and $CsuspentionTime ne '') {
      ($tyear, $tmonth, $tday) = split(/\-/, $CsuspentionDate);
      $tyear -= 1900; $tmonth--;
      ($thour, $tmin, $tsec) = split(/:/, $CsuspentionTime);
      $CsuspentionTimeslot = timelocal($tsec, $tmin, $thour, $tday, $tmonth, $tyear);
    } else {
      $CsuspentionTimeslot = '';
    }

    $nextAction = ($action eq 'insertView' ? 'insert' : 'insertView');

    # open connection to database and query data
    $rv  = 1;

    $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

    if ($dbh) {
      if ( $action eq 'insertView' ) {
        $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
        ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:catalogIDsubmitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

        $environmentSelect = '<select name="environment" size="1" onChange="javascript:environIDsubmitForm();"><option value="P"'. ($Cenvironment eq 'P' ? ' selected' : '') .'>Production</option><option value="A"'. ($Cenvironment eq 'A' ? ' selected' : '') .'>Acceptation</option><option value="S"'. ($Cenvironment eq 'S' ? ' selected' : '') .'>Simulation</option><option value="T"'. ($Cenvironment eq 'T' ? ' selected' : '') .'>Test</option></select>';

        $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.environment = '$Cenvironment' and production = 1 and activated = 1 and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by optionValueTitle";
        ($rv, $unselected_id) = create_combobox_multiple_from_DBI ($rv, $dbh, $sql, $action, $CuKey, 'unselected', 'uKey', 10, 64, 0, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

        if ( defined $remoteUserLoggedOn ) {
          $CremoteUser = $remoteUserLoggedOn;
          $sql = "select remoteUser, email from $SERVERTABLUSERS where catalogID = '$CcatalogID' and remoteUser = '$CremoteUser'";
        } else {
          my $andActivated = ($action eq 'insertView') ? 'and activated = 1' : '';
          $sql = "select remoteUser, email from $SERVERTABLUSERS where catalogID = '$CcatalogID' and pagedir REGEXP '/$pagedir/' and remoteUser <> 'admin' and remoteUser <> 'sadmin' $andActivated order by email";
        }

        ($rv, $remoteUsersSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 0, '', $CremoteUser, 'remoteUser', 'none', '-Select-', '', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      } else {
        my $CentryDate     = "$currentYear-$currentMonth-$currentDay";
        my $CentryTime     = "$currentHour:$currentMin:$currentSec";
        my $CentryTimeslot = timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear);

        if ($CactivationDate eq '' or $CactivationTime eq '') {
          $CactivationDate     = $CentryDate;
          $CactivationTime     = $CentryTime;
          $CactivationTimeslot = $CentryTimeslot;
        }

        if ($CsuspentionDate eq '' or $CsuspentionTime eq '') {
          $CsuspentionDate     = "0000-00-00";
          $CsuspentionTime     = "00:00:00";
          $CsuspentionTimeslot = "9999999999";
        }

        my $dummyInstability = ($Cinstability eq 'on') ? 1 : 0;
        my $dummyPersistent  = ($Cpersistent  eq 'on') ? 1 : 0;
        my $dummyDowntime    = ($Cdowntime    eq 'on') ? 1 : 0;

        foreach $catalogID_uKey (@CatalogIDuKeyList) {
          my ($catalogID, $uKey) = split(/_/, $catalogID_uKey);

          unless ( defined $uKey ) {
            $uKey = $catalogID;
            $catalogID = $CcatalogID;
          }

          ($rv, $Ctitle) = get_title( $dbh, $rv, $catalogID, $uKey, $debug, -1, $sessionID );
          $CatalogIDuKeyListStatus .= "<tr><td>$uKey from $catalogID</td>";

          if ($rv and defined $Ctitle) {
            $sql = 'INSERT INTO ' .$SERVERTABLCOMMENTS. ' SET catalogID="' .$catalogID. '", uKey="' .$uKey. '", replicationStatus="I", title="' .$Ctitle. '", entryDate="' .$CentryDate. '", entryTime="' .$CentryTime.'", entryTimeslot="' .$CentryTimeslot. '", instability="' .$dummyInstability. '", persistent="' .$dummyPersistent. '", downtime="' .$dummyDowntime. '", problemSolved="0", solvedDate="0000-00-00", solvedTime="00:00:00", solvedTimeslot="", remoteUser="' .$CremoteUser. '", commentData="MULTIPLE COMMENTS: ' .$CcommentData. '", activationDate="' .$CactivationDate. '", activationTime="' .$CactivationTime. '", activationTimeslot="' .$CactivationTimeslot. '", suspentionDate="' .$CsuspentionDate. '", suspentionTime="' .$CsuspentionTime. '", suspentionTimeslot="' .$CsuspentionTimeslot. '"';
            $CatalogIDuKeyListStatus .= "<td>$Ctitle</td></tr>";

            if ( $debug eq 'F' ) {
              $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
            } else {
              $CatalogIDuKeyListStatus .= "<tr><td>&nbsp;</td><td>$sql</td></tr>";
            } 
          } else {
            $CatalogIDuKeyListStatus .= "<td>NOT found</td></tr>";
          }
        }
      }

      $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
    }

    if ( $rv ) {
      # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      if ($action eq 'insertView') {
        print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', "<script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/TimeParserValidator.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/AnchorPosition.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/CalendarPopup.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/date.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/PopupWindow.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\">document.write(getCalendarStyles());</script>", $sessionID);

        my ($firstYear, $firstMonth, $firstDay) = Add_Delta_Days ($currentYear, $currentMonth, $currentDay, -1);

        print <<HTML;
<script language="JavaScript" type="text/javascript" id="jsListbox">
  var NS4 = (navigator.appName == "Netscape" && parseInt(navigator.appVersion) < 5);

  function addOption(theSel, theText, theValue) {
    var newOpt = new Option(theText, theValue);
    var selLength = theSel.length;
    theSel.options[selLength] = newOpt;
  }

  function deleteOption(theSel, theIndex) { 
    var selLength = theSel.length;

    if(selLength>0) {
      theSel.options[theIndex] = null;
    }
  }

  function moveOptions(theSelFrom, theSelTo, moveAll) {
    var selLength = theSelFrom.length;
    var selectedText = new Array();
    var selectedValues = new Array();
    var selectedCount = 0;
    var i;

    // Find the selected Options in reverse order and delete them from the 'from' Select.
    for(i=selLength-1; i>=0; i--) {
      if(theSelFrom.options[i].selected || moveAll) {
        selectedText[selectedCount] = theSelFrom.options[i].text;
        selectedValues[selectedCount] = theSelFrom.options[i].value;
        deleteOption(theSelFrom, i);
        selectedCount++;
      }
    }
  
    // Add the selected text/values in reverse order.
    // This will add the Options to the 'to' Select in the same order as they were in the 'from' Select.
    for(i=selectedCount-1; i>=0; i--) {
      addOption(theSelTo, selectedText[i], selectedValues[i]);
    }
  
    if(NS4) history.go(0);
  }

  function selectAllOptions(selStr) {
    var selObj = document.getElementById(selStr);

    for (var i=0; i<selObj.options.length; i++) {
      selObj.options[i].selected = true;
    }
  }
</script>

<script language="JavaScript" type="text/javascript" id="jsCal1Calendar">
  var cal1Calendar = new CalendarPopup("CalendarDIV");
  cal1Calendar.offsetX = 1;
  cal1Calendar.showNavigationDropdowns();
  cal1Calendar.addDisabledDates(null, "$firstYear-$firstMonth-$firstDay");
</script>

<DIV ID="CalendarDIV" STYLE="position:absolute;visibility:hidden;background-color:black;layer-background-color:black;"></DIV>

<script language="JavaScript1.2" type="text/javascript">
function catalogIDsubmitForm() {
  document.comments.catalogIDreload.value = 1;
  document.comments.submit();
  return true;
}

function environIDsubmitForm() {
  document.comments.environIDreload.value = 1;
  document.comments.submit();
  return true;
}

function validateForm() {
  var now = new Date();
  currentlyFullYear = now.getFullYear();
  currentlyMonth    = now.getMonth();
  currentlyDay      = now.getDate();
  currentlyHours    = now.getHours();
  currentlyMinutes  = now.getMinutes();
  currentlySeconds  = now.getSeconds();

  var nowEpochtime  = Date.UTC(currentlyFullYear, currentlyMonth, currentlyDay, currentlyHours, currentlyMinutes, currentlySeconds);

  var objectRegularExpressionDateFormat = /\^20\\d\\d-\\d\\d-\\d\\d\$/;
  var objectRegularExpressionDateValue  = /\^20\\d\\d-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])\$/;

  var objectRegularExpressionTimeFormat = /\^\\d\\d:\\d\\d:\\d\\d\$/;
  var objectRegularExpressionTimeValue  = /\^[0-1]\\d|2[0-3]:[0-5]\\d:[0-5]\\d\$/;

  if( document.comments.remoteUser.options[document.comments.remoteUser.selectedIndex].value == 'none' ) {
    document.comments.remoteUser.focus();
    alert('Please create/select one of the remote users!');
    return false;
  }

  if ( document.comments.commentData.value == null || document.comments.commentData.value == '' ) {
    document.comments.commentData.focus();
    alert('Please enter a comment!');
    return false;
  }

  if ( document.comments.activationDate.value != null && document.comments.activationDate.value != '' ) {
    if ( ! objectRegularExpressionDateFormat.test(document.comments.activationDate.value) ) {
      document.comments.activationDate.focus();
      alert('Please re-enter activation date: Bad date format!');
      return false;
    }

    if ( ! objectRegularExpressionDateValue.test(document.comments.activationDate.value) ) {
      document.comments.activationDate.focus();
      alert('Please re-enter activation date: Bad date value!');
      return false;
    }
  }

  if ( ( document.comments.activationDate.value == '' && document.comments.activationTime.value != '' ) || ( document.comments.activationDate.value != '' && document.comments.activationTime.value == '' ) ) {
    if ( document.comments.activationDate.value == '' ) {
      document.comments.activationDate.focus();
      alert('Please enter one activation date!');
    } else {
      document.comments.activationTime.focus();
      alert('Please enter one activation time!');
    }

    return false;
  } else if ( document.comments.activationDate.value != '' && document.comments.activationTime.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.comments.activationTime.value) ) {
      document.comments.activationTime.focus();
      alert('Please re-enter activation time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.comments.activationTime.value) ) {
      document.comments.activationTime.focus();
      alert('Please re-enter activation time: Bad time value!');
      return false;
    }
  }

  var activationEpochtime = 0;

  if ( document.comments.activationTime.value != null && document.comments.activationTime.value != '' ) {
    activationDate      = document.comments.activationDate.value;
    activationFullYear  = activationDate.substring(0, 4);
    activationMonth     = activationDate.substring(5, 7) - 1;
    activationDay       = activationDate.substring(8, 10);
    activationTime      = document.comments.activationTime.value;
    activationHours     = activationTime.substring(0, 2);
    activationMinutes   = activationTime.substring(3, 5);
    activationSeconds   = activationTime.substring(6, 8);
    activationEpochtime = Date.UTC(activationFullYear, activationMonth, activationDay, activationHours, activationMinutes, activationSeconds);

    if ( nowEpochtime > activationEpochtime ) {
      document.comments.activationDate.focus();
      alert('Please re-enter activation date/time: Date/Time are into the past!');
      return false;
    }
  } else {
    activationEpochtime = nowEpochtime;
  }

  if ( document.comments.suspentionDate.value != null && document.comments.suspentionDate.value != '' ) {
    if ( ! objectRegularExpressionDateFormat.test(document.comments.suspentionDate.value) ) {
      document.comments.suspentionDate.focus();
      alert('Please re-enter suspention date: Bad date format!');
      return false;
    }

    if ( ! objectRegularExpressionDateValue.test(document.comments.suspentionDate.value) ) {
      document.comments.suspentionDate.focus();
      alert('Please re-enter suspention date: Bad date value!');
      return false;
    }
  }

  if ( ( document.comments.suspentionDate.value == '' && document.comments.suspentionTime.value != '' ) || ( document.comments.suspentionDate.value != '' && document.comments.suspentionTime.value == '' ) ) {
    if ( document.comments.suspentionDate.value == '' ) {
      document.comments.suspentionDate.focus();
      alert('Please enter one suspention date!');
    } else {
      document.comments.suspentionTime.focus();
      alert('Please enter one suspention time!');
    }

    return false;
  } else if ( document.comments.suspentionDate.value != '' && document.comments.suspentionTime.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.comments.suspentionTime.value) ) {
      document.comments.suspentionTime.focus();
      alert('Please re-enter suspention time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.comments.suspentionTime.value) ) {
      document.comments.suspentionTime.focus();
      alert('Please re-enter suspention time: Bad time value!');
      return false;
    }
  }

  var suspentionEpochtime = 0;

  if ( document.comments.suspentionTime.value != null && document.comments.suspentionTime.value != '' ) {
    suspentionDate      = document.comments.suspentionDate.value;
    suspentionFullYear  = suspentionDate.substring(0, 4);
    suspentionMonth     = suspentionDate.substring(5, 7) - 1;
    suspentionDay       = suspentionDate.substring(8, 10);
    suspentionTime      = document.comments.suspentionTime.value;
    suspentionHours     = suspentionTime.substring(0, 2);
    suspentionMinutes   = suspentionTime.substring(3, 5);
    suspentionSeconds   = suspentionTime.substring(6, 8);
    suspentionEpochtime = Date.UTC(suspentionFullYear, suspentionMonth, suspentionDay, suspentionHours, suspentionMinutes, suspentionSeconds);

    if ( nowEpochtime > suspentionEpochtime ) {
      document.comments.suspentionDate.focus();
      alert('Please re-enter suspention date/time: Date/Time are into the past!');
      return false;
    }
  }

  if ( activationEpochtime != 0 && suspentionEpochtime != 0 ) {
    if ( activationEpochtime > suspentionEpochtime ) {
      document.comments.activationDate.focus();
      alert('Please re-enter activation/suspention date/time: Activation Date/Time > Suspention Date/Time !');
      return false;
    }
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="comments" enctype="multipart/form-data" onSubmit="selectAllOptions('selected_id'); return validateForm();">
  <input type="hidden" name="pagedir"         value="$pagedir">
  <input type="hidden" name="pageset"         value="$pageset">
  <input type="hidden" name="debug"           value="$debug">
  <input type="hidden" name="CGISESSID"       value="$sessionID">
  <input type="hidden" name="pageNo"          value="$pageNo">
  <input type="hidden" name="pageOffset"      value="$pageOffset">
  <input type="hidden" name="action"          value="$nextAction">
  <input type="hidden" name="catalogIDreload" value="0">
  <input type="hidden" name="environIDreload" value="0">
HTML
      } else {
        print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
        print "<br>\n";
      }

      print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
HTML

      if ( $action eq 'insert' and $userType != 0 ) {
        print <<HTML;
    <tr align="center"><td colspan="2">
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView">[Insert comments]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
	  </tr></table>
	</td></tr>
HTML
      }

      print "<tr><td colspan=\"2\">&nbsp;</td></tr>";

      if ($action eq 'insertView') {
        my $instabilityDisabled = ($userType < 2) ? 'disabled' : '';
        my $persistentDisabled  = ($userType < 2) ? 'disabled' : '';
        my $downtimeDisabled    = ($userType < 2) ? 'disabled' : '';

        my $instabilityChecked  = ($Cinstability eq 'on') ? ' checked' : '';
        my $persistentChecked   = ($Cpersistent  eq 'on') ? ' checked' : '';
        my $downtimeChecked     = ($Cdowntime    eq 'on') ? ' checked' : '';

        print <<HTML;
    <tr><td><table border="0" cellspacing="0" cellpadding="0">
      <tr><td><b>Catalog ID: </b></td><td>
        <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled> $catalogIDSelect
      </td></tr>
      <tr><td><b>Environment: </b></td><td>
        $environmentSelect
      </td></tr>
      <tr><td valign="top"><b>Applications uKey List: </b></td><td>
      	<table border="0" cellspacing="0" cellpadding="0"><tr><td valign="top">Available:<br>
          $unselected_id
        </td><td>
          <input type="image" src="$IMAGESURL/1moveLeft.png"  alt="Move item to left"       title="Move item to left"       onclick="moveOptions(this.form.selected_id,   this.form.unselected_id, false); selectAllOptions('selected_id'); return false;">
      	  <input type="image" src="$IMAGESURL/1moveRight.png" alt="Move item to right"      title="Move item to right"      onclick="moveOptions(this.form.unselected_id, this.form.selected_id,   false); selectAllOptions('selected_id'); return false;"><br>
        	<input type="image" src="$IMAGESURL/2moveLeft.png"  alt="Move all items to left"  title="Move all items to left"  onclick="moveOptions(this.form.selected_id,   this.form.unselected_id, true);  selectAllOptions('selected_id'); return false;">
      	  <input type="image" src="$IMAGESURL/2moveRight.png" alt="Move all items to right" title="Move all items to right" onclick="moveOptions(this.form.unselected_id, this.form.selected_id,   true);  selectAllOptions('selected_id'); return false;"><br>
        </td><td valign="top">Selected:<br>
          <select name="selected" id="selected_id" size="10" multiple></select>
        </td></tr></table>
      </td></tr><tr><td><b>Remote User: </b></td><td>
        $remoteUsersSelect
      </td>
      </tr><tr>
        <td valign="top"><b>Comment: </b></td>
        <td><textarea name=commentData cols=84 rows=10>$CcommentData</textarea></td>
      </tr><tr>
        <td><b>Instability: </b></td>
        <td><b><input type="checkbox" name="instability" $instabilityChecked $instabilityDisabled></b> 'checked' means 'instability' and 'not checked' means 'not instability'</td>
      </tr><tr>
        <td><b>Persistent: </b></td>
        <td><b><input type="checkbox" name="persistent" $persistentChecked $persistentDisabled></b> 'checked' means 'persistent' and 'not checked' means 'not persistent'</td>
      </tr><tr><td>&nbsp;</td><td>
        When 'Instability' and 'Persistent' are checked, this 'comment' will be not visible into the 'Minimal Condenced View'
		</td>
      </tr><tr>
        <td><b>Downtime: </b></td>
        <td><b><input type="checkbox" name="downtime" $downtimeChecked $downtimeDisabled></b> 'checked' means 'downtime scheduling' and 'not checked' means 'no downtime scheduling'</td>
      </tr><tr>
        <td>Activation: </td>
        <td>
          <b><input type="text" name="activationDate" value="$CactivationDate" size="10" maxlength="10"></b>&nbsp;
		      <a href="#" onclick="cal1Calendar.select(document.forms[0].activationDate, 'activationDateCalendar','yyyy-MM-dd'); return false;" name="activationDateCalendar" id="activationDateCalendar"><img src="$IMAGESURL/cal.gif" alt="Calendar" border="0"></a>&nbsp;format: yyyy-mm-dd&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
          <b><input type="text" name="activationTime" value="$CactivationTime" size="8" maxlength="8" onChange="ReadISO8601time(document.forms['comments'].activationTime.value);"></b> format: hh:mm:ss, 00:00:00 to 23:59:59
		    </td>
      </tr><tr>
        <td>Suspention: </td>
        <td>
          <b><input type="text" name="suspentionDate" value="$CsuspentionDate" size="10" maxlength="10"></b>&nbsp;
		      <a href="#" onclick="cal1Calendar.select(document.forms[0].suspentionDate, 'suspentionDateCalendar','yyyy-MM-dd'); return false;" name="suspentionDateCalendar" id="suspentionDateCalendar"><img src="$IMAGESURL/cal.gif" alt="Calendar" border="0"></a>&nbsp;format: yyyy-mm-dd&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
          <b><input type="text" name="suspentionTime" value="$CsuspentionTime" size="8" maxlength="8" onChange="ReadISO8601time(document.forms['comments'].suspentionTime.value);"></b> format: hh:mm:ss, 00:00:00 to 23:59:59
		    </td>
      </tr><tr><td>&nbsp;</td><td>
        <br>
        <b>Problem automatically solved when</b> ('not persistent' has higher priority then 'persistent')<b>:</b>
        <ul type="circle">
          <li>instability:
            <ul type="disc">
              <li>problem is <b>never</b> automatically solved</li>
            </ul>
          </li>
          <li>not persistent:
            <ul type="disc">
              <li>problem is automatically solved when 'last n results are OK' and 'current Timeslot' > 'Activation Date/time'</li>
        	  <li>problem is automatically solved when 'current Timeslot' > 'Suspention Date/time'</li>
            </ul>
          </li>
          <li>persistent:
            <ul type="disc">
              <li>problem is automatically solved when 'current Timeslot' > 'Suspention Date/time'</li>
              <li>problem is <b>never</b> automatically solved when 'Suspention Date/time' is missing</li>
            </ul>
          </li>
        </ul></td>
      </tr><tr><td>&nbsp;</td><td>Please enter all required information before committing the command. Required fields are marked in bold.</td>
      </tr><tr align="left"><td align="right"><br><input type="submit" value="Insert"></td><td><br><input type="reset" value="Reset"></td></tr>
	</table></td></tr>
HTML
      } else {
        print "<tr><td colspan=\"2\"><b>uKey from CatalogID overview:</b><br><br>$CatalogIDuKeyListStatus</td></tr>\n";
      }

      print "  </table>\n";

      if ($action eq 'insertView') {
        print "</form>\n";
      } else {
        print "<br>\n";
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
