#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, servers.pl for ASNMTAP::Asnmtap::Applications::CGI
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

$PROGNAME       = "servers.pl";
my $prgtext     = "Servers";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))            ? $cgi->param('pagedir')            : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))            ? $cgi->param('pageset')            : 'sadmin';  $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))              ? $cgi->param('debug')              : 'F';
my $pageNo              = (defined $cgi->param('pageNo'))             ? $cgi->param('pageNo')             : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))         ? $cgi->param('pageOffset')         : 0;
my $orderBy             = (defined $cgi->param('orderBy'))            ? $cgi->param('orderBy')            : 'serverID asc';
my $action              = (defined $cgi->param('action'))             ? $cgi->param('action')             : 'listView';
my $CcatalogID          = (defined $cgi->param('catalogID'))          ? $cgi->param('catalogID')          : $CATALOGID;
my $CcatalogIDreload    = (defined $cgi->param('catalogIDreload'))    ? $cgi->param('catalogIDreload')    : 0;
my $CserverID           = (defined $cgi->param('serverID'))           ? $cgi->param('serverID')           : '';
my $CserverTitle        = (defined $cgi->param('serverTitle'))        ? $cgi->param('serverTitle')        : '';
my $CmasterFQDN         = (defined $cgi->param('masterFQDN'))         ? $cgi->param('masterFQDN')         : '';
my $CmasterASNMTAP_PATH = (defined $cgi->param('masterASNMTAP_PATH')) ? $cgi->param('masterASNMTAP_PATH') : '';
my $CmasterRSYNC_PATH   = (defined $cgi->param('masterRSYNC_PATH'))   ? $cgi->param('masterRSYNC_PATH')   : '';
my $CmasterSSH_PATH     = (defined $cgi->param('masterSSH_PATH'))     ? $cgi->param('masterSSH_PATH')     : '';
my $CmasterSSHlogon     = (defined $cgi->param('masterSSHlogon'))     ? $cgi->param('masterSSHlogon')     : '';
my $CmasterSSHpasswd    = (defined $cgi->param('masterSSHpasswd'))    ? $cgi->param('masterSSHpasswd')    : '';
my $CmasterDatabaseFQDN = (defined $cgi->param('masterDatabaseFQDN')) ? $cgi->param('masterDatabaseFQDN') : '';
my $CmasterDatabasePort = (defined $cgi->param('masterDatabasePort')) ? $cgi->param('masterDatabasePort') : '3306';
my $CslaveFQDN          = (defined $cgi->param('slaveFQDN'))          ? $cgi->param('slaveFQDN')          : '';
my $CslaveASNMTAP_PATH  = (defined $cgi->param('slaveASNMTAP_PATH'))  ? $cgi->param('slaveASNMTAP_PATH')  : '';
my $CslaveRSYNC_PATH    = (defined $cgi->param('slaveRSYNC_PATH'))    ? $cgi->param('slaveRSYNC_PATH')    : '';
my $CslaveSSH_PATH      = (defined $cgi->param('slaveSSH_PATH'))      ? $cgi->param('slaveSSH_PATH')      : '';
my $CslaveSSHlogon      = (defined $cgi->param('slaveSSHlogon'))      ? $cgi->param('slaveSSHlogon')      : '';
my $CslaveSSHpasswd     = (defined $cgi->param('slaveSSHpasswd'))     ? $cgi->param('slaveSSHpasswd')     : '';
my $CslaveDatabaseFQDN  = (defined $cgi->param('slaveDatabaseFQDN'))  ? $cgi->param('slaveDatabaseFQDN')  : '';
my $CslaveDatabasePort  = (defined $cgi->param('slaveDatabasePort'))  ? $cgi->param('slaveDatabasePort')  : '3306';
my $CtypeServers        = (defined $cgi->param('typeServers'))        ? $cgi->param('typeServers')        : 0;
my $CtypeMonitoring     = (defined $cgi->param('typeMonitoring'))     ? $cgi->param('typeMonitoring')     : 0;
my $CtypeActiveServer   = (defined $cgi->param('typeActiveServer'))   ? $cgi->param('typeActiveServer')   : 'M';
my $Cactivated          = (defined $cgi->param('activated'))          ? $cgi->param('activated')          : 'off';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Server ID", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&serverID=$CserverID&serverTitle=$CserverTitle&masterFQDN=$CmasterFQDN&masterASNMTAP_PATH=$CmasterASNMTAP_PATH&masterRSYNC_PATH=$CmasterRSYNC_PATH&masterSSH_PATH=$CmasterSSH_PATH&masterSSHlogon=$CmasterSSHlogon&masterSSHpasswd=$CmasterSSHpasswd&masterDatabaseFQDN=$CmasterDatabaseFQDN&masterDatabasePort=$CmasterDatabasePort&slaveFQDN=$CslaveFQDN&slaveASNMTAP_PATH=$CslaveASNMTAP_PATH&slaveRSYNC_PATH=$CslaveRSYNC_PATH&slaveSSH_PATH=$CslaveSSH_PATH&slaveSSHlogon=$CslaveSSHlogon&slaveSSHpasswd=$CslaveSSHpasswd&slaveDatabaseFQDN=$CslaveDatabaseFQDN&slaveDatabasePort=$CslaveDatabasePort&typeServers=$CtypeServers&typeMonitoring=$CtypeMonitoring&typeActiveServer=$CtypeActiveServer&activated=$Cactivated";

