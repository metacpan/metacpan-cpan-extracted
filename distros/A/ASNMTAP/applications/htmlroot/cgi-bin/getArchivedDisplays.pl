#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, getArchivedDisplay.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;
use Date::Calc qw(Add_Delta_Days);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MEMBER :DBREADONLY :DBTABLES $PERLCOMMAND $SSHCOMMAND $SSHLOGONNAME &call_system);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "getArchivedDisplay.pl";
my $prgtext     = "Get Archived Display";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $currentYear   = sprintf ("%04d", (localtime)[5] + 1900 );
my $currentMonth  = sprintf ("%02d", (localtime)[4] + 1 );
my $currentDay    = sprintf ("%02d", (localtime)[3] );

# URL Access Parameters
my $cgi = new CGI;
my $pagedir       = (defined $cgi->param('pagedir'))      ? $cgi->param('pagedir')      : 'index';    $pagedir =~ s/\+/ /g;
my $pageset       = (defined $cgi->param('pageset'))      ? $cgi->param('pageset')      : 'index-cv'; $pageset =~ s/\+/ /g;
my $debug         = (defined $cgi->param('debug'))        ? $cgi->param('debug')        : 'F';
my $CcatalogID    = (defined $cgi->param('catalogID'))    ? $cgi->param('catalogID')    : $CATALOGID;
my $CcreationDate = (defined $cgi->param('creationDate')) ? $cgi->param('creationDate') : '';
my $CcreationTime = (defined $cgi->param('creationTime')) ? $cgi->param('creationTime') : '';

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

my $htmlTitle = "Get Archived Display(s) from $CcatalogID";

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, $remoteUser, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'member', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Display Archive", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&catalogID=$CcatalogID&CcreationDate=$CcreationDate&CcreationTime=$CcreationTime";

# Debug information
print "<pre>pagedir   : $pagedir<br>pageset   : $pageset<br>debug     : $debug<br>CGISESSID : $sessionID<br>catalog ID: $CcatalogID<br>date      : $CcreationDate<br>time      : $CcreationTime<br>URL ...   : $urlAccessParameters</pre>" if ( $debug eq 'T' );

