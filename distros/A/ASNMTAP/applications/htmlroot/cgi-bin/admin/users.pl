#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, users.pl for ASNMTAP::Asnmtap::Applications::CGI
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

$PROGNAME       = "users.pl";
my $prgtext     = "Users";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))            ? $cgi->param('pagedir')            : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))            ? $cgi->param('pageset')            : 'admin';   $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))              ? $cgi->param('debug')              : 'F';
my $pageNo              = (defined $cgi->param('pageNo'))             ? $cgi->param('pageNo')             : 1;
my $pageOffset          = (defined $cgi->param('pageOffset'))         ? $cgi->param('pageOffset')         : 0;
my $orderBy             = (defined $cgi->param('orderBy'))            ? $cgi->param('orderBy')            : 'remoteUser';
my $action              = (defined $cgi->param('action'))             ? $cgi->param('action')             : 'listView';
my $CcatalogID          = (defined $cgi->param('catalogID'))          ? $cgi->param('catalogID')          : $CATALOGID;
my $CcatalogIDreload    = (defined $cgi->param('catalogIDreload'))    ? $cgi->param('catalogIDreload')    : 0;
my $CremoteUser         = (defined $cgi->param('remoteUser'))         ? $cgi->param('remoteUser')         : '';
my $CremoteAddr         = (defined $cgi->param('remoteAddr'))         ? $cgi->param('remoteAddr')         : '';
my $CremoteNetmask      = (defined $cgi->param('remoteNetmask'))      ? $cgi->param('remoteNetmask')      : '';
my $CgivenName          = (defined $cgi->param('givenName'))          ? $cgi->param('givenName')          : '';
my $CfamilyName         = (defined $cgi->param('familyName'))         ? $cgi->param('familyName')         : '';
my $Cemail              = (defined $cgi->param('email'))              ? $cgi->param('email')              : '';
my $CdowntimeScheduling = (defined $cgi->param('downtimeScheduling')) ? $cgi->param('downtimeScheduling') : 'off';
my $CgeneratedReports   = (defined $cgi->param('generatedReports'))   ? $cgi->param('generatedReports')   : 'off';
my $Cpassword           = (defined $cgi->param('password'))           ? $cgi->param('password')           : '';
my $CuserType           = (defined $cgi->param('userType'))           ? $cgi->param('userType')           : 0;
my @Cpagedir            =          $cgi->param('pagedirs');
my $CkeyLanguage        = (defined $cgi->param('keyLanguage'))        ? $cgi->param('keyLanguage')        : 'none';
my $Cactivated          = (defined $cgi->param('activated'))          ? $cgi->param('activated')          : 'off';

my $Cpagedir = (@Cpagedir) ? '/'. join ('/', @Cpagedir) .'/' : '';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledRemoteUser, $submitButton, $givenName, $familyName, $password);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Users", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&remoteUser=$CremoteUser&remoteAddr=$CremoteAddr&remoteNetmask=$CremoteNetmask&givenName=$CgivenName&familyName=$CfamilyName&email=$Cemail&downtimeScheduling=$CdowntimeScheduling&generatedReports=$CgeneratedReports&password=$Cpassword&userType=$CuserType&pagedirs=$Cpagedir&activated=$Cactivated&keyLanguage=$CkeyLanguage";

