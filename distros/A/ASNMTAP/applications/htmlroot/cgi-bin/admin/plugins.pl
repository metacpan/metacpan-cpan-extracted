#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, plugins.pl for ASNMTAP::Asnmtap::Applications::CGI
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

$PROGNAME       = "plugins.pl";
my $prgtext     = "Plugins";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))            ? $cgi->param('pagedir')            : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))            ? $cgi->param('pageset')            : 'admin';   $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))              ? $cgi->param('debug')              : 'F';
my $pageNo              = (defined $cgi->param('pageNo'))             ? $cgi->param('pageNo')             : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))         ? $cgi->param('pageOffset')         : 0;
my $filter              = (defined $cgi->param('filter'))             ? $cgi->param('filter')             : '';
my $orderBy             = (defined $cgi->param('orderBy'))            ? $cgi->param('orderBy')            : 'title';
my $action              = (defined $cgi->param('action'))             ? $cgi->param('action')             : 'listView';
my $CcatalogID          = (defined $cgi->param('catalogID'))          ? $cgi->param('catalogID')          : $CATALOGID;
my $CcatalogIDreload    = (defined $cgi->param('catalogIDreload'))    ? $cgi->param('catalogIDreload')    : 0;
my $CuKey               = (defined $cgi->param('uKey'))               ? $cgi->param('uKey')               : '';
my $Ctest               = (defined $cgi->param('test'))               ? $cgi->param('test')               : '';
my $CshortDescription   = (defined $cgi->param('shortDescription'))   ? $cgi->param('shortDescription')   : '';
my $Cenvironment        = (defined $cgi->param('environment'))        ? $cgi->param('environment')        : 'L';
my $Carguments          = (defined $cgi->param('arguments'))          ? $cgi->param('arguments')          : '';
my $CargumentsOndemand  = (defined $cgi->param('argumentsOndemand'))  ? $cgi->param('argumentsOndemand')  : '';
my $Ctitle              = (defined $cgi->param('title'))              ? $cgi->param('title')              : '';
my $Ctrendline          = (defined $cgi->param('trendline'))          ? $cgi->param('trendline')          : 0;
my $Cpercentage         = (defined $cgi->param('percentage'))         ? $cgi->param('percentage')         : 25;
my $Ctolerance          = (defined $cgi->param('tolerance'))          ? $cgi->param('tolerance')          : 5;
my $Cstep               = (defined $cgi->param('step'))               ? $cgi->param('step')               : 0;
my $Condemand           = (defined $cgi->param('ondemand'))           ? $cgi->param('ondemand')           : 'off';
my $Cproduction         = (defined $cgi->param('production'))         ? $cgi->param('production')         : 'off';
my @Cpagedir            =          $cgi->param('pagedirs');
my $Cresultsdir         = (defined $cgi->param('resultsdir'))         ? $cgi->param('resultsdir')         : 'none';
my $ChelpPluginTextname = (defined $cgi->param('helpPluginTextname')) ? $cgi->param('helpPluginTextname') : '<NIHIL>';
my $ChelpPluginFilename = (defined $cgi->param('helpPluginFilename')) ? $cgi->param('helpPluginFilename') : '<NIHIL>';
my $CholidayBundleID    = (defined $cgi->param('holidayBundleID'))    ? $cgi->param('holidayBundleID')    : 1;
my $Cactivated          = (defined $cgi->param('activated'))          ? $cgi->param('activated')          : 'off';

