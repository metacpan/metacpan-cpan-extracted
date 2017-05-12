#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl for ASNMTAP::Asnmtap::Applications::CGI
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
use Date::Calc qw(Add_Delta_Days Delta_DHMS Week_of_Year);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :REPORTS :DBPERFPARSE :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "detailedStatisticsReportGenerationAndCompareResponsetimeTrends.pl";
my $prgtext     = "Detailed Statistics, Report Generation And Compare Response Time Trends";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin, $currentSec) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1,0]);
my $now         = "$currentYear-$currentMonth-$currentDay ($currentHour:$currentMin:$currentSec)";
my $startTime   = timelocal($currentSec, $currentMin, $currentHour, $currentDay, $localMonth, $localYear);
my $endDate;

# URL Access Parameters
my $cgi = new CGI;
my $pagedir          = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : 'index'; $pagedir =~ s/\+/ /g;
my $pageset          = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : 'index-cv'; $pageset =~ s/\+/ /g;
my $debug            = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : 'F';
my $selDetailed      = (defined $cgi->param('detailed'))        ? $cgi->param('detailed')        : 'on';
my $CcatalogID       = (defined $cgi->param('catalogID'))       ? $cgi->param('catalogID')       : $CATALOGID;
my $CcatalogIDreload = (defined $cgi->param('catalogIDreload')) ? $cgi->param('catalogIDreload') : 0;
my $uKey1            = (defined $cgi->param('uKey1'))           ? $cgi->param('uKey1')           : 'none';
my $uKey2            = (defined $cgi->param('uKey2'))           ? $cgi->param('uKey2')           : 'none';
my $uKey3            = (defined $cgi->param('uKey3'))           ? $cgi->param('uKey3')           : 'none';
my $startDate        = (defined $cgi->param('startDate'))       ? $cgi->param('startDate')       : "$currentYear-$currentMonth-$currentDay";
my $inputType        = (defined $cgi->param('inputType'))       ? $cgi->param('inputType')       : 'fromto';
my $selYear          = (defined $cgi->param('year'))            ? $cgi->param('year')            : 0;
my $selWeek          = (defined $cgi->param('week'))            ? $cgi->param('week')            : 0;
my $selMonth         = (defined $cgi->param('month'))           ? $cgi->param('month')           : 0;
my $selQuarter       = (defined $cgi->param('quarter'))         ? $cgi->param('quarter')         : 0;
my $timeperiodID     = (defined $cgi->param('timeperiodID'))    ? $cgi->param('timeperiodID')    : 1;
my $statuspie        = (defined $cgi->param('statuspie'))       ? $cgi->param('statuspie')       : 'off';
my $errorpie         = (defined $cgi->param('errorpie'))        ? $cgi->param('errorpie')        : 'off';
my $bar              = (defined $cgi->param('bar'))             ? $cgi->param('bar')             : 'off';
my $hourlyAvg        = (defined $cgi->param('hourlyAvg'))       ? $cgi->param('hourlyAvg')       : 'off';
my $dailyAvg         = (defined $cgi->param('dailyAvg'))        ? $cgi->param('dailyAvg')        : 'off';
my $details          = (defined $cgi->param('details'))         ? $cgi->param('details')         : 'off';
my $comments         = (defined $cgi->param('comments'))        ? $cgi->param('comments')        : 'off';
my $perfdata         = (defined $cgi->param('perfdata'))        ? $cgi->param('perfdata')        : 'off';
my $topx             = (defined $cgi->param('topx'))            ? $cgi->param('topx')            : 'off';
my $pf               = (defined $cgi->param('pf'))              ? $cgi->param('pf')              : 'off';
my $formatOutput     = (defined $cgi->param('formatOutput'))    ? $cgi->param('formatOutput')    : 'html';
my $htmlToPdf        = (defined $cgi->param('htmlToPdf'))       ? $cgi->param('htmlToPdf')       : 0;

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

if ( defined $cgi->param('endDate') and $cgi->param('endDate') ) { $endDate = $cgi->param('endDate'); } else { $endDate = ''; }
my $htmlTitle   = ( ( $selDetailed eq 'on' ) ? 'Detailed Statistics and Report Generation' : 'Compare Response Time Trends' );

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Reports", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&detailed=$selDetailed&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&uKey1=$uKey1&uKey2=$uKey2&uKey3=$uKey3&startDate=$startDate&endDate=$endDate&inputType=$inputType&year=$selYear&week=$selWeek&month=$selMonth&quarter=$selQuarter&timeperiodID=$timeperiodID&statuspie=$statuspie&errorpie=$errorpie&bar=$bar&hourlyAvg=$hourlyAvg&dailyAvg=$dailyAvg&details=$details&comments=$comments&perfdata=$perfdata&topx=$topx&pf=$pf";

# Debug information
print "<pre>pagedir     : $pagedir<br>pageset     : $pageset<br>debug       : $debug<br>CGISESSID   : $sessionID<br>detailed    : $selDetailed<br>catalog ID  : $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br>uKey1       : $uKey1<br>uKey2       : $uKey2<br>uKey3       : $uKey3<br>startDate   : $startDate<br>endDate     : $endDate<br>inputType   : $inputType<br>selYear     : $selYear<br>selWeek     : $selWeek<br>selMonth    : $selMonth<br>selQuarter  : $selQuarter<br>SLA window  : $timeperiodID<br>statuspie   : $statuspie<br>errorpie    : $errorpie<br>bar         : $bar<br>hourlyAvg   : $hourlyAvg<br>dailyAvg    : $dailyAvg<br>details     : $details<br>comments    : $comments<br>perfdata    : $perfdata<br>topx        : $topx<br>pf          : $pf<br>formatOutput: $formatOutput<br>htmlToPdf   : $htmlToPdf<br>URL ...     : $urlAccessParameters</pre>" if ( $debug eq 'T' );