# Debug information
print "<pre>pagedir            : $pagedir<br>pageset            : $pageset<br>debug              : $debug<br>CGISESSID          : $sessionID<br>page no            : $pageNo<br>page offset        : $pageOffset<br>order by           : $orderBy<br>action             : $action<br>catalog ID         : $CcatalogID<br>catalog ID reload  : $CcatalogIDreload<br>remote user        : $CremoteUser<br>remote address     : $CremoteAddr<br>remote netmask     : $CremoteNetmask<br>given name         : $CgivenName<br>surname            : $CfamilyName<br>email              : $Cemail<br>downtime scheduling: $CdowntimeScheduling<br>generated reports  : $CgeneratedReports<br>password           : $Cpassword<br>user type          : $CuserType<br>pagedirs           : $Cpagedir<br>activated          : $Cactivated<br>key language       : $CkeyLanguage<br>URL ...            : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($catalogIDSelect, $keyLanguageSelect, $pagedirsSelect, $matchingUsers, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset&amp;catalogID=$CcatalogID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledRemoteUser = '';

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert User";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
      $CcatalogID   = $CATALOGID if ($action eq 'insertView');
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if User $CremoteUser from $CcatalogID exist before to insert";

      $sql = "select remoteUser from $SERVERTABLUSERS WHERE catalogID='$CcatalogID' and remoteUser='$CremoteUser'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle    = "User $CremoteUser from $CcatalogID exist already";
        $nextAction   = "insertView";
      } else {
        $htmlTitle    = "User $CremoteUser from $CcatalogID inserted";
        my $dummyDowntimeScheduling = ($CdowntimeScheduling eq 'on') ? 1 : 0;
        my $dummyGeneratedReports = ($CgeneratedReports eq 'on') ? 1 : 0;
        my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
        $Cpassword = '' if ($Cpassword eq "***************");
        $sql = 'INSERT INTO ' .$SERVERTABLUSERS. ' SET catalogID="' .$CcatalogID. '", remoteUser="' .$CremoteUser. '", remoteAddr="' .$CremoteAddr. '", remoteNetmask="' .$CremoteNetmask. '", givenName="' .$CgivenName. '", familyName="' .$CfamilyName. '", email="' .$Cemail. '", downtimeScheduling="' .$dummyDowntimeScheduling. '", generatedReports="' .$dummyGeneratedReports. '", password="' .$Cpassword. '", userType="' .$CuserType. '", pagedir="' .$Cpagedir. '", activated="' .$dummyActivated. '", keyLanguage="' .$CkeyLanguage. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledRemoteUser = $formDisabledAll = 'disabled';
      $htmlTitle    = "Delete user $CremoteUser from $CcatalogID";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $sql = "select remoteUser, title from $SERVERTABLCOMMENTS where catalogID = '$CcatalogID' and remoteUser = '$CremoteUser' order by title, remoteUser";
      ($rv, $matchingUsers) = check_record_exist ($rv, $dbh, $sql, 'Comments from ' .$CcatalogID, 'Remote User', 'Title', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ($matchingUsers eq '') {
        $htmlTitle = "User $CremoteUser from $CcatalogID deleted";
        $sql = 'DELETE FROM ' .$SERVERTABLUSERS. ' WHERE catalogID="' .$CcatalogID. '" and remoteUser="' .$CremoteUser. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction = "listView" if ($rv);
      } else {
        $htmlTitle = "User $CremoteUser from $CcatalogID not deleted, still used by";
      }
    } elsif ($action eq 'displayView') {
      $formDisabledRemoteUser = $formDisabledAll = 'disabled';
      $htmlTitle    = "Display user $CremoteUser from $CcatalogID";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledRemoteUser = 'disabled';
      $htmlTitle    = "Edit user $CremoteUser from $CcatalogID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $htmlTitle    = "User $CremoteUser from $CcatalogID updated";
      my $dummyDowntimeScheduling = ($CdowntimeScheduling eq 'on') ? 1 : 0;
      my $dummyGeneratedReports = ($CgeneratedReports eq 'on') ? 1 : 0;
      my $dummyActivated = ($Cactivated eq 'on') ? 1 : 0;
      my $dummyPassword = ($Cpassword eq "***************") ? '' : ', password="' .$Cpassword. '"';
      $sql = 'UPDATE ' .$SERVERTABLUSERS. ' SET catalogID="' .$CcatalogID. '", remoteUser="' .$CremoteUser. '", remoteAddr="' .$CremoteAddr. '", remoteNetmask="' .$CremoteNetmask. '", givenName="' .$CgivenName. '", familyName="' .$CfamilyName. '", email="' .$Cemail. '", downtimeScheduling="' .$dummyDowntimeScheduling. '", generatedReports="' .$dummyGeneratedReports. '"' .$dummyPassword. ', userType="' .$CuserType. '", pagedir="' .$Cpagedir. '", activated="' .$dummyActivated. '", keyLanguage="' .$CkeyLanguage. '" WHERE catalogID="' .$CcatalogID. '" and remoteUser="' .$CremoteUser. '"';
      $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'listView') {
      $htmlTitle     = "All users listed";

      if ( $CcatalogIDreload ) {
        $pageNo = 1;
        $pageOffset = 0;
      }

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select SQL_NO_CACHE count(remoteUser) from $SERVERTABLUSERS where catalogID = '$CcatalogID'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID&amp;orderBy=$orderBy");

      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLUSERS, 'remoteUser', "catalogID = '$CcatalogID'", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;catalogID=$CcatalogID", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select catalogID, remoteUser, givenName, familyName, userType, activated from $SERVERTABLUSERS where catalogID = '$CcatalogID' and userType <= $userType order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID desc, remoteuser asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Catalog ID <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=catalogID asc, remoteuser asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=remoteuser desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Remote User <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=remoteuser asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      $header .= "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=givenName desc, familyName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Given Name <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=givenName asc, familyName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=familyName desc, givenName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Family Name <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=familyName asc, givenName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=userType desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> User Type	<a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=userType asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=activated asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingUsers, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'User', 'catalogID|remoteUser', '0|1', '', '4#0=>Guest|1=>Member|2=>Moderator|4=>Administrator|8=>Server Administrator', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select catalogID, remoteUser, remoteAddr, remoteNetmask, givenName, familyName, email, downtimeScheduling, generatedReports, password, userType, pagedir, activated, keyLanguage from $SERVERTABLUSERS where catalogID = '$CcatalogID' and remoteUser = '$CremoteUser'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcatalogID, $CremoteUser, $CremoteAddr, $CremoteNetmask, $CgivenName, $CfamilyName, $Cemail, $CdowntimeScheduling, $CgeneratedReports, $Cpassword, $CuserType, $Cpagedir, $Cactivated, $CkeyLanguage) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $CcatalogID = $CATALOGID if ($action eq 'duplicateView');
        $CdowntimeScheduling = ($CdowntimeScheduling == 1) ? 'on' : 'off';
        $CgeneratedReports = ($CgeneratedReports == 1) ? 'on' : 'off';
        $Cactivated = ($Cactivated == 1) ? 'on' : 'off';
        $Cpassword = '***************' if ($Cpassword ne '');
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      $sql = "select keyLanguage, languageName from $SERVERTABLLANGUAGE where languageActive = '1' order by languageName";
      ($rv, $keyLanguageSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CkeyLanguage, 'keyLanguage', 'none', '-Select-', $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select pagedir, groupName from $SERVERTABLPAGEDIRS where catalogID = '$CcatalogID' order by groupName";
      ($rv, $pagedirsSelect) = create_combobox_multiple_from_DBI ($rv, $dbh, $sql, $action, $Cpagedir, 'pagedirs', 'Pagedirs missing.', 10, 100, $formDisabledAll, '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', "<script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/md5.js\"></script>", $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
  // xxx.[xxx.[xxx.[xxx]]]
  var objectRegularExpressionIpAddrFormat    = /\^(\\d{1,3}\\.){1}\$|\^(\\d{1,3}\\.){2}\$|\^(\\d{1,3}\\.){3}\$|\^(\\d{1,3}\\.){3}\\d{1,3}\$/;
  var objectRegularExpressionIpAddrValue     = /\^(\?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\$/;
  var objectRegularExpressionIpAddrValue     = /\^(\?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){1}\$|\^(\?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){2}\$|\^(\?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}\$|\^(\?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\$/;

  // xxx.xxx.xxx.xxx
  var objectRegularExpressionNetmaskFormat   = /\^\\d{2}\$/;
  var objectRegularExpressionNetmaskValue    = /\^(\?:(?:0[1-9]|3[0-2]|[12]?[0-9]?)){1}\$/;

  // x\@y.z minimal
  var objectRegularExpressionEmailFormat     = /\^[\\w-_\\.]\+\\@[\\w-_]\+(\\.[\\w-_]\+)\+\$/;

  var objectRegularExpressionRemoteUserValue = /\^[a-zA-Z0-9-]\+\$/;

  // The password must contain at least 1 number, at least 1 lower case letter, and at least 1 upper case letter.
  var objectRegularExpressionPasswordFormat  = /\^[\\w|\\W]*(?=[\\w|\\W]*\\d)(?=[\\w|\\W]*[a-z])(?=[\\w|\\W]\*[A-Z])[\\w|\\W]*\$/;

HTML

      if ($action eq 'duplicateView' or $action eq 'insertView') {
        print <<HTML;
  if ( document.users.remoteUser.value == null || document.users.remoteUser.value == '' ) {
    document.users.remoteUser.focus();
    alert('Please enter a remote user!');
    return false;
  } else {
    if ( ! objectRegularExpressionRemoteUserValue.test(document.users.remoteUser.value) ) {
      document.users.remoteUser.focus();
      alert('Please re-enter remote user: Bad remote user value!');
      return false;
    }
  }
HTML
      }

      print <<HTML;
  if ( document.users.remoteAddr.value != null && document.users.remoteAddr.value != '' ) {
    if ( ! objectRegularExpressionIpAddrFormat.test(document.users.remoteAddr.value) ) {
      document.users.remoteAddr.focus();
      alert('Please re-enter remote address: Bad ip address format!');
      return false;
    }

    if ( ! objectRegularExpressionIpAddrValue.test(document.users.remoteAddr.value) ) {
      document.users.remoteAddr.focus();
      alert('Please re-enter remote address: Bad ip address value!');
      return false;
    }
  }

  if ( document.users.remoteNetmask.value != null && document.users.remoteNetmask.value != '' ) {
    if ( ! objectRegularExpressionNetmaskFormat.test(document.users.remoteNetmask.value) ) {
      document.users.remoteNetmask.focus();
      alert('Please re-enter remote netmask: Bad netmask address format!');
      return false;
    }

    if ( ! objectRegularExpressionNetmaskValue.test(document.users.remoteNetmask.value) ) {
      document.users.remoteNetmask.focus();
      alert('Please re-enter remote netmask: Bad netmask address value!');
      return false;
    }
  }

  if ( document.users.givenName.value == null || document.users.givenName.value == '' ) {
    document.users.givenName.focus();
    alert('Please enter a given name!');
    return false;
  }

  if ( document.users.familyName.value == null || document.users.familyName.value == '' ) {
    document.users.familyName.focus();
    alert('Please enter a surname!');
    return false;
  }

  if ( document.users.familyName.value == null || document.users.familyName.value == '' ) {
    document.users.familyName.focus();
    alert('Please enter a surname!');
    return false;
  }

  if ( document.users.email.value == null || document.users.email.value == '' ) {
    document.users.email.focus();
    alert('Please enter a email address!');
    return false;
  } else {
    if ( ! objectRegularExpressionEmailFormat.test(document.users.email.value) ) {
      document.users.email.focus();
      alert('Please re-enter email address: Bad email format!');
      return false;
    }
  }

  if ( document.users.password1.value != '***************' ) {
    if ( document.users.password1.value == null || document.users.password1.value == '' ) {
      document.users.password1.focus();
      alert('Please enter a password!');
      return false;
    } else {
      if ( ! objectRegularExpressionPasswordFormat.test(document.users.password1.value) ) {
        document.users.password1.focus();
        alert('Please re-enter password: Bad password format!');
        return false;
      }
    }
  }

  if ( document.users.password2.value != '***************' ) {
    if ( document.users.password2.value == null || document.users.password2.value == '' ) {
      document.users.password2.focus();
      alert('Please enter a password!');
      return false;
    } else {
      if ( ! objectRegularExpressionPasswordFormat.test(document.users.password2.value) ) {
        document.users.password2.focus();
        alert('Please re-enter password: Bad password format!');
        return false;
      }
    }
  }

  if ( document.users.password1.value != '***************' || document.users.password2.value != '***************' ) {
    if ( document.users.password1.value != document.users.password2.value ) {
      document.users.password1.focus();
      alert('Please re-enter passwords: Passwords are not equal!');
      return false;
    } else {
      document.users.password.value = hex_md5(document.users.password1.value);
    }
  }

  if ( document.users.pagedirs.selectedIndex == -1 ) {
    document.users.pagedirs.focus();
    alert('Please create/select one or more view pagedirs!');
    return false;
  }

  if ( document.users.keyLanguage.value == null || document.users.keyLanguage.value == 'none' ) {
    document.users.keyLanguage.focus();
    alert('Please create/select a language!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="users" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'listView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.users.catalogIDreload.value = 1;
  document.users.submit();
  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="users">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"users\">\n";
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
  <input type="hidden" name="password"        value="$Cpassword">
  <input type="hidden" name="catalogIDreload" value="0">
HTML
    } else {
      print "<br>\n";
    }

    print "  <input type=\"hidden\" name=\"catalogID\"    value=\"$CcatalogID\">\n  <input type=\"hidden\" name=\"remoteUser\"   value=\"$CremoteUser\">\n" if ($formDisabledRemoteUser ne '' and $action ne 'displayView');
	
    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;orderBy=$orderBy">[Insert user]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all users]</a></td>
	  </tr></table>
	</td></tr>
HTML

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      my $userTypeValues = '0=>Guest|1=>Member|2=>Moderator|4=>Administrator';
      $userTypeValues .= '|8=>Server Administrator' if ( $userType == 8 );
      my $userTypeSelect = create_combobox_from_keys_and_values_pairs ($userTypeValues, 'K', 0, $CuserType, 'userType', '', '', $formDisabledAll, '', $debug);

      my $downtimeSchedulingChecked = ($CdowntimeScheduling eq 'on') ? ' checked' : '';
      my $generatedReportsChecked   = ($CgeneratedReports eq 'on') ? ' checked' : '';
      my $activatedChecked          = ($Cactivated eq 'on') ? ' checked' : '';

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Catalog ID: </b></td><td>
          <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled>
        </td></tr>
        <tr><td><b>Remote User: </b></td><td>
          <input type="text" name="remoteUser" value="$CremoteUser" size="15" maxlength="15" $formDisabledRemoteUser>
        </td></tr>
		<tr><td>Remote Address: </td><td>
          <input type="text" name="remoteAddr" value="$CremoteAddr" size="15" maxlength="15" $formDisabledAll>&nbsp;&nbsp;format: x.[x.[x.[x]]]
        </td></tr>
		<tr><td>Remote Netmask: </td><td>
          <input type="text" name="remoteNetmask" value="$CremoteNetmask" size="2" maxlength="2" $formDisabledAll>&nbsp;&nbsp;format: 01-32
        </td></tr>
		<tr><td>&nbsp;</td><td>
          <table width="100%">
            <tr><td><font color="#0000FF">32</font> 255.255.255.255</td><td><font color="#0000FF">31</font> 255.255.255.254</td><td><font color="#0000FF">30</font> 255.255.255.252</td><td><font color="#0000FF">29</font> 255.255.255.248</td><td><font color="#0000FF">28</font> 255.255.255.240</td><td><font color="#0000FF">27</font> 255.255.255.224</td><td><font color="#0000FF">26</font> 255.255.255.192</td><td><font color="#0000FF">25</font> 255.255.255.128</td></tr>
            <tr><td><font color="#0000FF">24</font> 255.255.255.0</td><td><font color="#0000FF">23</font> 255.255.254.0</td><td><font color="#0000FF">22</font> 255.255.252.0</td><td><font color="#0000FF">21</font> 255.255.248.0</td><td><font color="#0000FF">20</font> 255.255.240.0</td><td><font color="#0000FF">19</font> 255.255.224.0</td><td><font color="#0000FF">18</font> 255.255.192.0</td><td><font color="#0000FF">17</font> 255.255.128.0</td></tr>
            <tr><td><font color="#0000FF">16</font> 255.255.0.0</td><td><font color="#0000FF">15</font> 255.254.0.0</td><td><font color="#0000FF">14</font> 255.252.0.0</td><td><font color="#0000FF">13</font> 255.248.0.0</td><td><font color="#0000FF">12</font> 255.240.0.0</td><td><font color="#0000FF">11</font> 255.224.0.0</td><td><font color="#0000FF">10</font> 255.192.0.0</td><td><font color="#0000FF">09</font> 255.128.0.0</td></tr>
            <tr><td><font color="#0000FF">08</font> 255.0.0.0</td><td><font color="#0000FF">07</font> 254.0.0.0</td><td><font color="#0000FF">06</font> 252.0.0.0</td><td><font color="#0000FF">05</font> 248.0.0.0</td><td><font color="#0000FF">04</font> 224.0.0.0</td><td><font color="#0000FF">03</font> 240.0.0.0</td><td><font color="#0000FF">02</font> 192.0.0.0</td><td><font color="#0000FF">01</font> 128.0.0.0</td></tr>
          </table>
        </td></tr>
		<tr><td><b>Given Name: </b></td><td>
          <input type="text" name="givenName" value="$CgivenName" size="50" maxlength="50" $formDisabledAll>
        </td></tr>
		<tr><td><b>Surname: </b></td><td>
          <input type="text" name="familyName" value="$CfamilyName" size="50" maxlength="50" $formDisabledAll>
        </td></tr>
		<tr><td><b>Email: </b></td><td>
          <input type="text" name="email" value="$Cemail" size="64" maxlength="64" $formDisabledAll>
        </td></tr>
        </td></tr><tr><td><b>Sending email for:</b></td><td>
          <input type="checkbox" name="downtimeScheduling" $downtimeSchedulingChecked $formDisabledAll>Downtime Scheduling&nbsp;
          <input type="checkbox" name="generatedReports" $generatedReportsChecked $formDisabledAll>Generated Reports&nbsp;
        </td></tr>
		<tr><td><b>Enter password: </b></td><td>
          <input type="password" name="password1" value="$Cpassword" size="15" maxlength="15" $formDisabledAll>&nbsp;&nbsp;The password must contain at least 1 number, at least 1 lower case letter, and at least 1 upper case letter.
        </td></tr>
		<tr><td><b>Confirm Password: </b></td><td>
          <input type="password" name="password2" value="$Cpassword" size="15" maxlength="15" $formDisabledAll>&nbsp;&nbsp;The password must contain at least 1 number, at least 1 lower case letter, and at least 1 upper case letter.
        </td></tr>
		<tr><td><b>User Type: </b></td><td>
          $userTypeSelect
        </td></tr>
		<tr><td valign="top"><b>Pagedirs: </b></td><td>
    	  $pagedirsSelect
        </td></tr>
		<tr><td><b>Language: </b></td><td>
          $keyLanguageSelect
        </td></tr>
		<tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="activated" $activatedChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Remote User: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingUsers</td></tr>" if (defined $matchingUsers and $matchingUsers ne '');
    } else {
      print "    <tr><td><br><table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='#333344'><tr><td align=\"left\"><b>Catalog ID: </b></td><td>$catalogIDSelect</td></tr></table></td></tr>";
      print "    <tr><td align=\"center\"><br>$matchingUsers</td></tr>";
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