my $Cpagedir = (@Cpagedir) ? '/'. join ('/', @Cpagedir) .'/' : '';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledUniqueKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Plugins", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&filter=$filter&orderBy=$orderBy&action=$action&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&uKey=$CuKey&test=$Ctest&environment=$Cenvironment&arguments=$Carguments&argumentsOndemand=$CargumentsOndemand&title=$Ctitle&shortDescription=$CshortDescription&trendline=$Ctrendline&percentage=$Cpercentage&tolerance=$Ctolerance&step=$Cstep&ondemand=$Condemand&production=$Cproduction&pagedirs=$Cpagedir&resultsdir=$Cresultsdir&helpPluginTextname=$ChelpPluginTextname&helpPluginFilename=$ChelpPluginFilename&holidayBundleID=$CholidayBundleID&activated=$Cactivated";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>page no           : $pageNo<br>page offset       : $pageOffset<br>filter            : $filter<br>order by          : $orderBy<br>action            : $action<br>catalog ID        : $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br>uKey              : $CuKey<br>test              : $Ctest<br>environment       : $Cenvironment<br>arguments         : $Carguments<br>arguments ondemand: $CargumentsOndemand<br>title             : $Ctitle<br>shortDescription  : $CshortDescription<br>trendline         : $Ctrendline<br>percentage        : $Cpercentage<br>tolerance         : $Ctolerance<br>step              : $Cstep<br>on demand         : $Condemand<br>production        : $Cproduction<br>pagedirs          : $Cpagedir<br>resultsdir        : $Cresultsdir<br>helpPluginTextname: $ChelpPluginTextname<br>helpPluginFilename: $ChelpPluginFilename<br>holiday Bundle ID : $CholidayBundleID<br>activated         : $Cactivated<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  if ( $ChelpPluginFilename eq '' or $ChelpPluginFilename eq '<NIHIL>' ) {
    $ChelpPluginFilename = ( $ChelpPluginTextname eq '' ? '<NIHIL>' : $ChelpPluginTextname );
    $ChelpPluginTextname = '';
  } else {
    if ( $cgi->param('helpPluginFilename') eq '' ) {
      $ChelpPluginFilename = $ChelpPluginTextname;
      $ChelpPluginTextname = '';
    } else {
      $ChelpPluginFilename =~ s/^.*(?:\/|\\)//;
      $ChelpPluginTextname = '<br><br>Help Plugin Filename: '. $ChelpPluginFilename;

      my $type = $cgi->uploadInfo( $cgi->param('helpPluginFilename') )->{'Content-Type'};

      if ( $type eq 'application/pdf') {
        my $fhOpen = open( FHOPEN, ">$PDPHELPPATH/$ChelpPluginFilename" );

        if ($fhOpen) {
          binmode FHOPEN;

          my $fh = $cgi->upload('helpPluginFilename');

          if ( defined $fh ) {
            while (<$fh>) { print FHOPEN; }
            $ChelpPluginTextname .= ', Uploaded and wrote file OK!';
          } else {
            $ChelpPluginTextname .= ', Cannot upload PDF file!';
          }

          close FHOPEN;
        } else {
          $ChelpPluginFilename = '<NIHIL>';
          $ChelpPluginTextname .= ', Cannot create PDF file!';
        }
      } else {
        $ChelpPluginFilename = '<NIHIL>';
        $ChelpPluginTextname .= ', PDF files only!';
      }
    }
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my ($catalogIDSelect, $environmentSelect, $holidayBundleSelect, $pagedirsSelect, $resultsdirSelect, $matchingPlugins, $navigationBar, $matchingViewsCrontabs, $generatePluginCrontabSchedulingReport);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset&amp;filter=$filter&amp;catalogID=$CcatalogID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledUniqueKey = '';

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert Plugin";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
      $CcatalogID   = $CATALOGID if ($action eq 'insertView');
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Plugin $CuKey from $CcatalogID exist before to insert";

      $sql = "select title from $SERVERTABLPLUGINS WHERE catalogID='$CcatalogID' and uKey='$CuKey'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

   if ( $numberRecordsIntoQuery ) {
        $htmlTitle  = "Plugin $CuKey from $CcatalogID exist already";
        $nextAction = "insertView";
      } else {
        $htmlTitle  = "Plugin $CuKey inserted from $CcatalogID";
        my $dummyOndemand   = ($Condemand eq 'on') ? 1 : 0;
        my $dummyProduction = ($Cproduction eq 'on') ? 1 : 0;
        my $dummyActivated  = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLPLUGINS. ' SET catalogID="' .$CcatalogID. '", uKey="' .$CuKey. '", test="' .$Ctest. '", environment="' .$Cenvironment. '", arguments="' .$Carguments. '", argumentsOndemand="' .$CargumentsOndemand. '", title="' .$Ctitle. '", shortDescription="' .$CshortDescription. '", trendline="' .$Ctrendline. '", percentage="' .$Cpercentage. '", tolerance="' .$Ctolerance. '", step="' .$Cstep. '", ondemand="' .$dummyOndemand. '", production="' .$dummyProduction. '", pagedir="' .$Cpagedir. '", resultsdir="' .$Cresultsdir. '", helpPluginFilename="' .$ChelpPluginFilename. '", holidayBundleID="' .$CholidayBundleID. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledUniqueKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Delete plugin $CuKey from $CcatalogID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $sql = "select uKey, title from $SERVERTABLCOMMENTS where catalogID = '$CcatalogID' and uKey = '$CuKey' order by title, uKey";
      ($rv, $matchingPlugins) = check_record_exist ($rv, $dbh, $sql, 'Comments from ' .$CcatalogID, 'Unique Key', 'Title', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select lineNumber, uKey from $SERVERTABLCRONTABS where catalogID = '$CcatalogID' and uKey = '$CuKey' order by uKey, lineNumber";
      ($rv, $matchingPlugins) = check_record_exist ($rv, $dbh, $sql, 'Crontabs from ' .$CcatalogID, 'Unique Key', 'Linenumber', $matchingPlugins, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select uKey, displayDaemon from $SERVERTABLVIEWS where catalogID = '$CcatalogID' and uKey = '$CuKey' order by displayDaemon, uKey";
      ($rv, $matchingPlugins) = check_record_exist ($rv, $dbh, $sql, 'Views from ' .$CcatalogID, 'Unique Key', 'Display Daemon', $matchingPlugins, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select $SERVERTABLREPORTS.uKey, concat( LTRIM(SUBSTRING_INDEX($SERVERTABLPLUGINS.title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as title from $SERVERTABLREPORTS, $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where $SERVERTABLREPORTS.catalogID = '$CcatalogID' and $SERVERTABLREPORTS.uKey = '$CuKey' and $SERVERTABLREPORTS.catalogID = $SERVERTABLPLUGINS.catalogID and $SERVERTABLREPORTS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by title, uKey";
      ($rv, $matchingPlugins) = check_record_exist ($rv, $dbh, $sql, 'Reports from ' .$CcatalogID, 'Unique Key', 'Title', $matchingPlugins, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

   if ($matchingPlugins eq '') {
        $htmlTitle = "Plugin $CuKey from $CcatalogID deleted";
        $sql = 'DELETE FROM ' .$SERVERTABLPLUGINS. ' WHERE catalogID="' .$CcatalogID. '" and uKey="' .$CuKey. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      } else {
        $htmlTitle = "Plugin $CuKey from $CcatalogID not deleted, still used by";
      }

      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'displayView') {
      $formDisabledUniqueKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Display plugin $CuKey from $CcatalogID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledUniqueKey = 'disabled';
      $htmlTitle    = "Edit plugin $CuKey from $CcatalogID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $htmlTitle    = "Plugin $CuKey updated from $CcatalogID";
      my $dummyOndemand   = ($Condemand eq 'on') ? 1 : 0;
      my $dummyProduction = ($Cproduction eq 'on') ? 1 : 0;
      my $dummyActivated  = ($Cactivated eq 'on') ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLPLUGINS. ' SET catalogID="' .$CcatalogID. '", uKey="' .$CuKey. '", test="' .$Ctest. '", environment="' .$Cenvironment. '", arguments="' .$Carguments. '", argumentsOndemand="' .$CargumentsOndemand. '", title="' .$Ctitle. '", shortDescription="' .$CshortDescription. '", trendline="' .$Ctrendline. '", percentage="' .$Cpercentage. '", tolerance="' .$Ctolerance. '", step="' .$Cstep. '", ondemand="' .$dummyOndemand. '", production="' .$dummyProduction. '", pagedir="' .$Cpagedir. '", resultsdir="' .$Cresultsdir. '", helpPluginFilename="' .$ChelpPluginFilename. '", holidayBundleID="' .$CholidayBundleID. '", activated="' .$dummyActivated. '" WHERE catalogID="' .$CcatalogID. '" and uKey="' .$CuKey. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'listView') {
      my $doFilter  = ( ( defined $filter and $filter ne '' ) ? 1 : 0 );
      $htmlTitle    = ( $doFilter ) ? "All plugins matching filter: $filter" : "All plugins listed";

      if ( $CcatalogIDreload ) {
        $pageNo = 1;
        $pageOffset = 0;
      }

      my $andFilter = ( ( $doFilter ) ? "AND title regexp '$filter'" : '' );

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select SQL_NO_CACHE count(uKey) from $SERVERTABLPLUGINS where catalogID = '$CcatalogID' $andFilter";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID&amp;filter=$filter&amp;orderBy=$orderBy");

      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLPLUGINS, 'title', "catalogID = '$CcatalogID' $andFilter", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID&amp;filter=$filter", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select catalogID, uKey, title, environment, ondemand, production, pagedir, resultsdir, activated from $SERVERTABLPLUGINS where catalogID = '$CcatalogID' $andFilter order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header  = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID desc, uKey asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID asc, uKey asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=uKey desc, catalogID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Unique Key <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=uKey asc, catalogID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Title <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=environment desc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Environment <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=environment asc, title asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=ondemand desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> On Demand <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=ondemand asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      $header .= "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=production desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Production <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=production asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=pagedir desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Views <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=pagedir asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=resultsdir desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Results <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=resultsdir asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, uKey desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=uKey asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>\n";
      ($rv, $matchingPlugins, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Plugin', 'catalogID|uKey', '0|1', '', '', "&amp;catalogID=$CcatalogID&amp;filter=$filter", $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select catalogID, uKey, test, environment, arguments, argumentsOndemand, title, shortDescription, trendline, percentage, tolerance, step, ondemand, production, pagedir, resultsdir, helpPluginFilename, holidayBundleID, activated from $SERVERTABLPLUGINS where catalogID = '$CcatalogID' and uKey = '$CuKey'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcatalogID, $CuKey, $Ctest, $Cenvironment, $Carguments, $CargumentsOndemand, $Ctitle, $CshortDescription, $Ctrendline, $Cpercentage, $Ctolerance, $Cstep, $Condemand, $Cproduction, $Cpagedir, $Cresultsdir, $ChelpPluginFilename, $CholidayBundleID, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $CcatalogID  = $CATALOGID if ($action eq 'duplicateView');
        $Condemand   = ($Condemand == 1) ? 'on' : 'off';
        $Cproduction = ($Cproduction == 1) ? 'on' : 'off';
        $Cactivated  = ($Cactivated == 1) ? 'on' : 'off';
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      $environmentSelect = create_combobox_from_keys_and_values_pairs ('P=>Production|A=>Acceptation|S=>Simulation|T=>Test|D=>Development|L=>Local', 'V', 0, $Cenvironment, 'environment', '', '', $formDisabledAll, '', $debug);

      $sql = "select pagedir, groupName from $SERVERTABLPAGEDIRS where catalogID = '$CcatalogID' order by groupName";
      ($rv, $pagedirsSelect) = create_combobox_multiple_from_DBI ($rv, $dbh, $sql, $action, $Cpagedir, 'pagedirs', 'Pagedirs missing.', 5, 100, $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select resultsdir, groupName from $SERVERTABLRESULTSDIR where catalogID = '$CcatalogID' order by groupName";
      ($rv, $resultsdirSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $Cresultsdir, 'resultsdir', 'none', '-Select-', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select holidayBundleID, holidayBundleName from $SERVERTABLHOLIDYSBNDL where catalogID = '$CcatalogID' and activated = '1' order by holidayBundleName";
      ($rv, $holidayBundleSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CholidayBundleID, 'holidayBundleID', '1', '+ No Holiday Bundle', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'editView') {
      $matchingViewsCrontabs .= "<table border=0 cellpadding=1 cellspacing=1 bgcolor=\"$COLORSTABLE{TABLE}\">";
      my ($VdisplayDaemon, $Vactivated, $DGgroupTitle, $DGactivated, $DDdisplayDaemon, $DDgroupName, $DDactivated, $ScatalogID, $SserverID, $SserverTitle, $StypeServers, $StypeMonitoring, $StypeActiveServer, $SmasterFQDN, $SslaveFQDN, $Sactivated, $CTlinenumber, $CTcollectorDaemon, $CTarguments, $CTminute, $CThour, $CTdayOfTheMonth, $CTmonthOfTheYear, $CTdayOfTheWeek, $CTnoOffline, $CTactivated, $CDcollectorDaemon, $CDgroupName, $CDactivated);
      my ($prevSserverID, $prevDDdisplayDaemon, $prevCDcollectorDaemon, $urlWithAccessParametersAction, $actionItem, $notActivated);

      $matchingViewsCrontabs .= "<tr><th colspan=\"3\">Servers, Display Daemons, Views &amp; Display Groups:</th></tr>\n";
      $sql = "select $SERVERTABLVIEWS.displayDaemon, $SERVERTABLVIEWS.activated, $SERVERTABLDISPLAYGRPS.groupTitle, $SERVERTABLDISPLAYGRPS.activated, $SERVERTABLDISPLAYDMNS.displayDaemon, $SERVERTABLDISPLAYDMNS.groupName, $SERVERTABLDISPLAYDMNS.activated, $SERVERTABLSERVERS.catalogID, $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.serverTitle, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeActiveServer, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLSERVERS.activated from $SERVERTABLPLUGINS, $SERVERTABLVIEWS, $SERVERTABLDISPLAYDMNS, $SERVERTABLDISPLAYGRPS, $SERVERTABLSERVERS where $SERVERTABLPLUGINS.catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.uKey = '$CuKey' and $SERVERTABLPLUGINS.catalogID = $SERVERTABLVIEWS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLVIEWS.uKey and $SERVERTABLVIEWS.catalogID = $SERVERTABLDISPLAYDMNS.catalogID and $SERVERTABLVIEWS.displayDaemon = $SERVERTABLDISPLAYDMNS.displayDaemon and $SERVERTABLVIEWS.catalogID = $SERVERTABLDISPLAYGRPS.catalogID and $SERVERTABLVIEWS.displayGroupID = $SERVERTABLDISPLAYGRPS.displayGroupID and $SERVERTABLDISPLAYDMNS.catalogID = $SERVERTABLSERVERS.catalogID and $SERVERTABLDISPLAYDMNS.serverID = $SERVERTABLSERVERS.serverID order by $SERVERTABLSERVERS.serverID, $SERVERTABLDISPLAYDMNS.displayDaemon, $SERVERTABLVIEWS.displayDaemon, $SERVERTABLDISPLAYGRPS.groupTitle";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$VdisplayDaemon, \$Vactivated, \$DGgroupTitle, \$DGactivated, \$DDdisplayDaemon, \$DDgroupName, \$DDactivated, \$ScatalogID, \$SserverID, \$SserverTitle, \$StypeServers, \$StypeMonitoring, \$StypeActiveServer, \$SmasterFQDN, \$SslaveFQDN, \$Sactivated ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        $prevSserverID = $prevDDdisplayDaemon = '';

        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            my $actionSkip = ( ( $ScatalogID eq $CATALOGID ) ? 0 : 1 );

            if ($prevSserverID eq '' or $prevSserverID ne $SserverID) {
              $urlWithAccessParametersAction = "../sadmin/servers.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;catalogID=$ScatalogID&amp;serverID=$SserverID&amp;orderBy=serverID asc&amp;action";
              $actionItem = "&nbsp;";
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display Server\" alt=\"Display Server\" border=\"0\"></a>&nbsp;" if ($iconDetails);
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Server\" alt=\"Edit Server\" border=\"0\"></a>&nbsp;" if ($iconEdit and ! $actionSkip);
              $notActivated = ($Sactivated) ? '' : ' not';
              $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td colspan=\"2\"><b>Server: $SserverTitle ($SserverID) -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
              my $typeMonitoringText = ($StypeMonitoring) ? 'Distributed' : 'Central';
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">type monitoring</td><td>$typeMonitoringText</td><td>&nbsp;</td></tr>\n";
              my $typeServersText = ($StypeServers) ? 'Failover' : 'Standalone';
              my $typeActiveServerText = ($StypeActiveServer eq 'S') ? 'Slave' : 'Master';
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">type servers</td><td>$typeServersText</td><td>&nbsp;</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">type active server</td><td>$typeActiveServerText</td><td>&nbsp;</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">master FQDN</td><td>$SmasterFQDN</td><td>&nbsp;</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">slave FQDN</td><td>$SslaveFQDN</td><td>&nbsp;</td></tr>\n";
            }

            if ($prevDDdisplayDaemon eq '' or $prevDDdisplayDaemon ne $DDdisplayDaemon) {
              $urlWithAccessParametersAction = "../sadmin/displayDaemons.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;catalogID=$ScatalogID&amp;displayDaemon=$DDdisplayDaemon&amp;orderBy=displayDaemon asc&amp;action";
              $actionItem = "&nbsp;";
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display Display Daemon\" alt=\"Display Display Daemon\" border=\"0\"></a>&nbsp;" if ($iconDetails);
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Display Daemon\" alt=\"Edit Display Daemon\" border=\"0\"></a>&nbsp;" if ($iconEdit and ! $actionSkip);
              $notActivated = ($DDactivated) ? '' : ' not';
              $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td colspan=\"2\"><b>Display daemon: DisplayCT-$DDdisplayDaemon -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Group name</td><td>$DDgroupName</td><td>&nbsp;</td></tr>\n";
            }

            $urlWithAccessParametersAction = "views.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;catalogID=$ScatalogID&amp;displayDaemon=$VdisplayDaemon;uKey=$CuKey&amp;orderBy=groupName asc, groupTitle asc, title asc&amp;action";
            $actionItem = "&nbsp;";
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display View\" alt=\"Display View\" border=\"0\"></a>&nbsp;" if ($iconDetails);
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit View\" alt=\"Edit View\" border=\"0\"></a>&nbsp;" if ($iconEdit and ! $actionSkip);
            $notActivated = ($Vactivated) ? '' : ' not';
            $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td colspan=\"2\"><b>View: $HTTPSURL/nav/$VdisplayDaemon -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
            $notActivated = ($DGactivated) ? '' : ' not';
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Display group title</td><td>$DGgroupTitle -<b>$notActivated activated</b></td><td>&nbsp;</td></tr>\n";

            $prevSserverID       = $SserverID;
            $prevDDdisplayDaemon = $DDdisplayDaemon;
          }
        } else {
          $matchingViewsCrontabs .= "<tr><td>No records found</td></tr>\n";
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingViewsCrontabs .= "<tr bgcolor=\"#000000\"><td colspan=\"3\">&nbsp;</td></tr><tr><th colspan=\"3\">Servers, Collector Daemons &amp; Crontabs:</th></tr>\n";
      $sql = "select $SERVERTABLCRONTABS.linenumber, $SERVERTABLCRONTABS.collectorDaemon, $SERVERTABLCRONTABS.arguments, $SERVERTABLCRONTABS.minute, $SERVERTABLCRONTABS.hour, $SERVERTABLCRONTABS.dayOfTheMonth, $SERVERTABLCRONTABS.monthOfTheYear, $SERVERTABLCRONTABS.dayOfTheWeek, $SERVERTABLCRONTABS.noOffline, $SERVERTABLCRONTABS.activated, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLCLLCTRDMNS.groupName, $SERVERTABLCLLCTRDMNS.activated, $SERVERTABLSERVERS.catalogID, $SERVERTABLSERVERS.serverID, $SERVERTABLSERVERS.serverTitle, $SERVERTABLSERVERS.typeServers, $SERVERTABLSERVERS.typeMonitoring, $SERVERTABLSERVERS.typeActiveServer, $SERVERTABLSERVERS.masterFQDN, $SERVERTABLSERVERS.slaveFQDN, $SERVERTABLSERVERS.activated from $SERVERTABLPLUGINS, $SERVERTABLCRONTABS, $SERVERTABLCLLCTRDMNS, $SERVERTABLSERVERS where $SERVERTABLPLUGINS.catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.uKey = '$CuKey' and $SERVERTABLPLUGINS.catalogID = $SERVERTABLCRONTABS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLCRONTABS.uKey and $SERVERTABLCRONTABS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLCRONTABS.collectorDaemon = $SERVERTABLCLLCTRDMNS.collectorDaemon and $SERVERTABLCLLCTRDMNS.catalogID = $SERVERTABLSERVERS.catalogID and $SERVERTABLCLLCTRDMNS.serverID = $SERVERTABLSERVERS.serverID order by $SERVERTABLSERVERS.serverID, $SERVERTABLCLLCTRDMNS.collectorDaemon, $SERVERTABLCRONTABS.collectorDaemon, $SERVERTABLCRONTABS.linenumber";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$CTlinenumber, \$CTcollectorDaemon, \$CTarguments, \$CTminute, \$CThour, \$CTdayOfTheMonth, \$CTmonthOfTheYear, \$CTdayOfTheWeek, \$CTnoOffline, \$CTactivated, \$CDcollectorDaemon, \$CDgroupName, \$CDactivated, \$ScatalogID, \$SserverID, \$SserverTitle, \$StypeServers, \$StypeMonitoring, \$StypeActiveServer, \$SmasterFQDN, \$SslaveFQDN, \$Sactivated ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        $prevSserverID = $prevCDcollectorDaemon = '';

        if ( $sth->rows ) {
          while( $sth->fetch() ) {
            my $actionSkip = ( ( $ScatalogID eq $CATALOGID ) ? 0 : 1 );

            if ($prevSserverID eq '' or $prevSserverID ne $SserverID) {
              $urlWithAccessParametersAction = "../sadmin/servers.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;catalogID=$ScatalogID&amp;serverID=$SserverID&amp;orderBy=serverID asc&amp;action";
              $actionItem = "&nbsp;";
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display Server\" alt=\"Display Server\" border=\"0\"></a>&nbsp;" if ($iconDetails);
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Server\" alt=\"Edit Server\" border=\"0\"></a>&nbsp;" if ($iconEdit and ! $actionSkip);
              $notActivated = ($Sactivated) ? '' : ' not';
              $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{ENDBLOCK}\"><td colspan=\"2\"><b>Server: $SserverTitle ($SserverID) -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
              my $typeMonitoringText = ($StypeMonitoring) ? 'Distributed' : 'Central';
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">type monitoring</td><td>$typeMonitoringText</td><td>&nbsp;</td></tr>\n";
              my $typeServersText = ($StypeServers) ? 'Failover' : 'Standalone';
              my $typeActiveServerText = ($StypeActiveServer eq 'S') ? 'Slave' : 'Master';
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">type servers</td><td>$typeServersText</td><td>&nbsp;</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">type active server</td><td>$typeActiveServerText</td><td>&nbsp;</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">master FQDN</td><td>$SmasterFQDN</td><td>&nbsp;</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">slave FQDN</td><td>$SslaveFQDN</td><td>&nbsp;</td></tr>\n";
            }

            if ($prevCDcollectorDaemon eq '' or $prevCDcollectorDaemon ne $CDcollectorDaemon) {
              $urlWithAccessParametersAction = "../sadmin/collectorDaemons.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;catalogID=$ScatalogID&amp;collectorDaemon=$CDcollectorDaemon&amp;orderBy=collectorDaemon asc&amp;action";
              $actionItem = "&nbsp;";
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display Collector Daemon\" alt=\"Display Collector Daemon\" border=\"0\"></a>&nbsp;" if ($iconDetails);
              $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Collector Daemon\" alt=\"Edit Collector Daemon\" border=\"0\"></a>&nbsp;" if ($iconEdit and ! $actionSkip);
              $notActivated = ($CDactivated) ? '' : ' not';
              $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td colspan=\"2\"><b>Collector daemon: CollectorCT-$CDcollectorDaemon -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
              $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Group name</td><td>$CDgroupName</td><td>&nbsp;</td></tr>\n";
            }

            $urlWithAccessParametersAction = "crontabs.pl?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=1&amp;pageOffset=0&amp;catalogID=$ScatalogID&amp;lineNumber=$CTlinenumber&amp;uKey=$CuKey&amp;orderBy=lineNumber asc, uKey asc, groupName asc, title asc&amp;action";
            $actionItem = "&nbsp;";
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=displayView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{details}\" title=\"Display Crontab\" alt=\"Display Crontab\" border=\"0\"></a>&nbsp;" if ($iconDetails);
            $actionItem .= "<a href=\"$urlWithAccessParametersAction=editView\" target=\"_blank\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Crontab\" alt=\"Edit Crontab\" border=\"0\"></a>&nbsp;" if ($iconEdit and ! $actionSkip);
            $notActivated = ($CTactivated) ? '' : ' not';
            $matchingViewsCrontabs .= "<tr bgcolor=\"$COLORSTABLE{NOBLOCK}\"><td colspan=\"2\"><b>Crontab: $CuKey-$CTlinenumber -$notActivated activated&nbsp;</b></td><td>$actionItem</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Arguments</td><td>$CTarguments</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Minute</td><td>$CTminute</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Hour</td><td>$CThour</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Day of the Month</td><td>$CTdayOfTheMonth</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Month of the Year</td><td>$CTmonthOfTheYear</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">Day of the Week</td><td>$CTdayOfTheWeek</td><td>&nbsp;</td></tr>\n";
            $matchingViewsCrontabs .= "<tr><td bgcolor=\"$COLORSTABLE{NOBLOCK}\">no Offline</td><td>$CTnoOffline</td><td>&nbsp;</td></tr>\n";

            $prevSserverID         = $SserverID;
            $prevCDcollectorDaemon = $CDcollectorDaemon;
          }

          $generatePluginCrontabSchedulingReport = 1;
        } else {
          $matchingViewsCrontabs .= "<tr><td>No records found</td></tr>\n";
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $matchingViewsCrontabs .= "</table>\n";
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
  if ( document.plugins.uKey.value == null || document.plugins.uKey.value == '' ) {
    document.plugins.uKey.focus();
    alert('Please enter a unique key!');
    return false;
  } else {
    var objectRegularExpressionUkeyFormat = /\^[a-zA-Z0-9-]\+\$/;

    if ( ! objectRegularExpressionUkeyFormat.test(document.plugins.uKey.value) ) {
      document.plugins.uKey.focus();
      alert('Please re-enter a unique key: Bad unique key value!');
      return false;
    }
  }
HTML
      }

      print <<HTML;

  if ( document.plugins.title.value == null || document.plugins.title.value == '' ) {
    document.plugins.title.focus();
    alert('Please enter a title!');
    return false;
  } else {
    var objectRegularExpressionTitleFormat = /[{}]/;

    if ( objectRegularExpressionTitleFormat.test(document.plugins.title.value) ) {
      document.plugins.title.focus();
      alert('Please re-enter a Title: Bad title value, not allowed characters are { and } !');
      return false;
    }
  }

  if ( document.plugins.test.value == null || document.plugins.test.value == '' ) {
    document.plugins.test.focus();
    alert('Please enter a plugin name!');
    return false;
  }

  if ( document.plugins.trendline.value == null || document.plugins.trendline.value == '' ) {
    document.plugins.trendline.focus();
    alert('Please enter a trendline!');
    return false;
  }

  if ( document.plugins.percentage.value == null || document.plugins.percentage.value == '' ) {
    document.plugins.percentage.focus();
    alert('Please enter a percentage!');
    return false;
  }

  if ( document.plugins.tolerance.value == null || document.plugins.tolerance.value == '' ) {
    document.plugins.tolerance.focus();
    alert('Please enter a tolerance!');
    return false;
  }

  if ( document.plugins.step.value == null || document.plugins.step.value == '' || document.plugins.step.value == '0' ) {
    document.plugins.step.focus();
    alert('Please enter a step!');
    return false;
  }

  if ( document.plugins.pagedirs.selectedIndex == -1 ) {
    document.plugins.pagedirs.focus();
    alert('Please create/select one or more view pagedirs!');
    return false;
  }

  if ( document.plugins.resultsdir.options[document.plugins.resultsdir.selectedIndex].value == 'none' ) {
    document.plugins.resultsdir.focus();
    alert('Please create/select a results subdir!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="plugins" enctype="multipart/form-data" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'listView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.plugins.catalogIDreload.value = 1;
  document.plugins.submit();
  return true;
}

function validateForm() {
  if ( document.plugins.filter.value != null || document.plugins.filter.value != "") {
    document.plugins.pageNo.value = 1;
    document.plugins.pageOffset.value = 0 ;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="plugins" enctype="multipart/form-data" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"plugins\">\n";
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

    print "  <input type=\"hidden\" name=\"catalogID\" value=\"$CcatalogID\">\n  <input type=\"hidden\" name=\"uKey\"      value=\"$CuKey\">\n" if ($formDisabledUniqueKey ne '' and $action ne 'displayView');
 
    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td colspan="2">
      <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;orderBy=$orderBy">[Insert plugin]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all/filtered plugins]</a></td>
	  </tr></table>
	</td></tr>
HTML

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      my $ondemandChecked   = ($Condemand eq 'on') ? ' checked' : '';
      my $productionChecked = ($Cproduction eq 'on') ? ' checked' : '';
      my $activatedChecked  = ($Cactivated eq 'on') ? ' checked' : '';

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
      <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Catalog ID: </b></td><td>
          <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled>
        </td></tr>
        <tr><td><b>Unique Key: </b></td><td>
          <input type="text" name="uKey" value="$CuKey" size="11" maxlength="11" $formDisabledUniqueKey>
        <tr><td><b>Title: </b></td><td>
          <input type="text" name="title" value="$Ctitle" size="75" maxlength="75" $formDisabledAll>
        <tr><td valign="top"><b>Short Description: </b></td><td>
          <textarea cols="75" rows="10" name="shortDescription" $formDisabledAll>$CshortDescription</textarea>
        <tr><td><b>Plugin Filename: </b></td><td>
          <input type="text" name="test" value="$Ctest" size="100" maxlength="100" $formDisabledAll>
        <tr><td><b>Environment: </b></td><td>
       $environmentSelect
        <tr><td>Common Arguments: </td><td>
          <input type="text" name="arguments" value="$Carguments" size="100" maxlength="1024" $formDisabledAll>
        <tr><td>On Demand Arguments: </td><td>
          <input type="text" name="argumentsOndemand" value="$CargumentsOndemand" size="100" maxlength="1024" $formDisabledAll>
        <tr><td><b>Trendline: </b></td><td>
          <input type="text" name="trendline" value="$Ctrendline" size="6" maxlength="6" $formDisabledAll>
        <tr><td><b>Percentage: </b></td><td>
          <input type="text" name="percentage" value="$Cpercentage" size="2" maxlength="2" $formDisabledAll>&nbsp;&nbsp;Proposal = MAX ( week ( hour ( AVG ( Duration ), 9-17 ), 1-5 ) ) * 1.percentage
        <tr><td><b>Tolerance: </b></td><td>
          <input type="text" name="tolerance" value="$Ctolerance" size="2" maxlength="2" $formDisabledAll>&nbsp;&nbsp;Proposal * 0.tolerance < Trendline < Proposal * 1.tolerance where Tolerance=0 means FIXED Trendline
        <tr><td><b>Step: </b></td><td>
          <input type="text" name="step" value="$Cstep" size="6" maxlength="6" $formDisabledAll>
        <tr><td><b>Run On Demand: </b></td><td>
          <input type="checkbox" name="ondemand" $ondemandChecked $formDisabledAll>
        <tr><td><b>Into Production: </b></td><td>
          <input type="checkbox" name="production" $productionChecked $formDisabledAll>
        <tr><td valign="top"><b>View Pagedirs: </b></td><td>
       $pagedirsSelect
        <tr><td><b>Results Subdir: </b></td><td>
          $resultsdirSelect
        <tr><td valign="top">Help Plugin Filename: </td><td>
          <input type="text" name="helpPluginTextname" value="$ChelpPluginFilename" size="100" maxlength="100" $formDisabledAll><br>
          <input type="file" name="helpPluginFilename" size="100" accept="application/pdf" $formDisabledAll>
        <tr><td>Holiday Bundle: </td><td>
       $holidayBundleSelect
        <tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Unique Key: $htmlTitle$ChelpPluginTextname</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingPlugins</td></tr>" if (defined $matchingPlugins and $matchingPlugins ne '');
    } else {
      print "    <tr><td><br><table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='#333344'><tr><td align=\"left\"><b>Catalog ID: </b></td><td>$catalogIDSelect</td><td>&nbsp;<input type=\"text\" name=\"filter\" size=\"25\" maxlength=\"50\">&nbsp;<input type=\"submit\" value=\"Filter\"></td></tr></table></td></tr>";
      print "    <tr><td align=\"center\"><br>$matchingPlugins</td></tr>";
    }

    print "  </table>\n";

    if ($action eq 'deleteView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView' or $action eq 'listView') {
      print "</form>\n";
    } else {
      print "<br>\n";
    }

    if (defined $matchingViewsCrontabs) {
      print "<table align=\"center\">\n<tr><td>\n$matchingViewsCrontabs</td></tr></table><br>\n";
      print "<table align=\"center\">\n<tr><td>\n<img src=\"$HTTPSURL/cgi-bin/moderator/generatePluginCrontabSchedulingReport.pl?catalogID=$CcatalogID&uKey=$CuKey&amp;".encode_html_entities('U', "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID")."\"></td></tr></table><br>\n" if (defined $generatePluginCrontabSchedulingReport);
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
