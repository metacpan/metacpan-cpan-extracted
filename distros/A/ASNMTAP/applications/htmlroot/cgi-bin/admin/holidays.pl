#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, holidays.pl for ASNMTAP::Asnmtap::Applications::CGI
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

$PROGNAME       = "holidays.pl";
my $prgtext     = "Holidays";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir          = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset          = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : 'admin';   $pageset =~ s/\+/ /g;
my $debug            = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : 'F';
my $pageNo           = (defined $cgi->param('pageNo'))          ? $cgi->param('pageNo')          : 1;
my $pageOffset       = (defined $cgi->param('pageOffset'))      ? $cgi->param('pageOffset')      : 0;
my $orderBy          = (defined $cgi->param('orderBy'))         ? $cgi->param('orderBy')         : 'holiday asc, countryName asc, formule asc, month asc, day asc, offset asc';
my $action           = (defined $cgi->param('action'))          ? $cgi->param('action')          : 'listView';
my $CcatalogID       = (defined $cgi->param('catalogID'))       ? $cgi->param('catalogID')       : $CATALOGID;
my $CcatalogIDreload = (defined $cgi->param('catalogIDreload')) ? $cgi->param('catalogIDreload') : 0;
my $CholidayID       = (defined $cgi->param('holidayID'))       ? $cgi->param('holidayID')       : 'none';
my $Cformule         = (defined $cgi->param('formule'))         ? $cgi->param('formule')         : 0;
my $Cmonth           = (defined $cgi->param('month'))           ? $cgi->param('month')           : 0;
my $Cday             = (defined $cgi->param('day'))             ? $cgi->param('day')             : 0;
my $Coffset          = (defined $cgi->param('offset'))          ? $cgi->param('offset')          : 0;
my $CcountryID       = (defined $cgi->param('countryID'))       ? $cgi->param('countryID')       : 'none';
my $Choliday         = (defined $cgi->param('holiday'))         ? $cgi->param('holiday')         : '';
my $Cactivated       = (defined $cgi->param('activated'))       ? $cgi->param('activated')       : 'off';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Holidays", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&holidayID=$CholidayID&formule$Cformule=&month=$Cmonth&day=$Cday&offset=$Coffset&countryID=$CcountryID&holiday=$Choliday&activated=$Cactivated";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>page no       : $pageNo<br>page offset   : $pageOffset<br>order by      : $orderBy<br>action        : $action<br>catalog ID     : $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br><br>holidayID     : $CholidayID<br>formule       : $Cformule<br>month         : $Cmonth<br>day           : $Cday<br>offset        : $Coffset<br>country ID    : $CcountryID<br>holiday       : $Choliday<br>activated     : $Cactivated<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($catalogIDSelect, $countryIDSelect, $matchingHolidays, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset&amp;catalogID=$CcatalogID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledPrimaryKey = '';

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert Holiday";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
      $CcatalogID   = $CATALOGID if ($action eq 'insertView');
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Holiday $CholidayID from $CcatalogID exist before to insert";

      $CholidayID   = "$Cformule-$Cmonth-$Cday-$Coffset-$CcountryID";
      $sql = "select holidayID from $SERVERTABLHOLIDYS WHERE catalogID = '$CcatalogID' and holidayID = '$CholidayID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle    = "Holiday $CholidayID from $CcatalogID exist already";
        $nextAction   = "insertView";
      } else {
        $htmlTitle    = "Holiday $CholidayID from $CcatalogID inserted";
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLHOLIDYS. ' SET catalogID="' .$CcatalogID. '", holidayID="' .$CholidayID. '", formule="' .$Cformule. '", month="' .$Cmonth. '", day="' .$Cday. '", offset="' .$Coffset. '", countryID="' .$CcountryID. '", holiday="' .$Choliday. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledAll = $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Delete Holiday $CholidayID from $CcatalogID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $sql = "select holidayBundleID, holidayBundleName from $SERVERTABLHOLIDYSBNDL where catalogID='$CcatalogID' and holidayID REGEXP '/$CholidayID/' order by holidayBundleName";
      ($rv, $matchingHolidays) = check_record_exist ($rv, $dbh, $sql, 'Holiday Bundle from ' .$CcatalogID, 'ID', 'Name', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ($matchingHolidays eq '') {
        $sql = 'DELETE FROM ' .$SERVERTABLHOLIDYS. ' WHERE catalogID="' .$CcatalogID. '" and holidayID="' .$CholidayID. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction = "listView" if ($rv);
        $htmlTitle = "Holiday $CholidayID from $CcatalogID deleted";
      } else {
        $htmlTitle = "Holiday $CholidayID from $CcatalogID not deleted, still used by";
      }
    } elsif ($action eq 'displayView') {
      $formDisabledAll = $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Display holiday $CholidayID from $CcatalogID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Edit holiday $CholidayID from $CcatalogID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $matchingHolidays = '';
      my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;

      unless ( $dummyActivated ) {
        $sql = "select holidayBundleID, holidayBundleName from $SERVERTABLHOLIDYSBNDL where catalogID = '$CcatalogID' and holidayID REGEXP '/$CholidayID/' order by holidayBundleName";
        ($rv, $matchingHolidays) = check_record_exist ($rv, $dbh, $sql, 'Holiday Bundle from ' .$CcatalogID, 'ID', 'Name', $matchingHolidays, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      }

	  if ($dummyActivated or $matchingHolidays eq '') {
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'UPDATE ' .$SERVERTABLHOLIDYS. ' SET catalogID="' .$CcatalogID. '", holidayID="' .$CholidayID. '", formule="' .$Cformule. '", month="' .$Cmonth. '", day="' .$Cday. '", offset="' .$Coffset. '", countryID="' .$CcountryID. '", holiday="' .$Choliday. '", activated="' .$dummyActivated. '" WHERE catalogID="' .$CcatalogID. '" and holidayID="' .$CholidayID. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
        $htmlTitle    = "Holiday $CholidayID from $CcatalogID updated";
      } else {
        $htmlTitle    = "Holiday $CholidayID from $CcatalogID not deactivated and updated, still used by";
      }	  
    } elsif ($action eq 'listView') {
      $htmlTitle    = "All holidays listed";

      if ( $CcatalogIDreload ) {
        $pageNo = 1;
        $pageOffset = 0;
      }

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select SQL_NO_CACHE count(holidayID) from $SERVERTABLHOLIDYS where catalogID = '$CcatalogID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID&amp;orderBy=$orderBy");
 
      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLHOLIDYS, 'holiday', "catalogID = '$CcatalogID'", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select $SERVERTABLHOLIDYS.catalogID, $SERVERTABLHOLIDYS.holidayID, $SERVERTABLHOLIDYS.formule, $SERVERTABLHOLIDYS.month, $SERVERTABLHOLIDYS.day, $SERVERTABLHOLIDYS.offset, $SERVERTABLCOUNTRIES.countryName, $SERVERTABLHOLIDYS.holiday, $SERVERTABLHOLIDYS.activated from $SERVERTABLHOLIDYS, $SERVERTABLCOUNTRIES where $SERVERTABLHOLIDYS.catalogID = '$CcatalogID' and $SERVERTABLCOUNTRIES.countryID = $SERVERTABLHOLIDYS.countryID order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header  = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID desc, formule asc, countryName asc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID asc, formule asc, countryName asc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=formule desc, countryName asc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Formule <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=formule asc, countryName desc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=month desc, countryName desc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Month <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=month asc, countryName desc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=day desc, countryName desc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Day <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=day asc, countryName desc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=offset desc, countryName desc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Offset <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=offset asc, countryName desc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      $header .= "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=countryName desc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Country <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=countryName asc, holiday asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=holiday desc, countryName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Holiday <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=holiday asc, countryName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, holiday asc, countryName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, holiday asc, countryName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingHolidays, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Holiday', 'catalogID|holidayID', '0|1', '1', '', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select catalogID, holidayID, formule, month, day, offset, countryID, holiday, activated from $SERVERTABLHOLIDYS where catalogID = '$CcatalogID' and holidayID = '$CholidayID'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcatalogID, $CholidayID, $Cformule, $Cmonth, $Cday, $Coffset, $CcountryID, $Choliday, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);

        if ($action eq 'duplicateView') {
          $CcatalogID = $CATALOGID;
          $CholidayID = '';
        }

        $Cactivated = ($Cactivated == 1) ? 'on' : 'off';
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      $sql = "select countryID, countryName from $SERVERTABLCOUNTRIES where activated = '1' order by countryName";
      ($rv, $countryIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcountryID, 'countryID', 'none', '-Select-', $formDisabledPrimaryKey, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, "onload=\"javascript:enableDisableFields();\"", 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function enableDisableFields() {
  if ( document.holidays.formule.value == 0 ) {
    document.holidays.month.disabled=false;
    document.holidays.day.disabled=false;

    document.holidays.offset.disabled=true;
    document.holidays.offset.value=0;
  } else {
    document.holidays.month.disabled=true;
    document.holidays.day.disabled=true;

    document.holidays.month.value=0;
    document.holidays.day.value=0;

    document.holidays.offset.disabled=false;
  }  
}

function validateForm() {
  if ( document.holidays.formule.value == null || document.holidays.formule.value == '' ) {
    document.holidays.formule.focus();
    alert('Please select a formule!');
    return false;
  } else {
    if ( document.holidays.formule.value == 0 ) {
      // month of year (1-12)
      var objectRegularExpressionMonthValue = /\^([1-9]|1[0-2])\$/;

      if ( document.holidays.month.value == null || document.holidays.month.value == '' ) {
        document.holidays.month.focus();
        alert('Please enter month of year!');
        return false;
      } else {
        if ( ! objectRegularExpressionMonthValue.test(document.holidays.month.value) ) {
          document.holidays.month.focus();
          alert('Please re-enter month of the year: Bad month of the year value!');
          return false;
        }
      }

      // day of month (1-31)
      var objectRegularExpressionDayValue = /\^([1-9]|[1-2][0-9]|3[0-1])\$/;

      if ( document.holidays.day.value == null || document.holidays.day.value == '' ) {
        document.holidays.day.focus();
        alert('Please enter day of the month!');
        return false;
      } else {
        if ( ! objectRegularExpressionDayValue.test(document.holidays.day.value) ) {
          document.holidays.day.focus();
          alert('Please re-enter day of the month: Bad day of the month value!');
          return false;
        }
      }
    }
  }

  // offset (0-364)
  var objectRegularExpressionOffsetValue = /\^([0-9]|[0-9][0-9]|[1-2][0-9][0-9]|[3][0-5][0-9]|[3][6][0-4])\$/;

  if ( document.holidays.offset.value == null || document.holidays.offset.value == '' ) {
    document.holidays.offset.focus();
    alert('Please enter offset!');
    return false;
  } else {
     if ( ! objectRegularExpressionOffsetValue.test(document.holidays.offset.value) ) {
      document.holidays.offset.focus();
      alert('Please re-enter offset: Bad offset value!');
      return false;
    }
  }

  if ( document.holidays.countryID.value == null || document.holidays.countryID.value == 'none' ) {
    document.holidays.countryID.focus();
    alert('Please create/select a country!');
    return false;
  }

  if ( document.holidays.holiday.value == null || document.holidays.holiday.value == '' ) {
    document.holidays.holiday.focus();
    alert('Please enter a holiday name!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="holidays" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'listView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.holidays.catalogIDreload.value = 1;
  document.holidays.submit();
  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="holidays">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"holidays\">\n";
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

    if ($formDisabledPrimaryKey ne '' and $action ne 'displayView') {
      print <<HTML;
  <input type=\"hidden\" name=\"catalogID\" value=\"$CcatalogID\">
  <input type=\"hidden\" name=\"holidayID\" value=\"$CholidayID\">
  <input type=\"hidden\" name=\"formule\"   value=\"$Cformule\">
  <input type=\"hidden\" name=\"month\"     value=\"$Cmonth\">
  <input type=\"hidden\" name=\"day\"       value=\"$Cday\">
  <input type=\"hidden\" name=\"offset\"    value=\"$Coffset\">
  <input type=\"hidden\" name=\"countryID\" value=\"$CcountryID\">
HTML
    }

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;orderBy=$orderBy">[Insert holiday]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all holidays]</a></td>
	  </tr></table>
    </td></tr>
HTML

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      my $formuleSelect = create_combobox_from_keys_and_values_pairs ('0=>Fixed|1=>Easter', 'V', 0, $Cformule, 'formule', '', '', $formDisabledPrimaryKey, 'onChange="javascript:enableDisableFields();"', $debug);
      my $activatedChecked = ($Cactivated eq 'on') ? ' checked' : '';

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Catalog ID: </b></td><td>
          <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled>
        <tr><td><b>Formule: </b></td><td>
          $formuleSelect
        </td></tr>
		<tr><td><b>Month: </b></td><td>
          <input type="text" name="month" value="$Cmonth" size="2" maxlength="2" $formDisabledPrimaryKey>&nbsp;&nbsp;format: 1-12
        </td></tr>
		<tr><td><b>Day: </b></td><td>
          <input type="text" name="day" value="$Cday" size="2" maxlength="2" $formDisabledPrimaryKey>&nbsp;&nbsp;format: 1-31
        </td></tr>
		<tr><td><b>Offset: </b></td><td>
          <input type="text" name="offset" value="$Coffset" size="3" maxlength="3" $formDisabledPrimaryKey>&nbsp;&nbsp;format: 0-364
        </td></tr>
		<tr><td><b>Country: </b></td><td>
          $countryIDSelect
        </td></tr>
		<tr><td><b>Holiday: </b></td><td>
          <input type="text" name="holiday" value="$Choliday" size="64" maxlength="64" $formDisabledAll>
        </td></tr>
		<tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Holiday: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingHolidays</td></tr>" if (defined $matchingHolidays and $matchingHolidays ne '');
    } else {
      print "    <tr><td><br><table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='#333344'><tr><td align=\"left\"><b>Catalog ID: </b></td><td>$catalogIDSelect</td></tr></table></td></tr>";
      print "    <tr><td align=\"center\"><br>$matchingHolidays</td></tr>";
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