unless ( defined $errorUserAccessControl ) {
  unless ( defined $userType ) {
    print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    print "<br>\n<table WIDTH=\"100%\" border=0><tr><td class=\"HelpPluginFilename\">\n<font size=\"+1\">$errorUserAccessControl</font>\n</td></tr></table>\n<br>\n";
  } else {
    my ($rv, $dbh, $sth, $sql, $displayDaemon, $creationTime);

    # open connection to database and query data
    $rv  = 1;

    $creationTime = $CcreationDate .' '. $CcreationTime if ($CcreationDate ne '' and $CcreationTime ne '');

    if ( defined $creationTime ) {
      $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY", ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

      if ( $dbh and $rv ) {
        $sql = "select displayDaemon from $SERVERTABLDISPLAYDMNS WHERE catalogID = '$CcatalogID' and pagedir='$pageDir'";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          ($displayDaemon) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        }

        # Close database connection - - - - - - - - - - - - - - - - - - - -
        $dbh->disconnect or $rv = error_trap_DBI("Sorry, the database was unable to disconnect", $debug, '', "", '', "", '', -1, '', $sessionID);
      }
    }

    if ($rv) {
      # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      my $onload = (defined $creationTime) ? "ONLOAD=\"if (document.images) document.Progress.src='".$IMAGESURL."/spacer.gif';\"" : '';
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, $onload, 'F', "<script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/TimeParserValidator.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/AnchorPosition.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/CalendarPopup.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/date.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/PopupWindow.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\">document.write(getCalendarStyles());</script>", $sessionID);

      my $urlWithAccessParameters = "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;catalogID=$CcatalogID&CcreationDate=$CcreationDate&amp;CcreationTime=$CcreationTime";

      my ($offsetFirst, $offsetLast) = (-14, +1);
      my ($firstYear, $firstMonth, $firstDay) = Add_Delta_Days ($currentYear, $currentMonth, $currentDay, $offsetFirst);
      my ($lastYear, $lastMonth, $lastDay) = Add_Delta_Days ($currentYear, $currentMonth, $currentDay, $offsetLast);

      print <<HTML;
<script language="JavaScript" type="text/javascript" id="jsCal1Calendar">
  var cal1Calendar = new CalendarPopup("CalendarDIV");
  cal1Calendar.offsetX = 1;
  cal1Calendar.showNavigationDropdowns();
  cal1Calendar.addDisabledDates(null, "$firstYear-$firstMonth-$firstDay");
  cal1Calendar.addDisabledDates("$lastYear-$lastMonth-$lastDay", null);
</script>

<DIV ID="CalendarDIV" STYLE="position:absolute;visibility:hidden;background-color:black;layer-background-color:black;"></DIV>

<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
  var now = new Date();
  currentlyFullYear = now.getFullYear();
  currentlyMonth    = now.getMonth();
  currentlyDay      = now.getDate();
  currentlyHours    = now.getHours();
  currentlyMinutes  = now.getMinutes();
  currentlySeconds  = now.getSeconds();

  var lastEpochtime  = Date.UTC(currentlyFullYear, currentlyMonth, currentlyDay, currentlyHours, currentlyMinutes, currentlySeconds);
  var firstEpochtime = lastEpochtime + (86400000 * $offsetFirst);

  var objectRegularExpressionDateFormat = /\^20\\d\\d-\\d\\d-\\d\\d\$/;
  var objectRegularExpressionDateValue  = /\^20\\d\\d-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])\$/;

  var objectRegularExpressionTimeFormat = /\^\\d\\d:\\d\\d:\\d\\d\$/;
  var objectRegularExpressionTimeValue  = /\^[0-1]\\d|2[0-3]:[0-5]\\d:[0-5]\\d\$/;

  if ( document.getArchivedDisplays.creationDate.value != null && document.getArchivedDisplays.creationDate.value != '' ) {
    if ( ! objectRegularExpressionDateFormat.test(document.getArchivedDisplays.creationDate.value) ) {
      document.getArchivedDisplays.creationDate.focus();
      alert('Please re-enter creation date: Bad date format!');
      return false;
    } else if ( ! objectRegularExpressionDateValue.test(document.getArchivedDisplays.creationDate.value) ) {
      document.getArchivedDisplays.creationDate.focus();
      alert('Please re-enter creation date: Bad date value!');
      return false;
    }
  } else {
    document.getArchivedDisplays.creationDate.focus();
    alert('Please enter one creation date!');
    return false;
  }

  if ( document.getArchivedDisplays.creationTime.value != null && document.getArchivedDisplays.creationTime.value != '' ) {
    if ( ! objectRegularExpressionTimeFormat.test(document.getArchivedDisplays.creationTime.value) ) {
      document.getArchivedDisplays.creationTime.focus();
      alert('Please re-enter creation time: Bad time format!');
      return false;
    } else if ( ! objectRegularExpressionTimeValue.test(document.getArchivedDisplays.creationTime.value) ) {
      document.getArchivedDisplays.creationTime.focus();
      alert('Please re-enter creation time: Bad time value!');
      return false;
    }
  } else {
    document.getArchivedDisplays.creationTime.focus();
    alert('Please enter one creation time!');
    return false;
  }

  var creationEpochtime = 0;

  var creationDate      = document.getArchivedDisplays.creationDate.value;
  var creationFullYear  = creationDate.substring(0, 4);
  var creationMonth     = creationDate.substring(5, 7) - 1;
  var creationDay       = creationDate.substring(8, 10);

  var creationTime      = document.getArchivedDisplays.creationTime.value;
  var creationHours     = creationTime.substring(0, 2);
  var creationMinutes   = creationTime.substring(3, 5);
  var creationSeconds   = creationTime.substring(6, 8);

  creationEpochtime = Date.UTC(creationFullYear, creationMonth, creationDay, creationHours, creationMinutes, creationSeconds);

  if ( firstEpochtime > creationEpochtime || creationEpochtime > lastEpochtime ) {
    document.getArchivedDisplays.creationDate.focus();
    alert('Please re-enter creation date/time: Date/Time are into the allowed range!');
    return false;
  }

  return true;
}
</script>
HTML

      if ( $userType >= 1 ) {
        print <<EndOfHtml;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
        <td class="StatusItem"><a href="getArchivedReport.pl$urlWithAccessParameters">[List report archive]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="getArchivedDebug.pl$urlWithAccessParameters">[List debug archive]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="getArchivedDisplays.pl$urlWithAccessParameters">[List display archive]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="getArchivedResults.pl$urlWithAccessParameters">[List results archive]</a></td>
	  </tr></table>
	</td></tr>
  </table>
EndOfHtml
      }

      print <<EndOfHtml;
  <BR>
  <form action="$ENV{SCRIPT_NAME}" method="post" name="getArchivedDisplays" onSubmit="return validateForm();">
    <input type="hidden" name="pagedir"   value="$pagedir">
    <input type="hidden" name="pageset"   value="$pageset">
    <input type="hidden" name="debug"     value="$debug">
    <input type="hidden" name="CGISESSID" value="$sessionID">
    <table border=0>
      <tr><td><b>Catalog ID: </b></td><td>
        <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled>
      </td></tr>
      <tr>
        <td>Display Daemon: </td>
        <td>
          <b><input type="text" name="creationDate" value="$CcreationDate" size="10" maxlength="10"></b>&nbsp;<a href="#" onclick="cal1Calendar.select(document.forms[1].creationDate, 'creationDateCalendar','yyyy-MM-dd'); return false;" name="entryDateCalendar" id="creationDateCalendar"><img src="$IMAGESURL/cal.gif" alt="Calendar" border="0"></a>&nbsp;format: yyyy-mm-dd&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
          <b><input type="text" name="creationTime" value="$CcreationTime" size="8" maxlength="8" onChange="ReadISO8601time(document.forms['getArchivedDisplays'].creationTime.value);"></b> format: hh:mm:ss, 00:00:00 to 23:59:59
      </tr><tr align="left"><td align="right"><br><input type="submit" value="Go"></td><td><br><input type="reset" value="Reset"></td></tr>
    </table>
  </form>
  <HR>
