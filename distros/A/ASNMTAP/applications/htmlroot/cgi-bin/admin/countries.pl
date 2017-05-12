#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, countries.pl for ASNMTAP::Asnmtap::Applications::CGI
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

$PROGNAME       = "countries.pl";
my $prgtext     = "Countries";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir      = (defined $cgi->param('pagedir'))     ? $cgi->param('pagedir')     : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset      = (defined $cgi->param('pageset'))     ? $cgi->param('pageset')     : 'admin';   $pageset =~ s/\+/ /g;
my $debug        = (defined $cgi->param('debug'))       ? $cgi->param('debug')       : 'F';
my $pageNo       = (defined $cgi->param('pageNo'))      ? $cgi->param('pageNo')      : 1;
my $pageOffset   = (defined $cgi->param('pageOffset'))  ? $cgi->param('pageOffset')  : 0;
my $orderBy      = (defined $cgi->param('orderBy'))     ? $cgi->param('orderBy')     : 'countryName';
my $action       = (defined $cgi->param('action'))      ? $cgi->param('action')      : 'listView';
my $CcountryID   = (defined $cgi->param('countryID'))   ? $cgi->param('countryID')   : '';
my $CcountryName = (defined $cgi->param('countryName')) ? $cgi->param('countryName') : '';
my $Cactivated   = (defined $cgi->param('activated'))   ? $cgi->param('activated')   : 'off';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Countries", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&countryID=$CcountryID&countryName=$CcountryName&activated=$Cactivated";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>page no       : $pageNo<br>page offset   : $pageOffset<br>order by      : $orderBy<br>action        : $action<br>country ID    : $CcountryID<br>country Name  : $CcountryName<br>activated     : $Cactivated<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($matchingCountries, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledPrimaryKey = '';

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert Country";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Country $CcountryID exist before to insert";

      $sql = "select countryID from $SERVERTABLCOUNTRIES WHERE countryID='$CcountryID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle    = "Country $CcountryID exist already";
        $nextAction   = "insertView";
      } else {
        $htmlTitle    = "Country $CcountryID inserted";
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLCOUNTRIES. ' SET countryID="' .$CcountryID. '", countryName="' .$CcountryName. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledAll = $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Delete Country $CcountryID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $matchingCountries = ($CcountryID eq '00') ? "<h1>Countries:</h1><table><th>ID</th><th>country</th><tr><td>00</td><td>+ All countries</td></tr></table>\n" : '';

      $sql = "select holidayID, holiday from $SERVERTABLHOLIDYS where countryID = '$CcountryID' order by holiday";
      ($rv, $matchingCountries) = check_record_exist ($rv, $dbh, $sql, 'Holidays', 'ID', 'Holiday', $matchingCountries, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select holidayBundleID, holidayBundleName from $SERVERTABLHOLIDYSBNDL where countryID = '$CcountryID' order by holidayBundleID";
      ($rv, $matchingCountries) = check_record_exist ($rv, $dbh, $sql, 'Holiday Bundle', 'ID', 'Name', $matchingCountries, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ($matchingCountries eq '') {
        $sql = 'DELETE FROM ' .$SERVERTABLCOUNTRIES. ' WHERE countryID="' .$CcountryID. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction = "listView" if ($rv);
        $htmlTitle = "Country $CcountryID deleted";
      } else {
        $htmlTitle = "Country $CcountryID not deleted, still used by";
      }
    } elsif ($action eq 'displayView') {
      $formDisabledAll = $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Display country $CcountryID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Edit country $CcountryID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
      $matchingCountries = ($CcountryID eq '00') ? "<h1>Countries:</h1><table><tr><th>ID</th><th>country</th><tr><td>00</td><td>+ All countries</td></tr></table>\n" : '';

      unless ( $dummyActivated ) {
        $sql = "select holidayID, holiday from $SERVERTABLHOLIDYS where countryID = '$CcountryID'";
        ($rv, $matchingCountries) = check_record_exist ($rv, $dbh, $sql, 'Holidays', 'ID', 'Name', $matchingCountries, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

        $sql = "select holidayBundleID, holidayBundleName from $SERVERTABLHOLIDYSBNDL where countryID = '$CcountryID' order by  holidayBundleID";
        ($rv, $matchingCountries) = check_record_exist ($rv, $dbh, $sql, 'Holiday Bundle', 'ID', 'Name', $matchingCountries, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      }
	  
	  if ($dummyActivated or $matchingCountries eq '') {
        $sql = 'UPDATE ' .$SERVERTABLCOUNTRIES. ' SET countryID="' .$CcountryID. '", countryName="' .$CcountryName. '", activated="' .$dummyActivated. '" WHERE countryID="' .$CcountryID. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
        $htmlTitle    = "Country $CcountryID updated";
      } else {
        $htmlTitle    = "Country $CcountryID not deactivated and updated, still used by";
      }
    } elsif ($action eq 'listView') {
      $htmlTitle    = "All countries listed";

      $sql = "select SQL_NO_CACHE count(countryID) from $SERVERTABLCOUNTRIES";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;orderBy=$orderBy");
 
      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLCOUNTRIES, 'countryName', "'1'", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select countryID, countryName, activated from $SERVERTABLCOUNTRIES order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=countryID desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Country ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=countryID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=countryName desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Country Name <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=countryName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, countryName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, countryName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingCountries, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Country', 'countryID', '0', '', '', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select countryID, countryName, activated from $SERVERTABLCOUNTRIES where countryID = '$CcountryID'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcountryID, $CcountryName, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
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

  if ( document.countries.countryID.value == null || document.countries.countryID.value == '' ) {
    document.countries.countryID.focus();
    alert('Please enter a country ID!');
    return false;
  }

  if ( document.countries.countryName.value == null || document.countries.countryName.value == '' ) {
    document.countries.countryName.focus();
    alert('Please enter a country name!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="countries" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"countries\">\n";
      $pageNo = 1; $pageOffset = 0;
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    }

    if ($action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      print <<HTML;
  <input type="hidden" name="pagedir"    value="$pagedir">
  <input type="hidden" name="pageset"    value="$pageset">
  <input type="hidden" name="debug"      value="$debug">
  <input type="hidden" name="CGISESSID"  value="$sessionID">
  <input type="hidden" name="pageNo"     value="$pageNo">
  <input type="hidden" name="pageOffset" value="$pageOffset">
  <input type="hidden" name="action"     value="$nextAction">
  <input type="hidden" name="orderBy"    value="$orderBy">
HTML
    } else {
      print "<br>\n";
    }

    print "  <input type=\"hidden\" name=\"countryID\"   value=\"$CcountryID\">\n" if ($formDisabledPrimaryKey ne '' and $action ne 'displayView');

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
      <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;orderBy=$orderBy">[Insert country]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all countries]</a></td>
	  </tr></table>
	</td></tr>
HTML

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      my $activatedChecked = ($Cactivated eq 'on') ? ' checked' : '';

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Country ID: </b></td><td>
          <input type="text" name="countryID" value="$CcountryID" size="2" maxlength="2" $formDisabledPrimaryKey>
        </td></tr><tr><td><b>Country Name: </b></td><td>
          <input type="text" name="countryName" value="$CcountryName" size="45" maxlength="45" $formDisabledAll>
        </td></tr><tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Country: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingCountries</td></tr>" if (defined $matchingCountries and $matchingCountries ne '');
    } else {
      print "    <tr><td align=\"center\"><br>$matchingCountries</td></tr>";
    }

    print "  </table>\n";

    if ($action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
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

