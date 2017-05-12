#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, reports_perfdata.pl for ASNMTAP::Asnmtap::Applications::CGI
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
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :ADMIN :DBPERFPARSE :DBREADWRITE :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "reports_perfdata.pl";
my $prgtext     = "Reports Perfdata";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir                = (defined $cgi->param('pagedir'))               ? $cgi->param('pagedir')               : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset                = (defined $cgi->param('pageset'))               ? $cgi->param('pageset')               : 'admin';   $pageset =~ s/\+/ /g;
my $debug                  = (defined $cgi->param('debug'))                 ? $cgi->param('debug')                 : 'F';
my $pageNo                 = (defined $cgi->param('pageNo'))                ? $cgi->param('pageNo')                : 1;
my $pageOffset             = (defined $cgi->param('pageOffset'))            ? $cgi->param('pageOffset')            : 0;
my $orderBy                = (defined $cgi->param('orderBy'))               ? $cgi->param('orderBy')               : 'uKey';
my $action                 = (defined $cgi->param('action'))                ? $cgi->param('action')                : 'listView';
my $CuKeyReload            = (defined $cgi->param('uKeyReload'))            ? $cgi->param('uKeyReload')            : 0;
my $CcatalogID             = (defined $cgi->param('catalogID'))             ? $cgi->param('catalogID')             : $CATALOGID;
my $CcatalogIDreload       = (defined $cgi->param('catalogIDreload'))       ? $cgi->param('catalogIDreload')       : 0;
my $CuKey                  = (defined $cgi->param('uKey'))                  ? $cgi->param('uKey')                  : 'none';
my $Cmetric_id             = (defined $cgi->param('metric_id'))             ? $cgi->param('metric_id')             : 'none';
my $Ctimes                 = (defined $cgi->param('times'))                 ? $cgi->param('times')                 : '';
my $Cpercentiles           = (defined $cgi->param('percentiles'))           ? $cgi->param('percentiles')           : '';
my $Cunit                  = (defined $cgi->param('unit'))                  ? $cgi->param('unit')                  : 's';
my $Cactivated             = (defined $cgi->param('activated'))             ? $cgi->param('activated')             : 'off';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledNoMetricID, $formDisabledPrimaryKey, $submitButton, $uKeySelect, $metric_idSelect);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Reports Perfdata", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&uKeyReload=$CuKeyReload&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&uKey=$CuKey&metric_id=$Cmetric_id&times=$Ctimes&percentiles=$Cpercentiles&unit=$Cunit&activated=$Cactivated";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>page no       : $pageNo<br>page offset   : $pageOffset<br>order by      : $orderBy<br>action        : $action<br>uKey Reload   : $CuKeyReload<br>catalog ID    : $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br>uKey          : $CuKey<br>metric ID     : $Cmetric_id<br>times         : $Ctimes<br>percentiles   : $Cpercentiles<br>unit          : $Cunit<br>activated     : $Cactivated<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($catalogIDSelect, $matchingReportsPerfdata, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset&amp;catalogID=$CcatalogID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledNoMetricID = $formDisabledPrimaryKey = '';

    if ( $CuKeyReload ) {
      if ($action eq 'insert' or $action eq 'insertView') {
        $action = "insertView";
      } elsif ($action eq 'edit' or $action eq 'editView') {
        $action = "editView";
      } else {
        $action = "listView";
      }
    }

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert Report Perfdata";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
      $CcatalogID   = $CATALOGID if ($action eq 'insertView');
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Report Perfdata $CuKey, $Cmetric_id from $CcatalogID exist before to insert";

      $sql = "select catalogID, uKey, metric_id from $SERVERTABLREPORTSPRFDT WHERE catalogID='$CcatalogID' and uKey='$CuKey' and metric_id='$Cmetric_id'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle    = "Report Perfdata $CuKey, $Cmetric_id from $CcatalogID exist already";
        $nextAction   = "insertView";
      } else {
        $htmlTitle    = "Report Perfdata $CuKey, $Cmetric_id from $CcatalogID inserted";
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLREPORTSPRFDT. ' SET catalogID="' .$CcatalogID. '", uKey="' .$CuKey. '", metric_id="' .$Cmetric_id. '", times="' .$Ctimes. '", percentiles="' .$Cpercentiles. '", unit="' .$Cunit. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Delete Report Perfdata $CuKey, $Cmetric_id from $CcatalogID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $sql = 'DELETE FROM ' .$SERVERTABLREPORTSPRFDT. ' WHERE catalogID="' .$CcatalogID. '" and uKey="' .$CuKey. '" and metric_id="' .$Cmetric_id. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction = "listView" if ($rv);
      $htmlTitle = "Report Perfdata $CuKey, $Cmetric_id from $CcatalogID deleted";
    } elsif ($action eq 'displayView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Display Report Perfdata $CuKey, $Cmetric_id from $CcatalogID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Edit Report Perfdata $CuKey, $Cmetric_id from $CcatalogID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $htmlTitle    = "Report Perfdata $CuKey, $Cmetric_id from $CcatalogID updated";
      my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLREPORTSPRFDT. ' SET catalogID="' .$CcatalogID. '", uKey="' .$CuKey. '", metric_id="' .$Cmetric_id. '", times="' .$Ctimes. '", percentiles="' .$Cpercentiles. '", unit="' .$Cunit. '", activated="' .$dummyActivated. '" WHERE catalogID="' .$CcatalogID. '" and uKey="' .$CuKey. '" and metric_id="' .$Cmetric_id. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'listView') {
      $htmlTitle    = "All reports perfdata listed";

      if ( $CcatalogIDreload ) {
        $pageNo = 1;
        $pageOffset = 0;
      }

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select SQL_NO_CACHE count(uKey) from $SERVERTABLREPORTSPRFDT where catalogID = '$CcatalogID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID&amp;orderBy=$orderBy");

      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLREPORTSPRFDT, 'uKey', "catalogID = '$CcatalogID'", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select $DATABASE.$SERVERTABLREPORTSPRFDT.catalogID, $DATABASE.$SERVERTABLREPORTSPRFDT.uKey, $DATABASE.$SERVERTABLREPORTSPRFDT.metric_id, concat( LTRIM(SUBSTRING_INDEX($DATABASE.$SERVERTABLPLUGINS.title, ']', -1)), ' (', $DATABASE.$SERVERTABLENVIRONMENT.label, ')' ), $PERFPARSEDATABASE.perfdata_service_metric.metric, $DATABASE.$SERVERTABLREPORTSPRFDT.times, $DATABASE.$SERVERTABLREPORTSPRFDT.percentiles, $DATABASE.$SERVERTABLREPORTSPRFDT.unit, $DATABASE.$SERVERTABLREPORTSPRFDT.activated from $DATABASE.$SERVERTABLREPORTSPRFDT, $DATABASE.$SERVERTABLPLUGINS, $DATABASE.$SERVERTABLENVIRONMENT, $PERFPARSEDATABASE.perfdata_service_metric where $DATABASE.$SERVERTABLREPORTSPRFDT.catalogID = '$CcatalogID' and $DATABASE.$SERVERTABLREPORTSPRFDT.catalogID = $DATABASE.$SERVERTABLPLUGINS.catalogID and $DATABASE.$SERVERTABLREPORTSPRFDT.uKey = $DATABASE.$SERVERTABLPLUGINS.uKey and $DATABASE.$SERVERTABLREPORTSPRFDT.metric_id = $PERFPARSEDATABASE.perfdata_service_metric.metric_id and $DATABASE.$SERVERTABLPLUGINS.environment = $DATABASE.$SERVERTABLENVIRONMENT.environment order by $orderBy limit $pageOffset, $RECORDSONPAGE";

      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalog desc, title desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalog asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalog desc, uKey desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Unique Key <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalog asc, uKey asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title desc, catalog asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Plugin Title <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title asc, catalog asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      $header .= "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=metric_id desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Metric <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=metric_id asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=times desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Times <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=times asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=percentiles desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Percentiles <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=percentiles asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=unit desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Unit <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=unit asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingReportsPerfdata, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Report Perfdata', 'catalogID|uKey|metric_id', '0|1|2', '2', '', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if (!$CuKeyReload and ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView')) {
      $sql = "select catalogID, uKey, metric_id, times, percentiles, unit, activated from $SERVERTABLREPORTSPRFDT WHERE catalogID='$CcatalogID' and uKey='$CuKey' and metric_id='$Cmetric_id'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcatalogID, $CuKey, $Cmetric_id, $Ctimes, $Cpercentiles, $Cunit, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $CcatalogID = $CATALOGID if ($action eq 'duplicateView');
        $Cactivated = ($Cactivated == 1) ? 'on' : 'off';
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }
    }

    if ($action eq 'insertView' or $action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'displayView' or $action eq 'editView') {
      if ($CuKey eq 'none' or $action eq 'insertView' or $action eq 'duplicateView' or $action eq 'editView') {
        $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where $SERVERTABLPLUGINS.catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by optionValueTitle";
      } else {
        $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where uKey = '$CuKey' and $SERVERTABLPLUGINS.catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment";
      }

      ($rv, $uKeySelect, $htmlTitle) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, $nextAction, $CuKey, 'uKey', 'none', '-Select-', $formDisabledPrimaryKey, 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      if ( $CuKey ne 'none' ) {
        my $sqlWherePERFDATA;
        my $catalogID_uKey = ( ( $CcatalogID eq 'CID' ) ? '' : $CcatalogID .'_' ) . $CuKey;

        if ( $PERFPARSEVERSION eq '20' ) {
          $sqlWherePERFDATA = "where service_id in (select service_id from $PERFPARSEDATABASE.perfdata_service where service_description = '$catalogID_uKey')";
        } else {
          $sqlWherePERFDATA = "where service_description = '$catalogID_uKey'";
        }

        if ( $rv ) {
          $sql = "select metric_id, metric from $PERFPARSEDATABASE.perfdata_service_metric $sqlWherePERFDATA and metric not regexp '^(Compilation|Execution|Duration)\$' and unit regexp '^(s|ms)\$' order by metric";
          ($rv, $metric_idSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, $nextAction, $Cmetric_id, 'metric_id', 'none', '-Select-', $formDisabledPrimaryKey, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
        }

        $formDisabledNoMetricID = '';
      } else {
        $metric_idSelect = "Application missing";
        $formDisabledNoMetricID = 'disabled';
      }
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, "", 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  if ( document.reports_perfdata.uKey.value == null || document.reports_perfdata.uKey.value == 'none' ) {
    document.reports_perfdata.uKey.focus();
    alert('Please create/select a Application!');
    return false;
  }

  document.reports_perfdata.uKeyReload.value = 1;
  document.reports_perfdata.submit();
  return true;
}

function validateForm() {
HTML

      if ($action eq 'duplicateView' or $action eq 'insertView') {
        print <<HTML;
  if ( document.reports_perfdata.uKey.options[document.reports_perfdata.uKey.selectedIndex].value == 'none' ) {
    document.reports_perfdata.uKey.focus();
    alert('Please create/select one of the applications!');
    return false;
  }

  if ( document.reports_perfdata.metric_id.options[document.reports_perfdata.metric_id.selectedIndex].value == 'none' ) {
    document.reports_perfdata.metric_id.focus();
    alert('Please create/select one of the metrics!');
    return false;
  }

HTML
      }

      print <<HTML;
  // times n[,n] and n >= 0
  var objectRegularExpressionTimesValue = /\^([0-9]+)(,([0-9]+))*\$/;

  if ( ! ( document.reports_perfdata.times.value == null || document.reports_perfdata.times.value == '' ) ) {
    if ( ! objectRegularExpressionTimesValue.test(document.reports_perfdata.times.value) ) {
      document.reports_perfdata.times.focus();
      alert('Please re-enter times: Bad times format!');
      return false;
    }
  }

  // percentiles n[,n] and 0 < n < 100
  var objectRegularExpressionPercentilesValue = /\^([1-9]|[1-9][0-9])(,([1-9]|[1-9][0-9]))*\$/;

  if ( ! ( document.reports_perfdata.percentiles.value == null || document.reports_perfdata.percentiles.value == '' ) ) {
    if ( ! objectRegularExpressionPercentilesValue.test(document.reports_perfdata.percentiles.value) ) {
      document.reports_perfdata.percentiles.focus();
      alert('Please re-enter percentiles: Bad percentile format!');
      return false;
    }
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="reports_perfdata" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'listView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, "", 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.reports_perfdata.catalogIDreload.value = 1;
  document.reports_perfdata.submit();
  return true;
}

</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="reports_perfdata">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"reports\">\n";
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
  <input type="hidden" name="uKeyReload"      value="0">
  <input type="hidden" name="catalogIDreload" value="0">
HTML
    } else {
      print "<br>\n";
    }

	if ($formDisabledPrimaryKey ne '' and $action ne 'displayView' and $action ne "listView") {
      print "  <input type=\"hidden\" name=\"catalogID\"       value=\"$CcatalogID\">\n";
      print "  <input type=\"hidden\" name=\"uKey\"            value=\"$CuKey\">\n";
      print "  <input type=\"hidden\" name=\"metric_id\"       value=\"$Cmetric_id\">\n";
    }

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;orderBy=$orderBy">[Insert report perfdata]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all reports perfdata]</a></td>
	  </tr></table>
	</td></tr>
HTML

    unless ( $PERFPARSEENABLED ) {
      print "    <tr><td align=\"center\"><br>'Performance Data' not enabled</td></tr>";
    } elsif ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      my $unitSelect = create_combobox_from_keys_and_values_pairs ('s=>s|ms=>ms', 'K', 0, $Cunit, 'unit', '', '', $formDisabledAll, '', $debug);
      my $activatedChecked = ($Cactivated eq 'on') ? ' checked' : '';

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Catalog ID: </b></td><td>
          <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled>
        </td></tr>
		<tr><td><b>Application: </b></td><td>
          $uKeySelect
        </td></tr>
        <tr><td><b>Metric: </b></td><td>
          $metric_idSelect
        </td></tr>
        <tr><td><b>Times: </b></td><td>
          <input type="text" name="times" value="$Ctimes" size="64" maxlength="64" $formDisabledAll>&nbsp;&nbsp;format: n[,n]&nbsp;&nbsp;value: >= 0
        </td></tr>
        <tr><td><b>Percentiles: </b></td><td>
          <input type="text" name="percentiles" value="$Cpercentiles" size="64" maxlength="64" $formDisabledAll>&nbsp;&nbsp;format: n[,n]&nbsp;&nbsp; 0 < value < 100
        </td></tr>
        <tr><td><b>Unit: </b></td><td>
          $unitSelect
        </td></tr>
		<tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Report Perfdata: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingReportsPerfdata</td></tr>" if (defined $matchingReportsPerfdata and $matchingReportsPerfdata ne '');
    } else {
      print "    <tr><td><br><table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='#333344'><tr><td align=\"left\"><b>Catalog ID: </b></td><td>$catalogIDSelect</td></tr></table></td></tr>";
      print "    <tr><td align=\"center\"><br>$matchingReportsPerfdata</td></tr>";
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