EndOfHtml
    }

    if ( defined $creationTime and defined $displayDaemon ) {
      my $command = "archive cd $APPLICATIONPATH; $PERLCOMMAND ./display.pl --loop=F --creationTime=\"$creationTime\" --displayTime=T --lockMySQL=F --debug=F --hostname=$SERVERNAMEREADONLY --checklist=DisplayCT-$displayDaemon --pagedir=_loop_${remoteUser}_${pageDir}";
      print "<P class=\"RunStatusOnDemandHtmlTitle\">$htmlTitle: <font class=\"RunStatusOnDemandCommand\">$command</font></P><IMG SRC=\"".$IMAGESURL."/gears.gif\" HSPACE=\"0\" VSPACE=\"0\" BORDER=\"0\" NAME=\"Progress\" title=\"Please Wait ...\" alt=\"Please Wait ...\"><table width=\"100%\" bgcolor=\"#333344\" border=0>";

      my ($rStatus, $rStdout, $rStderr) = call_system ("$SSHCOMMAND -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=$WWWKEYPATH/.ssh/known_hosts' -i '$WWWKEYPATH/.ssh/ssh' $SSHLOGONNAME\@localhost '$command'", ($debug eq 'T') ? 1 : 0);
      $rStderr =~ s/^stdin: is not a tty//;
      chomp ($rStderr);

      if ( $rStderr ) {
        print "<tr><td><pre>Status : '$rStatus'\n\nCommand: '$command'\n\nMessage: $rStderr\n\nSTDOUT : '$rStdout'\n\nSTDERR : '$rStderr'></pre></tr></td></table>\n";
      } else {
        print "<tr><td><a href=\"$HTTPSURL/nav/_loop_${remoteUser}_${pageDir}/$pageset.html\" target=\"_blank\">$htmlTitle for $creationTime</a></tr></td></table>\n";
      }
    } else {
      print "<br>Missing Display Daemon 'date/time'<br>";
    }

    print '<BR>', "\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