unless ( defined $errorUserAccessControl ) {
  if ( $formatOutput eq 'pdf' and ! $htmlToPdf ) {
    my $url = "$HTTPSURL/cgi-bin/htmlToPdf.pl?HTMLtoPDFprg=$HTMLTOPDFPRG&amp;HTMLtoPDFhow=$HTMLTOPDFHOW&amp;scriptname=". $ENV{SCRIPT_NAME} ."&amp;". encode_html_entities('U', $urlAccessParameters);

    print <<EndOfHtml;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">  
<html>
<head>
  <title>$htmlTitle</title>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
  <META HTTP-EQUIV="refresh" content="1;url=$url">
  <link rel="stylesheet" type="text/css" href="$HTTPSURL/asnmtap.css">
</head>
<BODY>
</BODY>
</HTML>
EndOfHtml

    exit;
  }

  my ($rv, $dbh, $sth, $uKey, $sqlQuery, $sqlSelect, $sqlAverage, $sqlInfo, $sqlErrors, $sqlWhere, $sqlPeriode);
  my ($printerFriendlyOutputBox, $formatOutputSelect, $catalogIDSelect, $uKeySelect1, $uKeySelect2, $uKeySelect3, $images);
  my ($subtime, $endTime, $duration, $seconden, $status, $statusMessage, $title, $Title, $shortDescription, $rest, $dummy, $count);
  my ($averageQ, $numbersOfTestsQ, $startDateQ, $stepQ, $endDateQ, $errorMessage, $chartOrTableChecked);
  my ($checkbox, $tables, $shortDescriptionTextArea, $infoTable, $topxTable, $errorList, $errorDetailList, $commentDetailList, $perfdataDetailList, $responseTable, $goodDate);
  my ($fromto, $years, $weeks, $months, $quarters, $slaWindows, $selectedYear, $selectedWeek, $selectedMonth, $selectedQuarter, $slaWindow, $i);
  my @arrMonths = qw(January Februari March April May June July August September October November December);

  # open connection to database and query data
  $rv  = 1;
  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ( $dbh and $rv ) {
    $uKey1 = $uKey2 = $uKey3 = 'none' if ( $CcatalogIDreload );

    $sqlQuery = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
    ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sqlQuery, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

    $sqlQuery = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where $SERVERTABLPLUGINS.catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.environment = '$environment' and pagedir REGEXP '/$pageDir/' and production = '1' and activated = 1 and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by optionValueTitle";
    $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlQuery", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
    $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlQuery", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
    $sth->bind_columns( \$uKey, \$title) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sqlQuery", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

    if ( $rv ) {
      $dummy = ($uKey1 eq 'none') ? " selected" : '';
      $uKeySelect1 = "          <option value=\"none\"$dummy>-Select-</option>\n";

      $dummy = ($uKey2 eq 'none') ? " selected" : '';
      $uKeySelect2 .= "          <option value=\"none\"$dummy>-Select-</option>\n";

      $dummy = ($uKey3 eq 'none') ? " selected" : '';
      $uKeySelect3 .= "          <option value=\"none\"$dummy>-Select-</option>\n";

      while( $sth->fetch() ) {
        if ($uKey eq $uKey1 and $selDetailed eq 'on') {
          $htmlTitle = "Results for $title from $CcatalogID";
	      $Title = "$title from $CcatalogID";
        }

        $dummy = ($uKey eq $uKey1) ? " selected" : '';
        $uKeySelect1 .= "          <option value=\"$uKey\"$dummy>$title</option>\n";

        $dummy = ($uKey eq $uKey2) ? " selected" : '';
        $uKeySelect2 .= "          <option value=\"$uKey\"$dummy>$title</option>\n";
	
        $dummy = ($uKey eq $uKey3) ? " selected" : '';
        $uKeySelect3 .= "          <option value=\"$uKey\"$dummy>$title</option>\n";
      }

      $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

      if ($htmlToPdf) {
        print <<EndOfHtml;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">  
<html>
<head>
  <title>$htmlTitle</title>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" href="$HTTPSURL/asnmtap.css">
</head>
<BODY TEXT="#000000">
EndOfHtml
      } else {
        print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', "<script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/AnchorPosition.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/CalendarPopup.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/date.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/PopupWindow.js\"></script>\n  <script type=\"text/javascript\" language=\"JavaScript\">document.write(getCalendarStyles());</script>", $sessionID);
      }

      # Section: FromTo
      $dummy  = ($inputType eq "fromto") ? ' checked' : '';
      $fromto = "<input type=\"radio\" name=\"inputType\" value=\"fromto\"$dummy>From:";

      # Section: Years
      $dummy  = ($inputType eq "year") ? ' checked' : '';
      $years  = "<input type=\"radio\" name=\"inputType\" value=\"year\"$dummy>Year:</td><td>\n";
      $years .= "        <select name=\"year\">\n";
      ($selectedWeek, $selectedYear) = Week_of_Year( $currentYear, $currentMonth, $currentDay );
      $selectedYear = $selYear if ($selYear != 0);

      my ($firstSelectedYear, undef, undef) = split (/-/, $FIRSTSTARTDATE);

      for ($i = $firstSelectedYear; $i <= $currentYear; $i++) {
        $dummy = ($i == $selectedYear) ? " selected" : '';
        $years .= "          <option value=\"". $i ."\"$dummy>". $i ."</option>\n";
      }

      $years .= "        </select>";

      # Section: Weeks
      $dummy = ($inputType eq "week") ? ' checked' : '';
      $weeks = "<input type=\"radio\" name=\"inputType\" value=\"week\"$dummy>Week:</td><td>";
      $weeks .= "        <select name=\"week\">\n";
      $selectedWeek = $selWeek if ($selWeek != 0);

      for ($i = 1; $i <= 53; $i++) {
        $dummy = ($i == $selectedWeek) ? " selected" : '';
        $weeks .= "          <option value=\"". $i ."\"$dummy>". $i ."</option>\n";
      }

      $weeks .= "        </select>\n";

      # Section: Months
      $dummy  = ($inputType eq "month") ? ' checked' : '';
      $months = "<input type=\"radio\" name=\"inputType\" value=\"month\"$dummy>Month:</td><td>\n";
      $months .= "        <select name=\"month\">\n";
      $selectedMonth = ($selMonth == 0) ? $localMonth : $selMonth - 1;

      for ($i = 0; $i < 12; $i++) {
        $dummy = ($i == $selectedMonth) ? " selected" : '';
        $months .= "          <option value=\"". ($i+1) ."\"$dummy>". $arrMonths[$i] ."</option>\n";
      }

      $months .= "        </select>\n";

      # Section: Quarters
      $dummy     = ($inputType eq "quarter") ? ' checked' : '';
      $quarters  = "<input type=\"radio\" name=\"inputType\" value=\"quarter\"$dummy>Quarter:</td><td>\n";
      $quarters .= "        <select name=\"quarter\">\n";
      $selectedQuarter = ($selQuarter == 0) ?  (int (($localMonth + 2) / 3)) : $selQuarter;

      for ($i = 1; $i <= 4; $i++) {
        $dummy = ($i == $selectedQuarter) ? " selected" : '';
        $quarters .= "          <option value=\"". $i ."\"$dummy>". $i ."</option>\n";
      }

      $quarters .= "        </select>\n";

      # Section: SLA windows
      ($rv, $slaWindows, undef) = create_combobox_from_DBI ($rv, $dbh, "select SQL_NO_CACHE timeperiodID, timeperiodName from $SERVERTABLTIMEPERIODS where catalogID = '$CcatalogID' and activated = 1 order by timeperiodName", 1, '', $timeperiodID, 'timeperiodID', '', '', '', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $sqlPeriode = '';

      if ( $timeperiodID > 1 ) {
        $sqlQuery = "select SQL_NO_CACHE timeperiodName, sunday, monday, tuesday, wednesday, thursday, friday, saturday from $SERVERTABLTIMEPERIODS where catalogID = '$CcatalogID' and timeperiodID = '$timeperiodID'";
        $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sqlQuery", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sqlQuery", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          ($slaWindow, my ($sunday, $monday, $tuesday, $wednesday, $thursday, $friday, $saturday)) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sqlQuery", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sqlQuery", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
          $sqlPeriode = create_sql_query_from_range_SLA_window ($sunday, $monday, $tuesday, $wednesday, $thursday, $friday, $saturday);
        }
      }

      # Components for the selection of the charts  - - - - - - - - - - - -
      $checkbox = $tables = '';
      $chartOrTableChecked = 0;
      $errorMessage = "<br>Select application<br>\n" if ($uKey1 eq 'none');

      if ( $selDetailed eq 'on') {
        if ($statuspie eq 'on') {
          $dummy = " checked";
          $chartOrTableChecked = 1;
          $images .= "<br><center><img src=$HTTPSURL/cgi-bin/generateChart.pl?chart=Status&amp;".encode_html_entities('U', $urlAccessParameters)."></center>\n" if ($uKey1 ne 'none');
        } else {
          $dummy = '';
        }

        $checkbox .= "        <input type=\"checkbox\" name=\"statuspie\"$dummy> Status\n";

        if ($errorpie eq 'on') {
          $dummy = " checked";
          $chartOrTableChecked = 1;
          $images .= "<br><center><img src=$HTTPSURL/cgi-bin/generateChart.pl?chart=ErrorDetails&amp;".encode_html_entities('U', $urlAccessParameters)."></center>\n" if ($uKey1 ne 'none');
        } else {
          $dummy = '';
        }

        $checkbox .= "        <input type=\"checkbox\" name=\"errorpie\"$dummy> Error Details\n";

        if ($bar eq 'on') {
          $dummy = " checked";
          $chartOrTableChecked = 1;
          $images .= "<br><center><img src=$HTTPSURL/cgi-bin/generateChart.pl?chart=Bar&amp;".encode_html_entities('U', $urlAccessParameters)."></center>\n" if ($uKey1 ne 'none');
        } else {
          $dummy = '';
        }

        $checkbox .= "        <input type=\"checkbox\" name=\"bar\"$dummy> Bar\n";
      }

      if ($hourlyAvg eq 'on') {
        $dummy = " checked";
        $chartOrTableChecked = 1;
        $images .= "<br><center><img src=$HTTPSURL/cgi-bin/generateChart.pl?chart=HourlyAverage&amp;".encode_html_entities('U', $urlAccessParameters)."></center>\n" if ($uKey1 ne 'none');
      } else {
        $dummy = '';
      }
			
      $checkbox .= "        <input type=\"checkbox\" name=\"hourlyAvg\"$dummy> Hourly Average \n";

      if ($dailyAvg eq 'on') {
        $dummy = " checked";
        $chartOrTableChecked = 1;
        $images .= "<br><center><img src=$HTTPSURL/cgi-bin/generateChart.pl?chart=DailyAverage&amp;".encode_html_entities('U', $urlAccessParameters)."></center>\n" if ($uKey1 ne 'none');
      } else {
        $dummy = '';
      }
			
      $checkbox .= "        <input type=\"checkbox\" name=\"dailyAvg\"$dummy> Daily Average (long term stats)";

      $dummy = ($pf eq 'on') ? ' checked' : '';
      $printerFriendlyOutputBox = "<input type=\"checkbox\" name=\"pf\"$dummy> Printer friendly output\n";

      my $comboboxSelectKeysAndValuesPairs = 'html=>HTML';
      $comboboxSelectKeysAndValuesPairs .= '|pdf=>PDF' if ( $HTMLTOPDFPRG ne '<nihil>' and $HTMLTOPDFHOW ne '<nihil>' );
      $formatOutputSelect = create_combobox_from_keys_and_values_pairs ($comboboxSelectKeysAndValuesPairs, 'V', 0, $formatOutput, 'formatOutput', '', '', '', '', $debug);

      my ($numberOfDays, $sqlStartDate, $sqlEndDate, $yearFrom, $monthFrom, $dayFrom, $yearTo, $monthTo, $dayTo);
      ($goodDate, $sqlStartDate, $sqlEndDate, $numberOfDays) = get_sql_startDate_sqlEndDate_numberOfDays_test ($STRICTDATE, $FIRSTSTARTDATE, $inputType, $selYear, $selQuarter, $selMonth, $selWeek, $startDate, $endDate, $currentYear, $currentMonth, $currentDay, $debug);
      $errorMessage .= "<br><font color=\"Red\">Wrong Startdate and/or Enddate</font><br>" unless ( $goodDate );

      if ( $selDetailed eq 'on' ) {
        if ($details eq 'on') {
          $dummy = " checked";
          $chartOrTableChecked = 1;
        } else {
          $dummy = '';
        }

        $tables .= "        <input type=\"checkbox\" name=\"details\"$dummy> Show Details\n";

        if ($comments eq 'on') {
          $dummy = " checked";
          $chartOrTableChecked = 1;
        } else {
          $dummy = '';
        }

        $tables .= "        <input type=\"checkbox\" name=\"comments\"$dummy> Show Comments\n";

        if ( $PERFPARSEENABLED ) {
          if ($perfdata eq 'on') {
            $dummy = " checked";
            $chartOrTableChecked = 1;
          } else {
            $dummy = '';
          }

          $tables .= "        <input type=\"checkbox\" name=\"perfdata\"$dummy> Show Performance Data\n";
        }

        if ($topx eq 'on') {
          $dummy = " checked";
          $chartOrTableChecked = 1;
        } else {
          $dummy = '';
        }

        $tables .= "        <input type=\"checkbox\" name=\"topx\"$dummy> Show Top 20 Slow tests<br>";

        # Sql init & Query's  - - - - - - - - - - - - - - - - - - - - - -
        if ((($details eq 'on') or ($comments eq 'on') or ($perfdata eq 'on') or ($topx eq 'on')) and ! defined $errorMessage) {
          $sqlSelect  = "select SQL_NO_CACHE startDate as startDateQ, startTime, endDate as endDateQ, endTime, duration, status, statusMessage";
          $sqlAverage = "select SQL_NO_CACHE avg(time_to_sec(duration)) as average";
          $sqlErrors  = "select SQL_NO_CACHE statusmessage, count(statusmessage) as aantal";
          $sqlWhere   = "WHERE catalogID='$CcatalogID' and uKey = '$uKey1'";
          $sqlPeriode = "AND startDate BETWEEN '$sqlStartDate' AND '$sqlEndDate' $sqlPeriode " if (defined $sqlStartDate and defined $sqlEndDate);
        }

        my ($numbersOfTests, $step, $average);
        my $forceIndex = "force index (key_startDate)"; $forceIndex = '';

        # Short Description - - - - - - - - - - - - - - - - - - - - - - - -
        if ( $uKey1 ne 'none' ) {
          $sqlQuery = "select SQL_NO_CACHE shortDescription from $SERVERTABLPLUGINS WHERE catalogID = '$CcatalogID' and uKey = '$uKey1'";
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            ($shortDescription) = $sth->fetchrow_array() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);

            if ( $rv and defined $shortDescription and $shortDescription ) {
              $shortDescriptionTextArea = "<H1>Short Description</H1>\n";
              $shortDescriptionTextArea .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td>$shortDescription</td></tr></table>\n";
            }
          }
        }

        if ($details eq 'on' and ! defined $errorMessage) {
          # Details: General information  - - - - - - - - - - - - - - - - -
          $sqlInfo  = "select SQL_NO_CACHE count(id) as numbersOfTests, max(step) as step";
          $sqlQuery = create_sql_query_events_from_range_year_month ($inputType, $sqlStartDate, $sqlEndDate, $sqlInfo, $forceIndex, $sqlWhere, $sqlPeriode, '', "group by uKey", '', "", "ALL");

          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$numbersOfTestsQ, \$stepQ ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            while( $sth->fetch() ) {
              $numbersOfTests += $numbersOfTestsQ if (defined $numbersOfTestsQ);
			        $step = $stepQ if (defined $stepQ);
            }

            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }

          # Average: General information  - - - - - - - - - - - - - - - - -
          $sqlQuery = create_sql_query_events_from_range_year_month ($inputType, $sqlStartDate, $sqlEndDate, $sqlAverage, $forceIndex, $sqlWhere, $sqlPeriode, "AND status = 'OK'", '', "", '', "ALL");
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$averageQ ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            my $numberOffAverage = 0;

            while( $sth->fetch() ) { 
              if (defined $averageQ) {
                $numberOffAverage++;
                $average += $averageQ;
              }
            }

            $average /= $numberOffAverage if ($numberOffAverage != 0);
            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }

          # General information table - - - - - - - - - - - - - - - - - - -
          $infoTable = "<H1>General information</H1>\n";
          $infoTable .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th width=\"200\">Entry</th><th>Value</th></tr>\n";
          $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Application</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .substr($htmlTitle, 11). " </td></tr>\n";
          $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Report Type</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .$inputType. ( defined $slaWindow ? ", " .$slaWindow : '') ." </td></tr>\n";
          $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Generated on</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .$now. "</td></tr>\n";
          $infoTable .= "  <tr><td colspan=\"2\"><br></td></tr>\n";
          $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Average (ok only)</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .substr($average,0,5). " seconds </td></tr>\n" if (defined $average);

          if (($step >= 1) and ($numberOfDays >= 1)) {
            $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Test interval</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .($step/60). " minutes</td></tr>\n";
            $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Should run 'X' tests:</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .((86400/$step)* $numberOfDays). " </td></tr>\n";
            $infoTable .= "  <tr><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">Number of tests run </td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\"> " .$numbersOfTests. " (".substr(($numbersOfTests/((86400/$step)* $numberOfDays))*100,0,6)."%)</td></tr>\n";
          }

          $infoTable .= "</table>\n";
        }

        if ($comments eq 'on' and ! defined $errorMessage) {
          # Comment Detail  - - - - - - - - - - - - - - - - - - - - - - -
          my ($activationDate, $suspentionDate, $solvedDate, $activationTime, $suspentionTime, $solvedTime, $commentData, $instability, $persistent, $downtime, $problemSolved);
          $commentDetailList = "<H1>Comment Details</H1>\n";

          $sqlQuery = "select SQL_NO_CACHE activationDate, suspentionDate, solvedDate, activationTime, suspentionTime, solvedTime, commentData, instability, persistent, downtime, problemSolved from $SERVERTABLCOMMENTS where catalogID = '" .$CcatalogID. "' and uKey = '". $uKey1 ."' and activationDate <= '". $sqlEndDate ."' and ( ( problemSolved = '1' and '". $sqlStartDate ."' <= solvedDate ) or problemSolved = '0' )";
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$activationDate, \$suspentionDate, \$solvedDate, \$activationTime, \$suspentionTime, \$solvedTime, \$commentData, \$instability, \$persistent, \$downtime, \$problemSolved ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            if ($sth->rows) {
  	          $commentDetailList .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th></th><th>Activation Date/Time</th><th>Suspention Date/Time</th><th>Solved Date/Time</th><th>Instability</th><th>Persistent</th><th>Downtime</th><th>Problem Solved</th></tr>\n";

              while( $sth->fetch() ) {
                $commentData =~ s/'/`/g;
                $commentData =~ s/[\n\r]+(Updated|Edited|Closed) by: (?:.+), (?:.+) \((?:.+)\) on (\d{4}-\d\d-\d\d) (\d\d:\d\d:\d\d)/\n\r$1 on $2 $3/g;
                $commentData =~ s/[\n\r]/<br>/g;
                $commentData =~ s/(?:<br>)+/<br>/g;
                $commentData = encode_html_entities('C', $commentData);
	              $commentDetailList .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td rowspan=\"2\" valign=\"top\">&nbsp;</td><td>$activationDate \@ $activationTime</td><td>$suspentionDate \@ $suspentionTime</td><td>$solvedDate \@ $solvedTime</td><td>$instability</td><td>$persistent</td><td>$downtime</td><td>$problemSolved</td></tr><tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td colspan=\"7\">$commentData</td></tr>\n";
              }

              $commentDetailList .= "</table>\n";
            } else {
              $commentDetailList .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td width=\"400\">No comments for this period!</td></tr></table>";
            }

            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }
        }

        if ($perfdata eq 'on' and ! defined $errorMessage) {
          # Performance Data Detail - - - - - - - - - - - - - - - - - - -
          $perfdataDetailList = "<H1>Performance Data Details</H1>\n";

          unless ( $PERFPARSEENABLED ) {
            $perfdataDetailList .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td width=\"400\">Performance Data not enabled!</td></tr></table>";
          } else {
            my ($sthPERFPARSE, $metric_id, $metric, $times, $percentiles, $unit, $Unit, $periodePERFPARSE, $countPERFPARSE, $valuePERFPARSE) = ( $dbh );

            my $toggle = 0;
            my $sqlWherePERFDATA;

            if ( $PERFPARSEVERSION eq '20' ) {
              my $catalogID_uKey = ( ( $CcatalogID eq 'CID' ) ? '' : $CcatalogID .'_' ) . $uKey1;
              $sqlQuery = "select service_id from $PERFPARSEDATABASE.perfdata_service where service_description = '$catalogID_uKey'";
              $sqlWherePERFDATA = "where $DATABASE.$SERVERTABLREPORTSPRFDT.metric_id = $PERFPARSEDATABASE.perfdata_service_metric.metric_id and $PERFPARSEDATABASE.perfdata_service_metric.service_id in ($sqlQuery)";
            } else {
              $sqlWherePERFDATA = "where $DATABASE.$SERVERTABLREPORTSPRFDT.catalogID='$CcatalogID' and $DATABASE.$SERVERTABLREPORTSPRFDT.uKey='$uKey1' and $DATABASE.$SERVERTABLREPORTSPRFDT.activated='1' and $DATABASE.$SERVERTABLREPORTSPRFDT.metric_id = $PERFPARSEDATABASE.perfdata_service_metric.metric_id";
            }

            $sqlQuery = "select $DATABASE.$SERVERTABLREPORTSPRFDT.metric_id, $PERFPARSEDATABASE.perfdata_service_metric.metric, $DATABASE.$SERVERTABLREPORTSPRFDT.times, $DATABASE.$SERVERTABLREPORTSPRFDT.percentiles, $DATABASE.$SERVERTABLREPORTSPRFDT.unit, $PERFPARSEDATABASE.perfdata_service_metric.unit from $DATABASE.$SERVERTABLREPORTSPRFDT, $PERFPARSEDATABASE.perfdata_service_metric $sqlWherePERFDATA";

            $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
            $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
            $sth->bind_columns( \$metric_id, \$metric, \$times, \$percentiles, \$unit, \$Unit ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

            if ( $rv ) {
              if ($sth->rows) {
                my $sqlPeriodePERFDATA = $sqlPeriode;

                if ( $PERFPARSEVERSION eq '20' ) {
                  $sqlPeriodePERFDATA  =~ s/^AND startDate BETWEEN '(\d+-\d+-\d+)' AND '(\d+-\d+-\d+)'/AND FROM_UNIXTIME\(ctime\) BETWEEN '$1 00:00:00' AND '$2 23:59:59'/g;
                  $sqlPeriodePERFDATA  =~ s/(startDate|startTime) BETWEEN/TIME\(FROM_UNIXTIME\(ctime\)\) BETWEEN/g;
                  $sqlPeriodePERFDATA  =~ s/(startDate|startTime)/FROM_UNIXTIME\(ctime\)/g;
                } else {
                  $sqlPeriodePERFDATA  =~ s/^AND startDate BETWEEN '(\d+-\d+-\d+)' AND '(\d+-\d+-\d+)'/AND ctime BETWEEN '$1 00:00:00' AND '$2 23:59:59'/g;
                  $sqlPeriodePERFDATA  =~ s/(startDate|startTime) BETWEEN/TIME\(ctime\) BETWEEN/g;
                  $sqlPeriodePERFDATA  =~ s/(startDate|startTime)/ctime/g;
                }

                my $groupPERFDATA       = ( $inputType eq 'fromto' ) ? 'dayofmonth' : $inputType; # 'dayofmonth' < 4.1.1 <= 'dayofmonth' or 'day' !!!
                my $percentagePERFDATA  = ( $inputType eq 'fromto' and $startDate ne $endDate ) ? 0 : 1;

  	            $perfdataDetailList .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\">\n";

                while( $sth->fetch() ) {
    	            $perfdataDetailList .= "<tr><th>&nbsp;$groupPERFDATA&nbsp;</th><th align=\"left\">&nbsp;$metric&nbsp;</th><th>&nbsp;Expression&nbsp;</th></tr>\n";
                  $times = ( defined $times and $times ne '' ) ? '0,'. $times : '0'; 

                  my $sqlValuePERFDATA = '';
                  my $countRows = 0;

                  if ( $unit =~ /(?:s|ms)/ and $Unit =~ /(?:s|ms)/ ) {
                    foreach my $time (split (/,/, $times)) {
                      $toggle = ( $toggle ) ? 0 : 1;

                      my $value = $time;

                      if ( $value ) {
                        if ( $unit ne $Unit ) {
                          if ( $Unit eq 'ms' ) {
                            $value *= 1000;
                          }  elsif ( $Unit eq 's' ) {
                            $value /= 1000;
                          }
                        }

                        $sqlValuePERFDATA = 'and value <= '. $value;
                      }

                      my $sqlWherePERFDATA;

                      if ( $PERFPARSEVERSION eq '20' ) {
                        $sqlWherePERFDATA = "WHERE metric_id = '$metric_id'";
                      } else {
                        my $catalogID_uKey1 = ( ( $CcatalogID eq 'CID' ) ? '' : $CcatalogID .'_' ) . $uKey1;
                        $sqlWherePERFDATA = "WHERE host_name = '$Title' and service_description = '$catalogID_uKey1' and metric = '$metric'";
                      }

                      my $sqlPERFDATA = "SELECT ";
                      $sqlPERFDATA .= ( $PERFPARSEVERSION eq '20' ) ? "$groupPERFDATA(FROM_UNIXTIME(ctime))" :" $groupPERFDATA(ctime)";
                      $sqlPERFDATA .= ", count(ctime) FROM $PERFPARSEDATABASE.perfdata_service_bin $sqlWherePERFDATA $sqlPeriodePERFDATA $sqlValuePERFDATA group by ";
                      $sqlPERFDATA .= ( $PERFPARSEVERSION eq '20' ) ? "$groupPERFDATA(FROM_UNIXTIME(ctime))" : "$groupPERFDATA(ctime)";

                      $sthPERFPARSE = $dbh->prepare( $sqlPERFDATA ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlPERFDATA", $debug, '', "", '', "", -1, '', $sessionID);
                      $sthPERFPARSE->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlPERFDATA", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
                      $sthPERFPARSE->bind_columns( \$periodePERFPARSE, \$countPERFPARSE ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlPERFDATA", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

                      my $expresionPERFPARSE = ( $debug eq 'T' ? "($value&nbsp;$Unit)&nbsp;" : '' );

                      my $bgcolor = ( $toggle ) ? $COLORSTABLE{ENDBLOCK} : $COLORSTABLE{STARTBLOCK};
                      $perfdataDetailList .= "<tr bgcolor=\"$bgcolor\"><td colspan=\"2\">&nbsp;$sqlPERFDATA&nbsp;</td><td>&nbsp;<=&nbsp;$time&nbsp;$unit&nbsp;$expresionPERFPARSE</td></tr>\n" if ( $debug eq 'T' );

                      if ( $rv ) {
                        if ($sthPERFPARSE->rows) {
                          while( $sthPERFPARSE->fetch() ) {
                            unless ( $value ) {
                              $countRows = $countPERFPARSE;
                            } else {
                              if ( $percentagePERFDATA ) {
                                my $percentage = sprintf "%.2f", ( ( $countPERFPARSE / $countRows ) * 100 );
                                $percentage = "( $countPERFPARSE / $countRows ) * 100 = $percentage" if ( $debug eq 'T' );
                                $perfdataDetailList .= "<tr bgcolor=\"$bgcolor\"><td align=\"right\">&nbsp;$periodePERFPARSE&nbsp;</td><td align=\"right\">&nbsp;$percentage %&nbsp;</td><td>&nbsp;<=&nbsp;$time&nbsp;$unit&nbsp;$expresionPERFPARSE</td></tr>\n";
                              } else {
                                $perfdataDetailList .= "<tr bgcolor=\"$bgcolor\"><td align=\"right\">&nbsp;$periodePERFPARSE&nbsp;</td><td align=\"right\">&nbsp;$countPERFPARSE #&nbsp;</td><td>&nbsp;<=&nbsp;$time&nbsp;$unit&nbsp;$expresionPERFPARSE</td></tr>\n";
                              }
                            }
                          }
                        } elsif ( $debug eq 'T' ) {
                          $perfdataDetailList .= "<tr bgcolor=\"$bgcolor\"><td align=\"right\">&nbsp;</td><td align=\"right\">&nbsp;0 ". ( $percentagePERFDATA ? '%' : '#' ) ."&nbsp;</td><td>&nbsp;<=&nbsp;$time&nbsp;$unit&nbsp;$expresionPERFPARSE</td></tr>\n";
                        }

                        $sthPERFPARSE->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
                      }
                    }

                    if ( $percentagePERFDATA ) {
                      foreach my $percentile (split (/,/, $percentiles)) {
                        $toggle = ( $toggle ) ? 0 : 1;

                        my ($IR, $FR) = split (/\./, sprintf "%.2f", ( ( $percentile / 100 ) * ( $countRows + 1 ) ) );
                        my $limit = ( $FR eq '00' ) ? 1 : 2;
                        my $offset = $IR - 1;
                        $FR = sprintf "0.%d", $FR;

                        my $sqlWherePERFDATA;

                        if ( $PERFPARSEVERSION eq '20' ) {
                          $sqlWherePERFDATA = "WHERE metric_id = '$metric_id'";
                        } else {
                          my $catalogID_uKey1 = ( ( $CcatalogID eq 'CID' ) ? '' : $CcatalogID .'_' ) . $uKey1;
                          $sqlWherePERFDATA = "WHERE host_name = '$Title' and service_description = '$catalogID_uKey1' and metric = '$metric'";
                        }

                        my $sqlPERFDATA = "SELECT ";
                        $sqlPERFDATA .= ( $PERFPARSEVERSION eq '20' ) ? "$groupPERFDATA(FROM_UNIXTIME(ctime))" : "$groupPERFDATA(ctime)";
                        $sqlPERFDATA .= ", value FROM $PERFPARSEDATABASE.perfdata_service_bin $sqlWherePERFDATA $sqlPeriodePERFDATA order by value limit $offset, $limit";

                        $sthPERFPARSE = $dbh->prepare( $sqlPERFDATA ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlPERFDATA", $debug, '', "", '', "", -1, '', $sessionID);
                        $sthPERFPARSE->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlPERFDATA", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
                        $sthPERFPARSE->bind_columns( \$periodePERFPARSE, \$valuePERFPARSE ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlPERFDATA", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

                        my $bgcolor = ( $toggle ) ? $COLORSTABLE{ENDBLOCK} : $COLORSTABLE{STARTBLOCK};
                        $perfdataDetailList .= "<tr bgcolor=\"$bgcolor\"><td colspan=\"2\">&nbsp;( ( $percentile / 100 ) * ( $countRows + 1 ) ), IR: $IR, FR: $FR, offset: $offset, limit: $limit & # $countRows&nbsp;<br>&nbsp;$sqlPERFDATA&nbsp;</td><td>&nbsp;$percentile&nbsp;ste&nbsp;percentile&nbsp;</td></tr>\n" if ( $debug eq 'T' );

                        if ( $rv ) {
                          if ($sthPERFPARSE->rows) {
                            my ($value1, $value2);

                            while( $sthPERFPARSE->fetch() ) {
                              $value1 = $valuePERFPARSE unless (defined $value1);
                              $value2 = $valuePERFPARSE if (defined $value1);
                            }

                            $value2 = $value1 unless (defined $value2);

                            if ( $unit ne $Unit ) {
                              if ( $Unit eq 'ms' ) {
                                $value1 /= 1000;
                                $value2 /= 1000;
                              }  elsif ( $Unit eq 's' ) {
                                $value1 *= 1000;
                                $value2 *= 1000;
                              }
                            }

                            my $percentilePERFPARSE = sprintf "%.2f $unit", ( "$FR" * ( $value2 - $value1 ) + $value1 );
                            $percentilePERFPARSE = "( $FR * ( $value2 - $value1 ) + $value1 ) = $percentilePERFPARSE" if ( $debug eq 'T' );
                            $perfdataDetailList .= "<tr bgcolor=\"$bgcolor\"><td align=\"right\">&nbsp;$periodePERFPARSE&nbsp;</td><td align=\"right\">&nbsp;$percentilePERFPARSE&nbsp;</td><td>&nbsp;$percentile&nbsp;ste&nbsp;percentile&nbsp;</td></tr>\n";
                          } elsif ( $debug eq 'T' ) {
                            $perfdataDetailList .= "<tr bgcolor=\"$bgcolor\"><td align=\"right\">&nbsp;</td><td align=\"right\">&nbsp;missing data&nbsp;</td><td>&nbsp;$percentile&nbsp;ste&nbsp;percentile&nbsp;</td></tr>\n";
                          }

                          $sthPERFPARSE->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
                        }
                      }
                    } else {
                      $perfdataDetailList .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td colspan=\"3\">&nbsp;ASNMTAP/Performance Data: percentile not supported when $startDate ne $endDate&nbsp;</td></tr>\n";
                    }
                  } else {
                    $perfdataDetailList .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td colspan=\"2\">&nbsp;ASNMTAP/Performance Data: unit not supported&nbsp;%&nbsp;</td><td>&nbsp;$unit/$Unit&nbsp;</td></tr>\n";
                  }
                }

                $perfdataDetailList .= "</table>\n";
              } else {
                $perfdataDetailList .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td width=\"400\">No Performance Data defined!</td></tr></table>";
              }

              $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
            }
          }
        }

        if ($details eq 'on' and ! defined $errorMessage) {
          # Problem Detail  - - - - - - - - - - - - - - - - - - - - - - - -
          my ($oneblock, $block, $firstrun, $nstartDateQ, $nstartTime, $nendDateQ, $nendTime, $nseconden);
          my ($test, $resultsdir, $tel, $wtel, $nstatus, $nrest, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $rrest);

          $errorDetailList = "<H1>Problem Details</H1>\n";
          $responseTable = "<H1>Response time warnings</H1>\n";

          $sqlQuery = "select SQL_NO_CACHE test, resultsdir from $SERVERTABLPLUGINS $sqlWhere";
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            ($test, $resultsdir) = $sth->fetchrow_array() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);

            if ( $rv ) {
              ($test, undef) = split(/\.pl/, $test);
	  
              $sqlQuery = create_sql_query_events_from_range_year_month ($inputType, $sqlStartDate, $sqlEndDate, $sqlSelect, $forceIndex, $sqlWhere, $sqlPeriode, "AND status <> 'OK' AND status <> 'OFFLINE' AND status <> 'NO TEST'", '', "", "order by startDateQ, startTime", "ALL");
              $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
              $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
              $sth->bind_columns( \$startDateQ, \$startTime, \$endDateQ, \$endTime, \$duration, \$status, \$statusMessage ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
            }
          }

          if ( $rv ) {
            sub createLinkToDebugFile {
              my ($startDate, $startTime, $status, $statusMessage) = @_;

              my ($year, $month, $day) = split (/-/, $startDate);
              my ($hour, $min, $sec) = split (/:/, $startTime);

              if ( $formatOutput ne 'html' or $htmlToPdf ) {
                return ($statusMessage);
              } else {
                my $catalogID_uKey1 = ( ( $CcatalogID eq 'CID' ) ? '' : $CcatalogID .'_' ) . $uKey1;

                if (-e "$PREFIXPATH/$RESULTSDIR/$resultsdir/$DEBUGDIR/$year$month$day$hour$min$sec-$test-$catalogID_uKey1-$status.htm") {
                  return ("<A HREF=\"$RESULTSURL/$resultsdir/$DEBUGDIR/$year$month$day$hour$min$sec-$test-$catalogID_uKey1-$status.htm\" target=\"_blank\">$statusMessage</A>");
                } else {
                  return ($statusMessage);
                }
              }
            }

            $firstrun = 1; $oneblock = $tel = $wtel = 0;

            while( $sth->fetch() ) {
              $seconden = int(substr($duration, 6, 2)) + int(substr($duration, 3, 2)*60) + int(substr($duration, 0, 2)*3600);
              (undef, $rest) = split(/:/, $statusMessage, 2);

            # ($rest, undef) = split(/\|/, $rest, 2) if (defined $rest); # remove performance data
              if (defined $rest) {
                my $_rest = reverse $rest;
                my ($_rest, undef) = reverse split(/\|/, $_rest, 2);
                my $rest = reverse $_rest;
              } 

              if ($firstrun) {
                $firstrun = 0;
              } else {
                ($oneblock, $block, $rrest, $dummy) = setBlockBGcolor ($oneblock, $status, $step, $startDateQ, $startTime, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstatus, $nrest);

                if ($rrest =~ /^Response/) {
                  $wtel++;
                  $responseTable .= "<table width=\"100%\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th width=\"40\"> # </th><th>Start</th><th>Stop</th><th>Duration</th><th>Status</th><th>Status Message</th></tr>\n" if ($wtel == 1);
                  $responseTable .= "<tr $block><td>$dummy$wtel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS {$nstatus}."\"> ".encode_html_entities('S', $nstatus)." </font></td><td> ".encode_html_entities('M', $rrest)." </td></tr>\n";
                } else {
                  $tel++;
                  $errorDetailList .= "<table width=\"100%\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th width=\"40\"> # </th><th>Start</th><th>Stop</th><th>Duration</th><th>Status</th><th>Status Message</th></tr>\n" if ($tel == 1);
                  $errorDetailList .= "<tr $block><td>$dummy$tel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS{$nstatus}."\"> ".encode_html_entities('S', $nstatus)." </font></td><td>".createLinkToDebugFile($nstartDateQ, $nstartTime, $nstatus, encode_html_entities('M', $rrest))." </td></tr>\n";
                }
              }

              ($nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstartDateQ, $nstartTime, $nendDateQ, $nendTime, $nseconden, $nstatus, $nrest) = setPreviousValues ($startDateQ, $startTime, $endDateQ, $endTime, $seconden, $status, $rest);
            }

            if ($tel || $wtel) {
              ($oneblock, $block, $rrest, $dummy) = setBlockBGcolor ($oneblock, $status, 0, $startDateQ, $startTime, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstatus, $nrest);
  
              if ($rrest =~ /^Response/) {
                $wtel++;
                $responseTable .= "<tr $block><td>$dummy$wtel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS {$nstatus}."\"> ".encode_html_entities('S', $nstatus)." </font></td><td> ".encode_html_entities('M', $rrest)." </td></tr>\n";
              } else {
                $tel++;
                $errorDetailList .= "<tr $block><td>$dummy$tel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS {$nstatus}."\"> ".encode_html_entities('S', $nstatus)." </font></td><td>".createLinkToDebugFile($nstartDateQ, $nstartTime, $nstatus, encode_html_entities('M', $rrest))." </td></tr>\n";
              }
            }

            $responseTable .= "</table>\n<br>\n<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td>Legende:</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">&nbsp;&nbsp;&nbsp;Single item&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">&nbsp;&nbsp;&nbsp;Start of block&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">&nbsp;&nbsp;&nbsp;Next element of the same block&nbsp;&nbsp;&nbsp;</td></tr></table>\n" if ($wtel);

            if ($tel) {
              $errorDetailList .= "</table>\n<br>\n<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td>Legende:</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">&nbsp;&nbsp;&nbsp;Single item&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">&nbsp;&nbsp;&nbsp;Start of block&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">&nbsp;&nbsp;&nbsp;Next element of the same block&nbsp;&nbsp;&nbsp;</td></tr></table>\n";
            } else {
              $errorDetailList .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td width=\"400\">No problems for this period!</td></tr></table>\n";
            }

            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }

          $sqlQuery = create_sql_query_events_from_range_year_month ($inputType, $sqlStartDate, $sqlEndDate, $sqlSelect, $forceIndex, $sqlWhere, $sqlPeriode, "AND status = 'OK' AND statusMessage regexp ': Response time [[:alnum:]]+.[[:alnum:]]+ > trendline [[:alnum:]]+'", '', "", "order by startDateQ, startTime", "ALL");
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$startDateQ, \$startTime, \$endDateQ, \$endTime, \$duration, \$status, \$statusMessage ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            $oneblock = $wtel = 0; 

            while( $sth->fetch() ) {
              $seconden = int(substr($duration, 6, 2)) + int(substr($duration, 3, 2)*60) + int(substr($duration, 0, 2)*3600);
              (undef, $rest) = split(/:/, $statusMessage, 2);

            # ($rest, undef) = split(/\|/, $rest, 2) if (defined $rest); # remove performance data
              if (defined $rest) {
                my $_rest = reverse $rest;
                my ($_rest, undef) = reverse split(/\|/, $_rest, 2);
                my $rest = reverse $_rest;
              } 
							
              if ($wtel) {
                ($oneblock, $block, $rrest, $dummy) = setBlockBGcolor ($oneblock, $status, $step, $startDateQ, $startTime, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstatus, $nrest);
                $responseTable .= "<tr $block><td>$dummy$wtel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS {$nstatus}."\"> " .encode_html_entities('S', $nstatus). " </font></td><td> " .encode_html_entities('M', $rrest). " </td></tr>\n";
              } else {
                $responseTable .= "<table width=\"100%\" border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th width=\"40\"> # </th><th>Start</th><th>Stop</th><th>Duration</th><th>Status</th><th>Status Message</th></tr>\n";
              }

              $wtel++;
              ($nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstartDateQ, $nstartTime, $nendDateQ, $nendTime, $nseconden, $nstatus, $nrest) = setPreviousValues ($startDateQ, $startTime, $endDateQ, $endTime, $seconden, $status, $rest);
            }

            if ($wtel) {
              ($oneblock, $block, $rrest, $dummy) = setBlockBGcolor ($oneblock, $status, 0, $startDateQ, $startTime, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstatus, $nrest);
              $responseTable .= "<tr $block><td>$dummy$wtel</td><td> $nstartDateQ \@ $nstartTime</td><td>$nendDateQ \@ $nendTime</td><td align=\"center\">".$nseconden."s</td><td><font color=\"".$COLORS {$nstatus}."\"> " .encode_html_entities('S', $nstatus). " </font></td><td> " .encode_html_entities('M', $rrest). " </td></tr>\n";
              $responseTable .= "</table>\n<br>\n<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td>Legende:</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">&nbsp;&nbsp;&nbsp;Single item&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{STARTBLOCK}\">&nbsp;&nbsp;&nbsp;Start of block&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;&nbsp;</td><td bgcolor=\"$COLORSTABLE{ENDBLOCK}\">&nbsp;&nbsp;&nbsp;Next element of the same block&nbsp;&nbsp;&nbsp;</td></tr></table>\n";
            } else {
              $responseTable .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td width=\"400\">No response time warnings for this period!</td></tr></table>\n";
            }

            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }

          # Problem Summary - - - - - - - - - - - - - - - - - - - - - - -
          $sqlQuery = create_sql_query_events_from_range_year_month ($inputType, $sqlStartDate, $sqlEndDate, $sqlErrors, $forceIndex, $sqlWhere, $sqlPeriode, "AND status ='CRITICAL'", "GROUP BY statusmessage", '', "order by aantal desc, statusmessage", "ALL");
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$statusMessage, \$count ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            my (%problemSummary);

            if ($sth->rows) {
              while( $sth->fetch() ) {
                my ($dummy, $rest) = split(/:/, $statusMessage, 2);
                $rest = $dummy unless ( $rest );

                if ($rest) {
                # ($rest, undef) = split(/\|/, $rest, 2); # remove performance data
                   my $_rest = reverse $rest;
                   my ($_rest, undef) = reverse split(/\|/, $_rest, 2);
                   my $rest = reverse $_rest;

                  ($dummy, $rest) = split(/,/, $rest, 2);
                  $rest = $dummy unless ( $rest );
                } else {
                  $rest = 'UNDEFINED';
                }

                if (exists $problemSummary{$rest}) {
                  $problemSummary{$rest} += $count;
                } else {
                  $problemSummary{$rest}  = $count;
                }
              }
            }

            $errorList = "<H1>Problem Summary </H1>\n";

  	        if ( $sth->rows > 0 ) {
  	          $errorList .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th>Statusmessage</th><th>Freq</th></tr>\n";

    	      foreach my $rest (sort {$problemSummary{$b} <=> $problemSummary{$a}} (keys(%problemSummary))) {
	            $errorList .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td> " .encode_html_entities('M', $rest). " </td><td align=\"right\">" .$problemSummary{$rest}. "</td></tr>\n";
	          }

              $errorList .= "</table>\n";
            } else {
              $errorList .= "<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><td width=\"400\">No errors for this period!</td></tr></table>";
            }

            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }
        }

        if ($topx eq 'on' and ! defined $errorMessage) {
          # Top X List  - - - - - - - - - - - - - - - - - - - - - - - - -
          my ($startDatetx, $durationtx, $startTimetx);
          $sqlQuery = create_sql_query_events_from_range_year_month ($inputType, $sqlStartDate, $sqlEndDate, "select SQL_NO_CACHE startDate, startTime, duration", $forceIndex, $sqlWhere, $sqlPeriode, "and status <> 'OFFLINE' and status <> 'CRITICAL' and duration > 0", '', "", "order by duration desc, startDate desc, startTime desc limit 20", "ALL");
          $sth = $dbh->prepare( $sqlQuery ) or $rv = error_trap_DBI("", "Cannot dbh->prepare: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID);
          $sth->execute() or $rv = error_trap_DBI("", "Cannot sth->execute: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;
          $sth->bind_columns( \$startDatetx, \$startTimetx,\$durationtx ) or $rv = error_trap_DBI("", "Cannot sth->bind_columns: $sqlQuery", $debug, '', "", '', "", -1, '', $sessionID) if $rv;

          if ( $rv ) {
            $topxTable .= "<H1>Top 20 Slow Tests </H1>\n";
            $topxTable .= "\n<table border=\"0\" cellpadding=\"1\" cellspacing=\"1\" bgcolor=\"$COLORSTABLE{TABLE}\"><tr><th width=\"40\"> # </th><th>Time</th><th>Duration</th></tr>\n";

            my $teltopx = 1;
	
            while( $sth->fetch() ) {
              $seconden = int(substr($durationtx, 6, 2)) + int(substr($durationtx, 3, 2)*60) + int(substr($durationtx, 0, 2)*3600);
              $topxTable .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td width=\"30\">$teltopx</td><td width=\"200\" align=\"center\">$startDatetx \@ $startTimetx</td><td width=\"80\" align=\"right\"><b>$seconden sec</b></td></tr>\n";
              $teltopx++;
            }			

            $topxTable .= "<tr><td width=\"400\">No top 20 slow tests for this period!</td></tr>\n" if ($teltopx == 1);
            $topxTable .= "</table>";
            $sth->finish() or $rv = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", -1, '', $sessionID);
          }
        }
      }

      $errorMessage .= "<br>There are no charts or tables checked<br>\n" unless ( $chartOrTableChecked );
    }

    # Close database connection - - - - - - - - - - - - - - - - - - - - -
    $dbh->disconnect or $rv = error_trap_DBI("Sorry, the database was unable to disconnect", $debug, '', "", '', "", '', -1, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if ($htmlToPdf) {
      my ($type, $range);
		
      if ($inputType eq "fromto") {
        if ($endDate ne '')	{
          $type  = '';
          $range = "Between $startDate and $endDate";
        } else {
          $type  = ' Daily';
          $range = "Date $startDate";
        }
      } elsif ($inputType eq "year") {
        $type  = ' Yearly';
        $range = "Year $selYear";
      } elsif ($inputType eq "quarter") {
        $type  = ' Quarterly';
        $range = "Year $selYear, Quarter $selQuarter";
      } elsif ($inputType eq "month") {
        $type  = ' Monthly';
        $range = "Year $selYear, Month " .$arrMonths[$selMonth -1];
      } elsif ($inputType eq "week") {
        $type  = ' Weekly';
        $range = "Year $selYear, Week $selWeek";
      }

      print "    <H1>$DEPARTMENT \@ $BUSINESS: '$APPLICATION'$type report</H1>\n";
      print "    <H2>Catalog: $CcatalogID</H2>\n";
      print "    <H2>Periode: $range</H2>\n" if (defined $range);
      print "    <H2>SLA window: $slaWindow</H2>\n" if (defined $slaWindow);
    } else {
      print <<HTML;
  <script language="JavaScript1.2" type="text/javascript">
    function submitForm() {
      document.reports.catalogIDreload.value = 1;
      document.reports.submit();
      return true;
    }

    function validateForm() {
      if ( document.reports.formatOutput.value != null ) {
        if ( document.reports.formatOutput.value == 'html' ) { document.reports.target = '_self';  }
        if ( document.reports.formatOutput.value == 'pdf' )  { document.reports.target = '_blank'; }
        return true;
      } else {
        return false;
      }
    }
  </script>

  <form action="$ENV{SCRIPT_NAME}" method="post" name="reports" target="_self" onSubmit="return validateForm();">
    <input type="hidden" name="pagedir"         value="$pagedir">
    <input type="hidden" name="pageset"         value="$pageset">
    <input type="hidden" name="debug"           value="$debug">
    <input type="hidden" name="CGISESSID"       value="$sessionID">
    <input type="hidden" name="detailed"        value="$selDetailed">
    <input type="hidden" name="catalogIDreload" value="0">
    <table border="0">
      <tr><td><b>Catalog ID: </b></td><td>
        <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled> $catalogIDSelect
      </td></tr>
HTML

      if ( $selDetailed eq 'on' ) {
        print <<HTML;
      <tr align="left"><td>Application:</td><td>
        <select name="uKey1">
$uKeySelect1        </select>
HTML
      } else {
        print <<HTML;
      <tr align="left"><td>Application 1:</td><td>
        <select name="uKey1">
$uKeySelect1        </select>
      </td></tr><tr align="left"><td>Application 2:</td><td>
        <select name="uKey2">
$uKeySelect2        </select>
      </td></tr><tr align="left"><td>Application 3:</td><td>
        <select name="uKey3">
$uKeySelect3        </select>
HTML
      }

      my ($firstStartdateYear, $firstStartdateMonth, $firstStartdateDay) = split (/-/, $FIRSTSTARTDATE);
      my ($firstYear, $firstMonth, $firstDay) = Add_Delta_Days ($firstStartdateYear, $firstStartdateMonth, $firstStartdateDay, -1);

      my ($lastYear, $lastMonth, $lastDay) = Add_Delta_Days ($currentYear, $currentMonth, $currentDay, 1);

      print <<HTML;
      </td></tr><tr align="left"><td>$fromto</td>
      <td><SCRIPT LANGUAGE="JavaScript" type="text/javascript" ID="jsCal1Calendar">
            var cal1Calendar = new CalendarPopup("CalendarDIV");
            cal1Calendar.offsetX = 1;
            cal1Calendar.showNavigationDropdowns();
            cal1Calendar.addDisabledDates(null, "$firstYear-$firstMonth-$firstDay");
            cal1Calendar.addDisabledDates("$lastYear-$lastMonth-$lastDay", null);
          </SCRIPT>
          <DIV ID="CalendarDIV" STYLE="position:absolute;visibility:hidden;background-color:black;layer-background-color:black;"></DIV>
	      <input type="text" name="startDate" value="$startDate" size="10" maxlength="10">&nbsp;
		  <a href="#" onclick="cal1Calendar.select(document.forms[1].startDate, 'startDateCalendar','yyyy-MM-dd'); return false;" name="startDateCalendar" id="startDateCalendar"><img src="$IMAGESURL/cal.gif" alt="Calendar" border="0"> </a>&nbsp;&nbsp;
		  To: <input type="text" name="endDate" value="$endDate" size="10" maxlength="10">&nbsp;
		  <a href="#" onclick="cal1Calendar.select(document.forms[1].endDate, 'endDateCalendar','yyyy-MM-dd'); return false;" name="endDateCalendar" id="endDateCalendar"><img src="$IMAGESURL/cal.gif" alt="Calendar" border="0"> </a>
      </td></tr><tr align="left"><td valign="top">$years
      </td></tr><tr align="left"><td valign="top">$quarters
      </td></tr><tr align="left"><td valign="top">$months
      </td></tr><tr align="left"><td valign="top">$weeks
      </td></tr><tr align="left"><td valign="top">SLA Window:</td><td>$slaWindows
      </td></tr><tr align="left"><td valign="top">Charts:</td><td>$checkbox
HTML

      print "      </td></tr><tr align=\"left\"><td valign=\"top\">Tables:</td><td>$tables\n" if ( $selDetailed eq 'on' );

      print <<HTML;
      </td></tr><tr align="left"><td>Options:</td><td>$printerFriendlyOutputBox
      </td></tr><tr align="left"><td>Format Output:</td><td>$formatOutputSelect
      </td></tr><tr align="left"><td align="right"><br>
        <input type="submit" value="Launch"></td><td><br><input type="reset" value="Reset">
      </td></tr>
    </table>
  </form>
  <hr>
HTML
    }

    if (defined $errorMessage) {
      print $errorMessage, "\n" ;
    } else {
      print $shortDescriptionTextArea, "<br><br>\n" if (defined $shortDescriptionTextArea);
      print $images, "\n" if (defined $images );
      print $infoTable, "<br><br>\n" if (defined $infoTable);
      print $topxTable, "<br><br>\n" if (defined $topxTable);
      print $errorList, "<br><br>\n" if (defined $errorList);
      print $commentDetailList, "<br><br>\n" if (defined $commentDetailList);
      print $perfdataDetailList, "<br><br>\n" if (defined $perfdataDetailList);
      print $errorDetailList, "<br><br>\n" if (defined $errorDetailList);
      print $responseTable if (defined $responseTable);
      print "<br><center><a href=\"$HTTPSURL/cgi-bin/htmlToPdf.pl?HTMLtoPDFprg=$HTMLTOPDFPRG&amp;HTMLtoPDFhow=$HTMLTOPDFHOW&amp;scriptname=", $ENV{SCRIPT_NAME}, "&amp;",encode_html_entities('U', $urlAccessParameters),"\" target=\"_blank\">[Generate PDF file]</a></center>\n" if ((! defined $errorMessage) and ($HTMLTOPDFPRG ne '<nihil>' and $HTMLTOPDFHOW ne '<nihil>') and (! $htmlToPdf));
    }
  }

  print '<BR>', "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub setBlockBGcolor {
  my ($oneblock, $status, $step, $startDateQ, $startTime, $nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $nstatus, $nrest) = @_;

  my $block;

  if ($step == 0) {
    $block = ($oneblock) ? " bgcolor=\"$COLORSTABLE{ENDBLOCK}\" " : " bgcolor=\"$COLORSTABLE{NOBLOCK}\" ";
    $oneblock = 0;
  } else {
    my ($year, $month, $day) = split(/-/, $startDateQ);
    my ($hours, $minuts, $seconds) = split(/:/, $startTime);

    my ($ddays, $dhours, $dminuts, $dseconds) = Delta_DHMS ($nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $year, $month, $day, $hours, $minuts, $seconds);
    my $dtotsec = $dseconds + ($dminuts * 60) + ($dhours * 3600) + ($ddays * 86400);

    if (($dtotsec < ($step * 2.2)) and ($nstatus eq $status)) {
      $block = ($oneblock) ? " bgcolor=\"$COLORSTABLE{ENDBLOCK}\" " : " bgcolor=\"$COLORSTABLE{STARTBLOCK}\" ";
      $oneblock = 1;
    } else {
      $block = ($oneblock) ? " bgcolor=\"$COLORSTABLE{ENDBLOCK}\" " : " bgcolor=\"$COLORSTABLE{NOBLOCK}\" ";
      $oneblock = 0;
    }
  }

  my ($dummy, $rrest);

  if (defined $nrest) {
    ($dummy, $rrest) = split(/,/, $nrest, 2);
    $dummy = '' unless ( defined $dummy );
    $rrest = $dummy unless ( defined $rrest );
  } else {
    $rrest = '';
  }

  $rrest =~ s/^ +//g; 
  return ($oneblock, $block, $rrest, '');
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub setPreviousValues {
  my ($startDateQ, $startTime, $endDateQ, $endTime, $seconden, $status, $rest) = @_;

  my ($nyear, $nmonth, $nday) = split(/-/, $startDateQ);
  my ($nhours, $nminuts, $nseconds) = split(/:/, $startTime);
  return ($nyear, $nmonth, $nday, $nhours, $nminuts, $nseconds, $startDateQ, $startTime, $endDateQ, $endTime, $seconden, $status, $rest);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
