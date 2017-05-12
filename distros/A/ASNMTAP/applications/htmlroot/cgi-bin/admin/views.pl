#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, views.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;

# ----------------------------------------------------------------------------------------------------------

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :SADMIN :DBREADWRITE :DBTABLES);

# ----------------------------------------------------------------------------------------------------------

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "views.pl";
my $prgtext     = "Views";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : 'admin';   $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : 'F';
my $pageNo              = (defined $cgi->param('pageNo'))          ? $cgi->param('pageNo')          : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))      ? $cgi->param('pageOffset')      : 0;
my $orderBy             = (defined $cgi->param('orderBy'))         ? $cgi->param('orderBy')         : 'displayDaemon';
my $action              = (defined $cgi->param('action'))          ? $cgi->param('action')          : 'listView';
my $CcatalogID          = (defined $cgi->param('catalogID'))       ? $cgi->param('catalogID')       : $CATALOGID;
my $CcatalogIDreload    = (defined $cgi->param('catalogIDreload')) ? $cgi->param('catalogIDreload') : 0;
my $CuKey               = (defined $cgi->param('uKey'))            ? $cgi->param('uKey')            : 'none';
my $CdisplayDaemon      = (defined $cgi->param('displayDaemon'))   ? $cgi->param('displayDaemon')   : 'none';
my $CdisplayGroupID     = (defined $cgi->param('displayGroupID'))  ? $cgi->param('displayGroupID')  : 'none';
my $CtimeperiodID       = (defined $cgi->param('timeperiodID'))    ? $cgi->param('timeperiodID')    : 'none';
my $Cactivated          = (defined $cgi->param('activated'))       ? $cgi->param('activated')       : 'off';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton, $uKeySelect);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Views", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&uKey=$CuKey&displayDaemon=$CdisplayDaemon&displayGroupID=$CdisplayGroupID&timeperiodID=$CtimeperiodID&activated=$Cactivated";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>page no           : $pageNo<br>page offset       : $pageOffset<br>order by          : $orderBy<br>action            : $action<br>catalog ID        : $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br>uKey              : $CuKey<br>displayDaemon     : $CdisplayDaemon<br>group title       : $CdisplayGroupID<br>Support window    : $CtimeperiodID<br>activated         : $Cactivated<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($catalogIDSelect, $displayDaemonSelect, $displayGroupSelect, $matchingViews, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset&amp;catalogID=$CcatalogID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledPrimaryKey = '';

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert View";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
      $CcatalogID   = $CATALOGID if ($action eq 'insertView');
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if View $CdisplayDaemon, $CuKey from $CcatalogID exist before to insert";

      $sql = "select displayGroupID from $SERVERTABLVIEWS WHERE catalogID='$CcatalogID' and displayDaemon='$CdisplayDaemon' and uKey='$CuKey'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle    = "View $CdisplayDaemon, $CuKey from $CcatalogID exist already";
        $nextAction   = "insertView";
      } else {
        $htmlTitle    = "View $CdisplayDaemon, $CuKey from $CcatalogID inserted";
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLVIEWS. ' SET catalogID="' .$CcatalogID. '", uKey="' .$CuKey. '", displayDaemon="' .$CdisplayDaemon. '", displayGroupID="' .$CdisplayGroupID. '", timeperiodID="' .$CtimeperiodID. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'viewView') {
      $htmlTitle    = "Selected views to be listed";
      $submitButton = "Views";
      $nextAction   = "view" if ($rv);
    } elsif ($action eq 'deleteView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Delete view $CdisplayDaemon, $CuKey from $CcatalogID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $htmlTitle    = "View $CdisplayDaemon, $CuKey from $CcatalogID deleted";
      $sql = 'DELETE FROM ' .$SERVERTABLVIEWS. ' WHERE catalogID="' .$CcatalogID. '" and displayDaemon="' .$CdisplayDaemon. '" and uKey="' .$CuKey. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'displayView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Display view $CdisplayDaemon, $CuKey from $CcatalogID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Edit view $CdisplayDaemon, $CuKey from $CcatalogID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $htmlTitle    = "View $CdisplayDaemon, $CuKey from $CcatalogID updated";
      my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLVIEWS. ' SET catalogID="' .$CcatalogID. '", uKey="' .$CuKey. '", displayDaemon="' .$CdisplayDaemon. '", displayGroupID="' .$CdisplayGroupID. '", timeperiodID="' .$CtimeperiodID. '", activated="' .$dummyActivated. '" WHERE catalogID="' .$CcatalogID. '" and displayDaemon="' .$CdisplayDaemon. '" and uKey="' .$CuKey. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'listView' or $action eq 'view') {
      my ($sqlWhereCount, $sqlWhereList, $urlWithAccessParametersQuery);
      $sqlWhereCount = $sqlWhereList = $urlWithAccessParametersQuery = '';

      if ( $CcatalogIDreload ) {
        $pageNo = 1;
        $pageOffset = 0;
      }

      if ($action eq 'view') {
        $htmlTitle      = "All selected views listed";
        $nextAction     = "view";
	
        $sqlWhereCount  = "where $SERVERTABLVIEWS.activated=";
        $sqlWhereCount .= ($Cactivated eq 'on') ? '1' : '0';
        $sqlWhereCount .= " and $SERVERTABLVIEWS.catalogID='$CcatalogID'";
        $sqlWhereCount .= " and $SERVERTABLVIEWS.uKey='$CuKey'" if ($CuKey ne 'none');
        $sqlWhereCount .= " and $SERVERTABLVIEWS.displayDaemon='$CdisplayDaemon'" if ($CdisplayDaemon ne 'none');

        $sqlWhereList   = "$SERVERTABLVIEWS.activated=";
        $sqlWhereList  .= ($Cactivated eq 'on') ? '1' : '0';
        $sqlWhereList  .= " and $SERVERTABLVIEWS.catalogID='$CcatalogID'";
        $sqlWhereList  .= " and $SERVERTABLVIEWS.uKey='$CuKey'" if ($CuKey ne 'none');
        $sqlWhereList  .= " and $SERVERTABLVIEWS.displayDaemon='$CdisplayDaemon'" if ($CdisplayDaemon ne 'none');
        $sqlWhereList  .= " and";

      # $urlWithAccessParametersQuery = "&activated=$Cactivated&catalogID=$CcatalogID&uKey=$CuKey&displayDaemon=$CdisplayDaemon";
        $urlWithAccessParametersQuery = "&activated=$Cactivated";
      } else {
        $htmlTitle      = "All views listed";
        $nextAction     = "listView";

        $sqlWhereCount  = "where $SERVERTABLVIEWS.catalogID='$CcatalogID'";
        $sqlWhereList   = " $SERVERTABLVIEWS.catalogID='$CcatalogID' and";
      # $urlWithAccessParametersQuery = "&catalogID=$CcatalogID";
        $urlWithAccessParametersQuery = "";
      }

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select SQL_NO_CACHE count(uKey) from $SERVERTABLVIEWS $sqlWhereCount";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&action=$nextAction&orderBy=$orderBy$urlWithAccessParametersQuery");

      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLVIEWS, 'displayDaemon', "catalogID = '$CcatalogID'", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

    # $sql = "select $SERVERTABLVIEWS.catalogID, $SERVERTABLVIEWS.displayDaemon, $SERVERTABLVIEWS.uKey, $SERVERTABLDISPLAYDMNS.groupName, $SERVERTABLDISPLAYGRPS.groupTitle, concat( LTRIM(SUBSTRING_INDEX($SERVERTABLPLUGINS.title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ), $SERVERTABLVIEWS.activated from $SERVERTABLVIEWS, $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT, $SERVERTABLDISPLAYDMNS, $SERVERTABLDISPLAYGRPS where $sqlWhereList $SERVERTABLVIEWS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLDISPLAYDMNS.displayDaemon = $SERVERTABLVIEWS.displayDaemon and $SERVERTABLVIEWS.displayGroupID = $SERVERTABLDISPLAYGRPS.displayGroupID and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $sql = "select $SERVERTABLVIEWS.catalogID, $SERVERTABLVIEWS.displayDaemon, $SERVERTABLVIEWS.uKey, $SERVERTABLDISPLAYDMNS.groupName, $SERVERTABLDISPLAYGRPS.groupTitle, concat( LTRIM(SUBSTRING_INDEX($SERVERTABLPLUGINS.title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ), $SERVERTABLVIEWS.activated from $SERVERTABLVIEWS, $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT, $SERVERTABLDISPLAYDMNS, $SERVERTABLDISPLAYGRPS where $sqlWhereList $SERVERTABLVIEWS.catalogID = $SERVERTABLPLUGINS.catalogID and $SERVERTABLVIEWS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLDISPLAYDMNS.catalogID = $SERVERTABLVIEWS.catalogID and $SERVERTABLDISPLAYDMNS.displayDaemon = $SERVERTABLVIEWS.displayDaemon and $SERVERTABLVIEWS.catalogID = $SERVERTABLDISPLAYGRPS.catalogID and $SERVERTABLVIEWS.displayGroupID = $SERVERTABLDISPLAYGRPS.displayGroupID and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by $orderBy limit $pageOffset, $RECORDSONPAGE";

      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID desc, groupName asc, groupTitle asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID asc, groupName asc, groupTitle asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=displayDaemon desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Display Daemon <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=displayDaemon asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName desc, groupTitle asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Group Name <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupName asc, groupTitle asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupTitle desc, groupName asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Group Title <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=groupTitle asc, groupName asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      $header .= "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title desc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Title <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title asc, groupName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, groupName asc, groupTitle, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, groupName asc, groupTitle, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";

      ($rv, $matchingViews, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'View', 'catalogID|displayDaemon|uKey', '0|1|2', '2', '', $urlWithAccessParametersQuery, $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select catalogID, uKey, displayDaemon, displayGroupID, timeperiodID, activated from $SERVERTABLVIEWS where catalogID='$CcatalogID' and displayDaemon='$CdisplayDaemon' and uKey='$CuKey'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcatalogID, $CuKey, $CdisplayDaemon, $CdisplayGroupID, $CtimeperiodID, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $CcatalogID = $CATALOGID if ($action eq 'duplicateView');
        $Cactivated = ($Cactivated == 1) ? 'on' : 'off';
      # $CtimeperiodID = 
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }
    }

    if ($action eq 'insertView' or $action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'displayView' or $action eq 'editView' or $action eq 'viewView') {
      if ($CuKey eq 'none' or $action eq 'duplicateView') {
        $sql = "select uKey, concat( title, ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by optionValueTitle";
      } else {
        $sql = "select uKey, concat( title, ' (', $SERVERTABLENVIRONMENT.label, ')' ) from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where uKey = '$CuKey' and catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment";
      }

      ($rv, $uKeySelect, $htmlTitle) = create_combobox_from_DBI ($rv, $dbh, $sql, 0, $nextAction, $CuKey, 'uKey', 'none', '-Select-', $formDisabledPrimaryKey, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select displayDaemon, groupName from $SERVERTABLDISPLAYDMNS where catalogID = '$CcatalogID' order by groupName";
      ($rv, $displayDaemonSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CdisplayDaemon, 'displayDaemon', 'none', '-Select-', $formDisabledPrimaryKey, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select displayGroupID, groupTitle from $SERVERTABLDISPLAYGRPS where catalogID = '$CcatalogID' order by groupTitle";
      ($rv, $displayGroupSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CdisplayGroupID, 'displayGroupID', 'none', '-Select-', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView' or $action eq 'viewView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
HTML

      if ($action eq 'duplicateView' or $action eq 'insertView') {
        print <<HTML;

  if ( document.views.displayDaemon.options[document.views.displayDaemon.selectedIndex].value == 'none' ) {
    document.views.displayDaemon.focus();
    alert('Please create/select a view display daemon!');
    return false;
  }

  if( document.views.uKey.options[document.views.uKey.selectedIndex].value == 'none' ) {
    document.views.uKey.focus();
    alert('Please create/select one of the applications!');
    return false;
  }
HTML
      }

      if ($action eq 'editView' or $action eq 'duplicateView' or $action eq 'insertView') {
        print <<HTML;

  if ( document.views.displayGroupID.options[document.views.displayGroupID.selectedIndex].value == 'none' ) {
    document.views.displayGroupID.focus();
    alert('Please create/select a view display group!');
    return false;
  }

  if ( document.views.timeperiodID.value == null || document.views.timeperiodID.value == 'none' ) {
    document.views.timeperiodID.focus();
    alert('Please create/select one of the Support windows!');
    return false;
  }
HTML
      }
	
      print <<HTML;
  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="views" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'listView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.views.catalogIDreload.value = 1;
  document.views.submit();
  return true;
}

</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="views">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"views\">\n";
      $pageNo = 1; $pageOffset = 0;
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    }

    if ($action eq 'duplicateView' or $action eq 'deleteView' or $action eq 'editView' or $action eq 'insertView' or $action eq 'viewView' or $action eq 'listView') {
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
      print "  <input type=\"hidden\" name=\"catalogID\"     value=\"$CcatalogID\">\n";
      print "  <input type=\"hidden\" name=\"displayDaemon\" value=\"$CdisplayDaemon\">\n";
      print "  <input type=\"hidden\" name=\"uKey\"          value=\"$CuKey\">\n";
    } elsif ($action eq 'viewView') {
      print "  <input type=\"hidden\" name=\"catalogID\"     value=\"$CcatalogID\">\n";
    }

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;orderBy=$orderBy">[Insert view]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all views]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=viewView&amp;orderBy=$orderBy">[List selected views]</a></td>
  	  </tr></table>
	</td></tr>
HTML

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView' or $action eq 'viewView') {
      my $activatedChecked = ($Cactivated eq 'on') ? ' checked' : '';

      my $supportWindowSelect = '';
      ($rv, $supportWindowSelect, undef) = create_combobox_from_DBI ($rv, $dbh, "select timeperiodID, timeperiodName from $SERVERTABLTIMEPERIODS where catalogID = '$CcatalogID' and activated = 1 order by timeperiodName", 1, '', $CtimeperiodID, 'timeperiodID', 'none', '-Select-', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Catalog ID: </b></td><td>
          <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled>
        </td></tr>
        <tr><td><b>Display Daemon: </b></td><td>
          $displayDaemonSelect
        </td></tr>
        <tr><td><b>Application: </b></td><td>
          $uKeySelect
        </td></tr>
        <tr><td><b>Incident Monitoring Window: </b></td><td>
          $supportWindowSelect
        </td></tr>
HTML

      if ( $action ne "viewView" ) {
        print <<HTML;
        <tr><td><b>Display Group: </b></td><td>
          $displayGroupSelect
        </td></tr>
HTML
      }

      print <<HTML;
        <tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML
	
      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Unique Key: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingViews</td></tr>" if (defined $matchingViews and $matchingViews ne '');
    } else {
      print "    <tr><td><br><table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='#333344'><tr><td align=\"left\"><b>Catalog ID: </b></td><td>$catalogIDSelect</td></tr></table></td></tr>" if ($action ne 'view');
      print "    <tr><td align=\"center\"><br>$matchingViews</td></tr>";
    }

    print "  </table>\n";

    if ($action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView' or $action eq 'viewView' or $action eq 'listView') {
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

