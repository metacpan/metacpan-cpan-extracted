#!/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, catalog.pl for ASNMTAP::Asnmtap::Applications::CGI
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

$PROGNAME       = "catalog.pl";
my $prgtext     = "Catalog";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))        ? $cgi->param('pagedir')        : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))        ? $cgi->param('pageset')        : 'sadmin';  $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))          ? $cgi->param('debug')          : 'F';
my $pageNo              = (defined $cgi->param('pageNo'))         ? $cgi->param('pageNo')         : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))     ? $cgi->param('pageOffset')     : 0;
my $orderBy             = (defined $cgi->param('orderBy'))        ? $cgi->param('orderBy')        : 'catalogName';
my $action              = (defined $cgi->param('action'))         ? $cgi->param('action')         : 'listView';
my $CcatalogID          = (defined $cgi->param('catalogID'))      ? $cgi->param('catalogID')      : $CATALOGID;
my $CcatalogName        = (defined $cgi->param('catalogName'))    ? $cgi->param('catalogName')    : 'Central Application Monitor';
my $CcatalogType        = (defined $cgi->param('catalogType'))    ? $cgi->param('catalogType')    : 'Central';
my $CdatabaseFQDN       = (defined $cgi->param('databaseFQDN'))   ? $cgi->param('databaseFQDN')   : 'localhost';
my $CdatabasePort       = (defined $cgi->param('databasePort'))   ? $cgi->param('databasePort')   : 3306;
my $ClastEventsID       = (defined $cgi->param('lastEventsID'))   ? $cgi->param('lastEventsID')   : 0;
my $ClastCommentsID     = (defined $cgi->param('lastCommentsID')) ? $cgi->param('lastCommentsID') : 0;
my $Cactivated          = (defined $cgi->param('activated'))      ? $cgi->param('activated')      : 'off';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Catalog", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&catalogID=$CcatalogID&catalogName=$CcatalogName&catalogType=$CcatalogType&databaseFQDN=$CdatabaseFQDN&databasePort=$CdatabasePort&lastEventsID=$ClastEventsID&lastCommentsID=$ClastCommentsID&activated=$Cactivated";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>page no           : $pageNo<br>page offset       : $pageOffset<br>order by          : $orderBy<br>action            : $action<br>catalog ID        : $CcatalogID<br>catalogName       : $CcatalogName<br>catalogType       : $CcatalogType<br>databaseFQDN      : $CdatabaseFQDN<br>databasePort      : $CdatabasePort<br>lastEventsID      : $ClastEventsID<br>lastCommentsID    : $ClastCommentsID<br>activated         : $Cactivated<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($matchingCatalog, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledPrimaryKey = '';

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert Catalog";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Catalog $CcatalogID from $CATALOGID exist before to insert";

      $sql = "select catalogID from $SERVERTABLCATALOG WHERE catalogID = '$CcatalogID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle    = "Catalog $CcatalogID from $CATALOGID exist already";
        $nextAction   = "insertView";
      } else {
        $htmlTitle    = "Catalog $CcatalogID from $CATALOGID inserted";
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;

        $sql = 'INSERT INTO ' .$SERVERTABLCATALOG. ' SET catalogID="' .$CcatalogID. '", catalogName="' .$CcatalogName. '", catalogType="' .$CcatalogType. '", databaseFQDN="' .$CdatabaseFQDN. '", databasePort="' .$CdatabasePort. '", lastEventsID="' .$ClastEventsID. '", lastCommentsID="' .$ClastCommentsID. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Delete catalog $CcatalogID from $CATALOGID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $htmlTitle = "Catalog $CcatalogID from $CATALOGID deleted";
      $sql = 'DELETE FROM ' .$SERVERTABLCATALOG. ' WHERE catalogID="' .$CcatalogID. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'displayView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Display catalog $CcatalogID from $CATALOGID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $htmlTitle    = "Edit catalog $CcatalogID from $CATALOGID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $htmlTitle    = "Catalog $CcatalogID from $CATALOGID updated";
      my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLCATALOG. ' SET catalogID="' .$CcatalogID. '", catalogName="' .$CcatalogName. '", catalogType="' .$CcatalogType. '", databaseFQDN="' .$CdatabaseFQDN. '", databasePort="' .$CdatabasePort. '", lastEventsID="' .$ClastEventsID. '", lastCommentsID="' .$ClastCommentsID. '", activated="' .$dummyActivated. '" WHERE catalogID="' .$CcatalogID. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'listView') {
      $htmlTitle    = "All catalogs listed";
      $nextAction   = "listView";

      $sql = "select SQL_NO_CACHE count(catalogID) from $SERVERTABLCATALOG";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID&amp;orderBy=$orderBy");

      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLCATALOG, 'catalogName', "'1'", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select catalogID, catalogName, catalogType, activated from $SERVERTABLCATALOG order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogType desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog Type <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogType asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingCatalog, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Catalog', 'catalogID', '0', '', '2#central=>Central|federated=>Federated|probe=>Probe|distributed=>Distributed', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select catalogID, catalogName, catalogType, databaseFQDN, databasePort, lastEventsID, lastCommentsID, activated from $SERVERTABLCATALOG where catalogID = '$CcatalogID'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcatalogID, $CcatalogName, $CcatalogType, $CdatabaseFQDN, $CdatabasePort, $ClastEventsID, $ClastCommentsID, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
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
HTML

      if ($action eq 'duplicateView' or $action eq 'insertView') {
        print <<HTML;

  var objectRegularExpressionCatalogIDFormat = /\^[a-zA-Z]\+\$/;

  if ( document.catalog.catalogID.value == null || document.catalog.catalogID.value == '' ) {
    document.catalog.catalogID.focus();
    alert('Please enter a catalogID!');
    return false;
  } else {
    if ( ! objectRegularExpressionCatalogIDFormat.test(document.catalog.catalogID.value) ) {
      document.catalog.catalogID.focus();
      alert('Please re-enter catalogID: Bad catalogID format!');
      return false;
    }
  }
HTML
      }

      print <<HTML;

  if ( document.catalog.catalogName.value == null || document.catalog.catalogName.value == '' ) {
    document.catalog.catalogName.focus();
    alert('Please enter a catalog name!');
    return false;
  }

  var objectRegularExpressionFQDNValue  = /\^[a-zA-Z0-9-]\+(\\.[a-zA-Z0-9-]\+)\*\$/;

  if ( ! (document.catalog.databaseFQDN.value == null || document.catalog.databaseFQDN.value == '' ) ) {
    if ( ! objectRegularExpressionFQDNValue.test(document.catalog.databaseFQDN.value) ) {
      document.catalog.databaseFQDN.focus();
      alert('Please re-enter database FQDN: Bad database FQDN value!');
      return false;
    }
  }

  var objectRegularExpressionDatabasePort = /\^[0-9]\+\$/;

  if ( ! (document.catalog.databasePort.value == null || document.catalog.databasePort.value == '' ) ) {
    if ( ! objectRegularExpressionDatabasePort.test(document.catalog.databasePort.value) ) {
      document.catalog.databasePort.focus();
      alert('Please re-enter database port: Bad database port value!');
      return false;
    }
  }

  var objectRegularExpressionID = /\^[0-9]\+\$/;

  if ( ! (document.catalog.lastEventsID.value == null || document.catalog.lastEventsID.value == '' ) ) {
    if ( ! objectRegularExpressionID.test(document.catalog.lastEventsID.value) ) {
      document.catalog.lastEventsID.focus();
      alert('Please re-enter Last Events ID: Bad Last Events ID value!');
      return false;
    }
  }

  if ( ! (document.catalog.lastCommentsID.value == null || document.catalog.lastCommentsID.value == '' ) ) {
    if ( ! objectRegularExpressionID.test(document.catalog.lastCommentsID.value) ) {
      document.catalog.lastCommentsID.focus();
      alert('Please re-enter Last Comments ID: Bad Last Comments ID value!');
      return false;
    }
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="catalog" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"catalog\">\n";
      $pageNo = 1; $pageOffset = 0;
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    }

    if ($action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      print <<HTML;
  <input type="hidden" name="pagedir"      value="$pagedir">
  <input type="hidden" name="pageset"      value="$pageset">
  <input type="hidden" name="debug"        value="$debug">
  <input type="hidden" name="CGISESSID"    value="$sessionID">
  <input type="hidden" name="pageNo"       value="$pageNo">
  <input type="hidden" name="pageOffset"   value="$pageOffset">
  <input type="hidden" name="action"       value="$nextAction">
  <input type="hidden" name="orderBy"      value="$orderBy">
HTML
    } else {
      print "<br>\n";
    }

    print "  <input type=\"hidden\" name=\"catalogID\" value=\"$CcatalogID\">\n" if ($formDisabledPrimaryKey ne '' and $action ne 'displayView');

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=insertView&amp;orderBy=$orderBy">[Insert Catalog ID]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=listView&amp;orderBy=$orderBy">[List all Catalog ID's]</a></td>
	  </tr></table>
    </td></tr>
HTML

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      my $catalogTypeSelect = create_combobox_from_keys_and_values_pairs ('central=>Central|federated=>Federated|distributed=>Distributed', 'K', 0, $CcatalogType, 'catalogType', '', '', $formDisabledAll, 'onChange="javascript:enableOrDisableFields();"', $debug);

      my $activatedChecked = ($Cactivated eq 'on') ? ' checked' : '';

      print <<HTML;
      <tr><td>&nbsp;</td></tr>
      <tr><td>
	    <table border="0" cellspacing="0" cellpadding="0">
          <tr><td><b>Catalog ID: </b></td><td>
            <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" $formDisabledPrimaryKey>
          </td></tr>
          <tr><td><b>Catalog Name: </b></td><td>
            <input type="text" name="catalogName" value="$CcatalogName" size="64" maxlength="64" $formDisabledAll>
          </td></tr>
          <tr><td><b>Catalog Type: </b></td><td>
            $catalogTypeSelect
          </td></tr>
          <tr><td><b>Database FQDN: </b></td><td>
            <input type="text" name="databaseFQDN" value="$CdatabaseFQDN" size="64" maxlength="64" $formDisabledAll>
          </td></tr>
          <tr><td><b>Database Port: </b></td><td>
            <input type="text" name="databasePort" value="$CdatabasePort" size="4" maxlength="4" $formDisabledAll>
          </td></tr>
          <tr><td><b>Last Events ID: </b></td><td>
            <input type="text" name="lastEventsID" value="$ClastEventsID" size="11" maxlength="11" $formDisabledAll>
          </td></tr>
          <tr><td><b>Last Comments ID: </b></td><td>
            <input type="text" name="lastCommentsID" value="$ClastCommentsID" size="11" maxlength="11" $formDisabledAll>
          </td></tr>
          <tr><td><b>Activated: </b></td><td>
            <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
          </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Unique Key: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingCatalog</td></tr>" if (defined $matchingCatalog and $matchingCatalog ne '');
    } else {
      print "    <tr><td align=\"center\"><br>$matchingCatalog</td></tr>";
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