# Debug information
print "<pre>pagedir           : $pagedir<br>pageset           : $pageset<br>debug             : $debug<br>CGISESSID         : $sessionID<br>page no           : $pageNo<br>page offset       : $pageOffset<br>order by          : $orderBy<br>action            : $action<br>catalog ID        : $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br>server ID         : $CserverID<br>serverTitle       : $CserverTitle<br>masterFQDN        : $CmasterFQDN<br>masterASNMTAP_PATH: $CmasterASNMTAP_PATH<br>masterRSYNC_PATH  : $CmasterRSYNC_PATH<br>masterSSH_PATH    : $CmasterSSH_PATH<br>masterSSHlogon    : $CmasterSSHlogon<br>masterSSHpasswd   : $CmasterSSHpasswd<br>masterDatabaseFQDN: $CmasterDatabaseFQDN<br>masterDatabasePort: $CmasterDatabasePort<br>slaveFQDN         : $CslaveFQDN<br>slaveASNMTAP_PATH : $CslaveASNMTAP_PATH<br>slaveRSYNC_PATH   : $CslaveRSYNC_PATH<br>slaveSSH_PATH     : $CslaveSSH_PATH<br>slaveSSHlogon     : $CslaveSSHlogon<br>slaveSSHpasswd    : $CslaveSSHpasswd<br>slaveDatabaseFQDN : $CslaveDatabaseFQDN<br>slaveDatabaseFQDN : $CslaveDatabaseFQDN<br>typeServers       : $CtypeServers<br>typeMonitoring    : $CtypeMonitoring<br>typeActiveServer  : $CtypeActiveServer<br>activated         : $Cactivated<br>URL ...           : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($catalogIDSelect, $matchingServers, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;catalogID=$CcatalogID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledPrimaryKey = '';

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert Server ID";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
      $CcatalogID   = $CATALOGID if ($action eq 'insertView');
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Server ID $CserverID from $CcatalogID exist before to insert";

      $sql = "select serverID from $SERVERTABLSERVERS WHERE catalogID = '$CcatalogID' and serverID='$CserverID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle  = "Server ID $CserverID from $CcatalogID exist already";
        $nextAction = "insertView";
      } else {
        $htmlTitle  = "Server ID $CserverID from $CcatalogID inserted";
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $sql = 'INSERT INTO ' .$SERVERTABLSERVERS. ' SET catalogID="' .$CcatalogID. '", serverID="' .$CserverID. '", serverTitle="' .$CserverTitle. '", masterFQDN="' .$CmasterFQDN. '", masterASNMTAP_PATH="' .$CmasterASNMTAP_PATH. '", masterRSYNC_PATH="' .$CmasterRSYNC_PATH. '", masterSSH_PATH="' .$CmasterSSH_PATH. '", masterSSHlogon="' .$CmasterSSHlogon. '", masterSSHpasswd="' .$CmasterSSHpasswd. '", masterDatabaseFQDN="' .$CmasterDatabaseFQDN. '", masterDatabasePort="' .$CmasterDatabasePort. '", slaveFQDN="' .$CslaveFQDN. '", slaveASNMTAP_PATH="' .$CslaveASNMTAP_PATH. '", slaveRSYNC_PATH="' .$CslaveRSYNC_PATH. '", slaveSSH_PATH="' .$CslaveSSH_PATH. '", slaveSSHlogon="' .$CslaveSSHlogon. '", slaveSSHpasswd="' .$CslaveSSHpasswd. '", slaveDatabaseFQDN="' .$CslaveDatabaseFQDN. '", slaveDatabasePort="' .$CslaveDatabasePort. '", typeServers="' .$CtypeServers. '", typeMonitoring="' .$CtypeMonitoring. '", typeActiveServer="' .$CtypeActiveServer. '", activated="' .$dummyActivated. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Delete Server ID $CserverID from $CcatalogID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $sql = "select collectorDaemon, groupName from $SERVERTABLCLLCTRDMNS where catalogID = '$CcatalogID' and serverID = '$CserverID' order by groupName";
      ($rv, $matchingServers) = check_record_exist ($rv, $dbh, $sql, 'Collector Daemon from ' .$CcatalogID, 'Collector Daemon', 'Group Name', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select displayDaemon, groupName from $SERVERTABLDISPLAYDMNS where catalogID = '$CcatalogID' and serverID = '$CserverID' order by groupName";
      ($rv, $matchingServers) = check_record_exist ($rv, $dbh, $sql, 'Display Daemons from ' .$CcatalogID, 'Display Daemon', 'Group Name', $matchingServers, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ($matchingServers eq '') {
        $htmlTitle = "Server ID $CserverID from $CcatalogID deleted";
        $sql = 'DELETE FROM ' .$SERVERTABLSERVERS. ' WHERE catalogID="' .$CcatalogID. '" and serverID="' .$CserverID. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction = "listView" if ($rv);
      } else {
        $htmlTitle = "Server ID $CserverID from $CcatalogID not deleted, still used by";
      }

      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'displayView') {
      $formDisabledPrimaryKey = $formDisabledAll = 'disabled';
      $htmlTitle    = "Display Server ID $CserverID from $CcatalogID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Edit Server ID $CserverID from $CcatalogID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $htmlTitle    = "Server ID $CserverID from $CcatalogID updated";
      my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
      $sql = 'UPDATE ' .$SERVERTABLSERVERS. ' SET catalogID="' .$CcatalogID. '", serverID="' .$CserverID. '", serverTitle="' .$CserverTitle. '", masterFQDN="' .$CmasterFQDN. '", masterASNMTAP_PATH="' .$CmasterASNMTAP_PATH. '", masterRSYNC_PATH="' .$CmasterRSYNC_PATH. '", masterSSH_PATH="' .$CmasterSSH_PATH. '", masterSSHlogon="' .$CmasterSSHlogon. '", masterSSHpasswd="' .$CmasterSSHpasswd. '", masterDatabaseFQDN="' .$CmasterDatabaseFQDN. '", masterDatabasePort="' .$CmasterDatabasePort. '", slaveFQDN="' .$CslaveFQDN. '", slaveASNMTAP_PATH="' .$CslaveASNMTAP_PATH. '", slaveRSYNC_PATH="' .$CslaveRSYNC_PATH. '", slaveSSH_PATH="' .$CslaveSSH_PATH. '", slaveSSHlogon="' .$CslaveSSHlogon. '", slaveSSHpasswd="' .$CslaveSSHpasswd. '", slaveDatabaseFQDN="' .$CslaveDatabaseFQDN. '", slaveDatabasePort="' .$CslaveDatabasePort. '", typeServers="' .$CtypeServers. '", typeMonitoring="' .$CtypeMonitoring. '", typeActiveServer="' .$CtypeActiveServer. '", activated="' .$dummyActivated. '" WHERE catalogID="' .$CcatalogID. '" and serverID="' .$CserverID. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'listView') {
      $htmlTitle    = "All Servers listed";
      $nextAction   = "listView";

      if ( $CcatalogIDreload ) {
        $pageNo = 1;
        $pageOffset = 0;
      }

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select SQL_NO_CACHE count(serverID) from $SERVERTABLSERVERS where catalogID = '$CcatalogID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID&amp;orderBy=$orderBy");

      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLSERVERS, 'serverTitle', "catalogID = '$CcatalogID'", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select catalogID, serverID, serverTitle, typeMonitoring, typeServers, typeActiveServer, activated from $SERVERTABLSERVERS where catalogID = '$CcatalogID' order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID desc, serverID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID asc, serverID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverID desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Server ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverID asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      $header .= "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverTitle desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Server Title <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=typeMonitoring desc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Type Monitoring <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=typeMonitoring asc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=typeServers desc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Type Servers <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=typeServers asc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=typeActiveServer desc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Type Active Server <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=typeActiveServer asc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc, serverTitle asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingServers, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Server', 'catalogID|serverID', '0|1', '', '3#0=>Central|1=>Distributed||4#0=>Standalone|1=>Failover||5#M=>Master|S=>Slave', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select catalogID, serverID, serverTitle, masterFQDN, masterASNMTAP_PATH, masterRSYNC_PATH, masterSSH_PATH, masterSSHlogon, masterSSHpasswd, masterDatabaseFQDN, masterDatabasePort, slaveFQDN, slaveASNMTAP_PATH, slaveRSYNC_PATH, slaveSSH_PATH, slaveSSHlogon, slaveSSHpasswd, slaveDatabaseFQDN, slaveDatabasePort, typeServers, typeMonitoring, typeActiveServer, activated from $SERVERTABLSERVERS where catalogID='$CcatalogID' and serverID='$CserverID'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcatalogID, $CserverID, $CserverTitle, $CmasterFQDN, $CmasterASNMTAP_PATH, $CmasterRSYNC_PATH , $CmasterSSH_PATH, $CmasterSSHlogon, $CmasterSSHpasswd, $CmasterDatabaseFQDN, $CmasterDatabasePort, $CslaveFQDN, $CslaveASNMTAP_PATH, $CslaveRSYNC_PATH , $CslaveSSH_PATH, $CslaveSSHlogon, $CslaveSSHpasswd, $CslaveDatabaseFQDN, $CslaveDatabasePort, $CtypeServers, $CtypeMonitoring, $CtypeActiveServer, $Cactivated) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
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
      my $onload = "ONLOAD=\"enableOrDisableFields();\"";
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, $onload, 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function enableOrDisableFields() {
  var typeServerDisabled = false;

  if( document.servers.typeServers.options[document.servers.typeServers.selectedIndex].value == '0' ) {
    typeServerDisabled = true;
  }

  document.servers.typeActiveServer.disabled  = typeServerDisabled;

  document.servers.slaveFQDN.disabled         = typeServerDisabled;
  document.servers.slaveASNMTAP_PATH.disabled = typeServerDisabled;
  document.servers.slaveRSYNC_PATH.disabled   = typeServerDisabled;
  document.servers.slaveSSH_PATH.disabled     = typeServerDisabled;
  document.servers.slaveSSHlogon.disabled     = typeServerDisabled;
  document.servers.slaveSSHpasswd.disabled    = typeServerDisabled;

  var typeMonitoringDisabled = false;

  if( document.servers.typeMonitoring.options[document.servers.typeMonitoring.selectedIndex].value == '1' ) {
    typeMonitoringDisabled = true;
    typeServerDisabled = true;
  }

  document.servers.masterDatabaseFQDN.disabled = typeMonitoringDisabled;
  document.servers.masterDatabasePort.disabled = typeMonitoringDisabled;

  document.servers.slaveDatabaseFQDN.disabled  = typeServerDisabled;
  document.servers.slaveDatabasePort.disabled  = typeServerDisabled;
}

function validateForm() {
  var objectRegularExpressionFQDNValue  = /\^[a-zA-Z0-9-]\+(\\.[a-zA-Z0-9-]\+)\*\$/;

  var objectRegularExpressionPATHValue =  /\^(\\/[a-zA-Z0-9-\\s]\+)\*\$/;

  var objectRegularExpressionLogonValue = /\^[a-zA-Z0-9-]\+\$/;

  // The password must contain at least 1 number, at least 1 lower case letter, and at least 1 upper case letter.
  var objectRegularExpressionPasswordFormat = /\^[\\w|\\W]*(?=[\\w|\\W]*\\d)(?=[\\w|\\W]*[a-z])(?=[\\w|\\W]\*[A-Z])[\\w|\\W]*\$/;

  var objectRegularExpressionDatabasePort = /\^[0-9]\+\$/;

HTML

      if ($action eq 'duplicateView' or $action eq 'insertView') {
        print <<HTML;
  var objectRegularExpressionServerIDFormat = /\^[a-zA-Z0-9-]\+\$/;

  if ( document.servers.serverID.value == null || document.servers.serverID.value == '' ) {
    document.servers.serverID.focus();
    alert('Please enter a server ID!');
    return false;
  } else {
    if ( ! objectRegularExpressionServerIDFormat.test(document.servers.serverID.value) ) {
      document.servers.serverID.focus();
      alert('Please re-enter server ID: Bad server ID format!');
      return false;
    }
  }
HTML
      }

      print <<HTML;
  if ( document.servers.serverTitle.value == null || document.servers.serverTitle.value == '' ) {
    document.servers.serverTitle.focus();
    alert('Please enter a server title!');
    return false;
  }

  if ( document.servers.masterFQDN.value == null || document.servers.masterFQDN.value == '' ) {
    document.servers.masterFQDN.focus();
    alert('Please enter a master FQDN!');
    return false;
  } else {
    if ( ! objectRegularExpressionFQDNValue.test(document.servers.masterFQDN.value) ) {
      document.servers.masterFQDN.focus();
      alert('Please re-enter master FQDN: Bad master FQDN value!');
      return false;
    }
  }

  if ( document.servers.masterASNMTAP_PATH.value == null || document.servers.masterASNMTAP_PATH.value == '' ) {
    document.servers.masterASNMTAP_PATH.focus();
    alert('Please enter a master ASNMTAP_PATH!');
    return false;
  } else {
    if ( ! objectRegularExpressionPATHValue.test(document.servers.masterASNMTAP_PATH.value) ) {
      document.servers.masterASNMTAP_PATH.focus();
      alert('Please re-enter master ASNMTAP_PATH: Bad master ASNMTAP_PATH value!');
      return false;
    }
  }

  if ( document.servers.masterRSYNC_PATH.value == null || document.servers.masterRSYNC_PATH.value == '' ) {
    document.servers.masterRSYNC_PATH.focus();
    alert('Please enter a master RSYNC_PATH!');
    return false;
  } else {
    if ( ! objectRegularExpressionPATHValue.test(document.servers.masterRSYNC_PATH.value) ) {
      document.servers.masterRSYNC_PATH.focus();
      alert('Please re-enter master RSYNC_PATH: Bad master RSYNC_PATH value!');
      return false;
    }
  }

  if ( document.servers.masterSSH_PATH.value == null || document.servers.masterSSH_PATH.value == '' ) {
    document.servers.masterSSH_PATH.focus();
    alert('Please enter a master SSH_PATH!');
    return false;
  } else {
    if ( ! objectRegularExpressionPATHValue.test(document.servers.masterSSH_PATH.value) ) {
      document.servers.masterSSH_PATH.focus();
      alert('Please re-enter master SSH_PATH: Bad master SSH_PATH value!');
      return false;
    }
  }

  if ( ! ( document.servers.masterSSHlogon.value == null || document.servers.masterSSHlogon.value == '' ) ) {
    if ( ! objectRegularExpressionLogonValue.test(document.servers.masterSSHlogon.value) ) {
      document.servers.masterSSHlogon.focus();
      alert('Please re-enter master SSH logon: Bad master SSH logon value!');
      return false;
    }
  }

  if ( ! ( document.servers.masterSSHpasswd.value == null || document.servers.masterSSHpasswd.value == '' ) ) {
    if ( ! objectRegularExpressionPasswordFormat.test(document.servers.masterSSHpasswd.value) ) {
      document.servers.masterSSHpasswd.focus();
      alert('Please re-enter master SSH passwd: Bad master SSH passwd format!');
      return false;
    }
  }

  if ( ! document.servers.masterDatabaseFQDN.disabled ) {
    if ( document.servers.masterDatabaseFQDN.value == null || document.servers.masterDatabaseFQDN.value == '' ) {
      document.servers.masterDatabaseFQDN.focus();
      alert('Please enter a master database FQDN!');
      return false;
    } else {
      if ( ! objectRegularExpressionFQDNValue.test(document.servers.masterDatabaseFQDN.value) ) {
        document.servers.masterDatabaseFQDN.focus();
        alert('Please re-enter master database FQDN: Bad master database FQDN value!');
        return false;
      }
    }

    if ( document.servers.masterDatabasePort.value == null || document.servers.masterDatabasePort.value == '' ) {
      document.servers.masterDatabasePort.focus();
      alert('Please enter a master database port!');
      return false;
    } else {
      if ( ! objectRegularExpressionDatabasePort.test(document.servers.masterDatabasePort.value) ) {
        document.servers.masterDatabasePort.focus();
        alert('Please re-enter master database port: Bad master database port value!');
        return false;
      }
    }
  }

  if( document.servers.typeServers.options[document.servers.typeServers.selectedIndex].value == '1' ) {
    if ( document.servers.slaveFQDN.value == null || document.servers.slaveFQDN.value == '' ) {
      document.servers.slaveFQDN.focus();
      alert('Please enter a slave FQDN!');
      return false;
    }

    if ( document.servers.slaveASNMTAP_PATH.value == null || document.servers.slaveASNMTAP_PATH.value == '' ) {
      document.servers.slaveASNMTAP_PATH.focus();
      alert('Please enter a slave ASNMTAP_PATH!');
      return false;
    }

    if ( document.servers.slaveRSYNC_PATH.value == null || document.servers.slaveRSYNC_PATH.value == '' ) {
      document.servers.slaveRSYNC_PATH.focus();
      alert('Please enter a slave RSYNC_PATH!');
      return false;
    }

    if ( document.servers.slaveSSH_PATH.value == null || document.servers.slaveSSH_PATH.value == '' ) {
      document.servers.slaveSSH_PATH.focus();
      alert('Please enter a slave SSH_PATH!');
      return false;
    }

    if ( ! document.servers.slaveDatabaseFQDN.disabled ) {
      if ( document.servers.slaveDatabaseFQDN.value == null || document.servers.slaveDatabaseFQDN.value == '' ) {
        document.servers.slaveDatabaseFQDN.focus();
        alert('Please enter a slave database FQDN!');
        return false;
      }

      if ( document.servers.slaveDatabasePort.value == null || document.servers.slaveDatabasePort.value == '' ) {
        document.servers.slaveDatabasePort.focus();
        alert('Please enter a slave database port!');
        return false;
      }
    }
  }

  if ( ! (document.servers.slaveFQDN.value == null || document.servers.slaveFQDN.value == '' ) ) {
    if ( ! objectRegularExpressionFQDNValue.test(document.servers.slaveFQDN.value) ) {
      document.servers.slaveFQDN.focus();
      alert('Please re-enter slave FQDN: Bad slave FQDN value!');
      return false;
    }
  }

  if ( ! (document.servers.slaveASNMTAP_PATH.value == null || document.servers.slaveASNMTAP_PATH.value == '' ) ) {
    if ( ! objectRegularExpressionPATHValue.test(document.servers.slaveASNMTAP_PATH.value) ) {
      document.servers.slaveASNMTAP_PATH.focus();
      alert('Please re-enter slave ASNMTAP_PATH: Bad slave ASNMTAP_PATH value!');
      return false;
    }
  }

  if ( ! (document.servers.slaveRSYNC_PATH.value == null || document.servers.slaveRSYNC_PATH.value == '' ) ) {
    if ( ! objectRegularExpressionPATHValue.test(document.servers.slaveRSYNC_PATH.value) ) {
      document.servers.slaveRSYNC_PATH.focus();
      alert('Please re-enter slave RSYNC_PATH: Bad slave RSYNC_PATH value!');
      return false;
    }
  }

  if ( ! (document.servers.slaveSSH_PATH.value == null || document.servers.slaveSSH_PATH.value == '' ) ) {
    if ( ! objectRegularExpressionPATHValue.test(document.servers.slaveSSH_PATH.value) ) {
      document.servers.slaveSSH_PATH.focus();
      alert('Please re-enter slave SSH_PATH: Bad slave SSH_PATH value!');
      return false;
    }
  }

  if ( ! ( document.servers.slaveSSHlogon.value == null || document.servers.slaveSSHlogon.value == '' ) ) {
    if ( ! objectRegularExpressionLogonValue.test(document.servers.slaveSSHlogon.value) ) {
      document.servers.slaveSSHlogon.focus();
      alert('Please re-enter slave SSH logon: Bad slave SSH logon value!');
      return false;
    }
  }

  if ( ! (document.servers.slaveSSHpasswd.value == null || document.servers.slaveSSHpasswd.value == '') ) {
    if ( ! objectRegularExpressionPasswordFormat.test(document.servers.slaveSSHpasswd.value) ) {
      document.servers.slaveSSHpasswd.focus();
      alert('Please re-enter slave SSH passwd: Bad slave SSH passwd format!');
      return false;
    }
  }

  if ( ! (document.servers.slaveDatabaseFQDN.value == null || document.servers.slaveDatabaseFQDN.value == '' ) ) {
    if ( ! objectRegularExpressionFQDNValue.test(document.servers.slaveDatabaseFQDN.value) ) {
      document.servers.slaveDatabaseFQDN.focus();
      alert('Please re-enter slave database FQDN: Bad slave database FQDN value!');
      return false;
    }
  }

  if ( ! (document.servers.slaveDatabasePort.value == null || document.servers.slaveDatabasePort.value == '' ) ) {
    if ( ! objectRegularExpressionDatabasePort.test(document.servers.slaveDatabasePort.value) ) {
      document.servers.slaveDatabasePort.focus();
      alert('Please re-enter slave database port: Bad slave database port value!');
      return false;
    }
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="servers" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'listView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.servers.catalogIDreload.value = 1;
  document.servers.submit();
  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="servers">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"serverID\">\n";
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

    print "  <input type=\"hidden\" name=\"catalogID\" value=\"$CcatalogID\">\n  <input type=\"hidden\" name=\"serverID\"  value=\"$CserverID\">\n" if ($formDisabledPrimaryKey ne '' and $action ne 'displayView');

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=insertView&amp;orderBy=$orderBy">[Insert Server]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;pageNo=1&amp;pageOffset=0&amp;action=listView&amp;orderBy=$orderBy">[List all Servers]</a></td>
	  </tr></table>
	</td></tr>
HTML

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      my $typeMonitoringSelect = create_combobox_from_keys_and_values_pairs ('0=>Central|1=>Distributed', 'K', 0, $CtypeMonitoring, 'typeMonitoring', '', '', $formDisabledAll, 'onChange="javascript:enableOrDisableFields();"', $debug);

      my $typeServersSelect = create_combobox_from_keys_and_values_pairs ('0=>Standalone|1=>Failover', 'K', 0, $CtypeServers, 'typeServers', '', '', $formDisabledAll, 'onChange="javascript:enableOrDisableFields();"', $debug);

      my $typeActiveServerSelect = create_combobox_from_keys_and_values_pairs ('M=>Master|S=>Slave', 'K', 0, $CtypeActiveServer, 'typeActiveServer', '', '', $formDisabledAll, 'onChange="javascript:enableOrDisableFields();"', $debug);

      my $activatedChecked = ($Cactivated eq 'on') ? ' checked' : '';

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Catalog ID: </b></td><td colspan="3">
          <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled>
        </td></tr>
        <tr><td><b>Server ID: </b></td><td colspan="3">
          <input type="text" name="serverID" value="$CserverID" size="11" maxlength="11" $formDisabledPrimaryKey> format: [a-z|A-Z|0-9|-]
        </td></tr><tr><td><b>Server Title: </b></td><td colspan="3">
          <input type="text" name="serverTitle" value="$CserverTitle" size="64" maxlength="64" $formDisabledAll>
        </td></tr><tr><td colspan="4">&nbsp;
    	</td></tr><tr><td><b>Type Monitoring: </b></td><td>
           $typeMonitoringSelect
        </td><td>&nbsp;&nbsp;<b>Type Servers: </b></td><td>
           $typeServersSelect
        </td></tr><tr><td><b>Master FQDN: </b></td><td>
          <input type="text" name="masterFQDN" value="$CmasterFQDN" size="64" maxlength="64" $formDisabledAll>
        </td><td>&nbsp;&nbsp;<b>Slave FQDN: </b></td><td>
          <input type="text" name="slaveFQDN" value="$CslaveFQDN" size="64" maxlength="64" $formDisabledAll>
        </td></tr><tr><td><b>Master ASNMTAP_PATH: </b></td><td>
          <input type="text" name="masterASNMTAP_PATH" value="$CmasterASNMTAP_PATH" size="64" maxlength="64" $formDisabledAll>
        </td><td>&nbsp;&nbsp;<b>Slave ASNMTAP_PATH: </b></td><td>
          <input type="text" name="slaveASNMTAP_PATH" value="$CslaveASNMTAP_PATH" size="64" maxlength="64" $formDisabledAll>
        </td></tr><tr><td><b>Master RSYNC_PATH: </b></td><td>
          <input type="text" name="masterRSYNC_PATH" value="$CmasterRSYNC_PATH" size="64" maxlength="64" $formDisabledAll>
        </td><td>&nbsp;&nbsp;<b>Slave RSYNC_PATH: </b></td><td>
          <input type="text" name="slaveRSYNC_PATH" value="$CslaveRSYNC_PATH" size="64" maxlength="64" $formDisabledAll>
        </td></tr><tr><td><b>Master SSH_PATH: </b></td><td>
          <input type="text" name="masterSSH_PATH" value="$CmasterSSH_PATH" size="64" maxlength="64" $formDisabledAll>
        </td><td>&nbsp;&nbsp;<b>Slave SSH_PATH: </b></td><td>
          <input type="text" name="slaveSSH_PATH" value="$CslaveSSH_PATH" size="64" maxlength="64" $formDisabledAll>
        </td></tr><tr><td>Master SSH logon: </td><td>
          <input type="text" name="masterSSHlogon" value="$CmasterSSHlogon" size="15" maxlength="15" $formDisabledAll>
        </td><td>&nbsp;&nbsp;Slave SSH logon: </td><td>
          <input type="text" name="slaveSSHlogon" value="$CslaveSSHlogon" size="15" maxlength="15" $formDisabledAll>
        </td></tr><tr><td>Master SSH passwd: </td><td>
          <input type="password" name="masterSSHpasswd" value="$CmasterSSHpasswd" size="32" maxlength="32" $formDisabledAll>
        </td><td>&nbsp;&nbsp;Slave SSH passwd: </td><td>
          <input type="password" name="slaveSSHpasswd" value="$CslaveSSHpasswd" size="32" maxlength="32" $formDisabledAll>
        </td></tr><tr><td><b>Master Database FQDN: </b></td><td>
          <input type="text" name="masterDatabaseFQDN" value="$CmasterDatabaseFQDN" size="64" maxlength="64" $formDisabledAll>
        </td><td>&nbsp;&nbsp;<b>Slave Database FQDN:</b> </td><td>
          <input type="text" name="slaveDatabaseFQDN" value="$CslaveDatabaseFQDN" size="64" maxlength="64" $formDisabledAll>
        <tr><td><b>Master Database Port: </b></td><td>
          <input type="text" name="masterDatabasePort" value="$CmasterDatabasePort" size="4" maxlength="4" $formDisabledAll>
        </td><td>&nbsp;&nbsp;<b>Slave Database Port:</b> </td><td>
          <input type="text" name="slaveDatabasePort" value="$CslaveDatabasePort" size="4" maxlength="4" $formDisabledAll>
        </td></tr><tr><td colspan="4">&nbsp;
        </td></tr><tr><td><b>Server Activated: </b></td><td>
           $typeActiveServerSelect
        </td><td>&nbsp;&nbsp;<b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td colspan=\"3\"><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td colspan=\"3\"><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Unique Key: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingServers</td></tr>" if (defined $matchingServers and $matchingServers ne '');
    } else {
      print "    <tr><td><br><table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='#333344'><tr><td align=\"left\"><b>Catalog ID: </b></td><td>$catalogIDSelect</td></tr></table></td></tr>";
      print "    <tr><td align=\"center\"><br>$matchingServers</td></tr>";
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

