#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, resultsdirs.pl for ASNMTAP::Asnmtap::Applications::CGI
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

$PROGNAME       = "resultsdirs.pl";
my $prgtext     = "Resultsdirs";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : 'admin';   $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : 'F';
my $pageNo              = (defined $cgi->param('pageNo'))          ? $cgi->param('pageNo')          : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))      ? $cgi->param('pageOffset')      : 0;
my $orderBy             = (defined $cgi->param('orderBy'))         ? $cgi->param('orderBy')         : 'resultsdir asc';
my $action              = (defined $cgi->param('action'))          ? $cgi->param('action')          : 'listView';
my $CcatalogID          = (defined $cgi->param('catalogID'))       ? $cgi->param('catalogID')       : $CATALOGID;
my $CcatalogIDreload    = (defined $cgi->param('catalogIDreload')) ? $cgi->param('catalogIDreload') : 0;
my $Cresultsdir         = (defined $cgi->param('resultsdir'))      ? $cgi->param('resultsdir')      : '';
my $CgroupName          = (defined $cgi->param('groupName'))       ? $cgi->param('groupName')       : '';
my $Cactivated          = (defined $cgi->param('activated'))       ? $cgi->param('activated')       : 'off';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Resultsdir", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&resultsdir=$Cresultsdir&groupName=$CgroupName&activated=$Cactivated";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>page no           : $pageNo<br>page offset       : $pageOffset<br>order by          : $orderBy<br>action            : $action<br>catalog ID        : $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br>resultsdir        : $Cresultsdir<br>groupName         : $CgroupName<br>activated         : $Cactivated<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($catalogIDSelect, $matchingResultsdir, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;catalogID=$CcatalogID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledPrimaryKey = '';

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert Resultsdir";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
      $CcatalogID   = $CATALOGID if ($action eq 'insertView');
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Resultsdir $Cresultsdir from $CcatalogID exist before to insert";

      $sql = "select resultsdir from $SERVERTABLRESULTSDIR WHERE catalogID='$CcatalogID' and resultsdir='$Cresultsdir'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle  = "Resultsdir $Cresultsdir from $CcatalogID exist already";
        $nextAction = "insertView";
      } else {
        $htmlTitle  = "Resultsdir $Cresultsdir from $CcatalogID inserted";
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLRESULTSDIR. ' SET catalogID="' .$CcatalogID. '", resultsdir="' .$Cresultsdir. '", groupName="' .$CgroupName. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Delete Resultsdir $Cresultsdir from $CcatalogID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where catalogID = '$CcatalogID' and resultsdir = '$Cresultsdir' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by title, uKey";
      ($rv, $matchingResultsdir) = check_record_exist ($rv, $dbh, $sql, 'Plugins from ' .$CcatalogID, 'Unique Key', 'Title', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ($matchingResultsdir eq '') {
        $htmlTitle = "Resultsdir $Cresultsdir from $CcatalogID deleted";
        $sql = 'DELETE FROM ' .$SERVERTABLRESULTSDIR. ' WHERE catalogID="' .$CcatalogID. '" and resultsdir="' .$Cresultsdir. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      } else {
        $htmlTitle = "Resultsdir $Cresultsdir from $CcatalogID not deleted, still used by";
      }

      $nextAction = "listView" if ($rv);
    } elsif ($action eq 'displayView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Display Resultsdir $Cresultsdir from $CcatalogID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Edit Resultsdir $Cresultsdir from $CcatalogID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $htmlTitle    = "Resultsdir $Cresultsdir from $CcatalogID updated";
      my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLRESULTSDIR. ' SET catalogID="' .$CcatalogID. '", resultsdir="' .$Cresultsdir. '", groupName="' .$CgroupName. '", activated="' .$dummyActivated. '" WHERE catalogID="' .$CcatalogID. '" and resultsdir="' .$Cresultsdir. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'listView') {
      $htmlTitle    = "All resultsdir listed";

      if ( $CcatalogIDreload ) {
        $pageNo = 1;
        $pageOffset = 0;
      }

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select SQL_NO_CACHE count(resultsdir) from $SERVERTABLRESULTSDIR where catalogID = '$CcatalogID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID&amp;orderBy=$orderBy");

      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLRESULTSDIR, 'groupName', "catalogID = '$CcatalogID'", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select catalogID, resultsdir, groupName, activated from $SERVERTABLRESULTSDIR where catalogID = '$CcatalogID' order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID desc, resultsdir asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID asc, resultsdir asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=resultsdir desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Resultdir <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=resultsdir asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Group Name <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingResultsdir, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Resultsdir', 'catalogID|resultsdir', '0|1', '', '', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select catalogID, resultsdir, groupName, activated from $SERVERTABLRESULTSDIR where catalogID='$CcatalogID' and resultsdir='$Cresultsdir'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcatalogID, $Cresultsdir, $CgroupName, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $CcatalogID = $CATALOGID if ($action eq 'duplicateView');
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

  var objectRegularExpressionResultsdirFormat = /\^[a-zA-Z0-9-]\+\$/;

  if ( document.resultsdir.resultsdir.value == null || document.resultsdir.resultsdir.value == '' ) {
    document.resultsdir.resultsdir.focus();
    alert('Please enter a resultsdir!');
    return false;
  } else {
    if ( ! objectRegularExpressionResultsdirFormat.test(document.resultsdir.resultsdir.value) ) {
      document.resultsdir.resultsdir.focus();
      alert('Please re-enter resultsdir: Bad resultsdir format!');
      return false;
    }
  }
HTML
      }

      print <<HTML;

  if ( document.resultsdir.groupName.value == null || document.resultsdir.groupName.value == '' ) {
    document.resultsdir.groupName.focus();
    alert('Please enter a group name!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="resultsdir" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'listView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.resultsdir.catalogIDreload.value = 1;
  document.resultsdir.submit();
  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="resultsdir">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"resultsdir\">\n";
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

    print "  <input type=\"hidden\" name=\"catalogID\" value=\"$CcatalogID\">\n  <input type=\"hidden\" name=\"resultsdir\" value=\"$Cresultsdir\">\n" if ($formDisabledPrimaryKey ne '' and $action ne 'displayView');

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=insertView&amp;orderBy=$orderBy">[Insert resultsdir]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=listView&amp;orderBy=$orderBy">[List all resultsdir]</a></td>
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
        <tr><td><b>Resultsdir: </b></td><td>
          <input type="text" name="resultsdir" value="$Cresultsdir" size="64" maxlength="64" $formDisabledPrimaryKey>
        <tr><td><b>Group Name: </b></td><td>
          <input type="text" name="groupName" value="$CgroupName" size="64" maxlength="64" $formDisabledAll>
        <tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Unique Key: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingResultsdir</td></tr>" if (defined $matchingResultsdir and $matchingResultsdir ne '');
    } else {
      print "    <tr><td><br><table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='#333344'><tr><td align=\"left\"><b>Catalog ID: </b></td><td>$catalogIDSelect</td></tr></table></td></tr>";
      print "    <tr><td align=\"center\"><br>$matchingResultsdir</td></tr>";
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
