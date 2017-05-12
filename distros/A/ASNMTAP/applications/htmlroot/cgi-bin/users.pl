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

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MEMBER :DBREADWRITE :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "users.pl";
my $prgtext     = "Users";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir             = (defined $cgi->param('pagedir'))       ? $cgi->param('pagedir')       : 'index'; $pagedir =~ s/\+/ /g;
my $pageset             = (defined $cgi->param('pageset'))       ? $cgi->param('pageset')       : 'index-cv'; $pageset =~ s/\+/ /g;
my $debug               = (defined $cgi->param('debug'))         ? $cgi->param('debug')         : 'F';
my $action              = (defined $cgi->param('action'))        ? $cgi->param('action')        : 'editView';
my $CcatalogID          = (defined $cgi->param('catalogID'))     ? $cgi->param('catalogID')     : $CATALOGID;
my $CremoteUser         = (defined $cgi->param('remoteUser'))    ? $cgi->param('remoteUser')    : '';
my $CremoteAddr         = (defined $cgi->param('remoteAddr'))    ? $cgi->param('remoteAddr')    : '';
my $CremoteNetmask      = (defined $cgi->param('remoteNetmask')) ? $cgi->param('remoteNetmask') : '';
my $CgivenName          = (defined $cgi->param('givenName'))     ? $cgi->param('givenName')     : '';
my $CfamilyName         = (defined $cgi->param('familyName'))    ? $cgi->param('familyName')    : '';
my $Cemail              = (defined $cgi->param('email'))         ? $cgi->param('email')         : '';
my $Cpassword           = (defined $cgi->param('password'))      ? $cgi->param('password')      : '';
my $CkeyLanguage        = (defined $cgi->param('keyLanguage'))   ? $cgi->param('keyLanguage')   : 'EN';

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

my $htmlTitle = $APPLICATION .' - '. $ENVIRONMENT{$environment};

# Init parameters
my ($rv, $dbh, $sth, $sql, $nextAction, $submitButton, $keyLanguageSelect, $givenName, $familyName, $password);

# User Session and Access Control
my ($sessionID, undef, undef, undef, undef, undef, undef, $errorUserAccessControl, $remoteUserLoggedOn, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Users", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&action=$action&catalogID=$CcatalogID&remoteUser=$CremoteUser&remoteAddr=$CremoteAddr&remoteNetmask=$CremoteNetmask&givenName=$CgivenName&familyName=$CfamilyName&email=$Cemail&password=$Cpassword&keyLanguage=$CkeyLanguage";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>action        : $action<br>catalog ID    : $CcatalogID<br>remote user   : $CremoteUser<br>remote address: $CremoteAddr<br>remote netmask: $CremoteNetmask<br>given name    : $CgivenName<br>surname       : $CfamilyName<br>email         : $Cemail<br>password      : $Cpassword<br>key language  : $CkeyLanguage<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    if ($action eq 'editView') {
      $CremoteUser  = $remoteUserLoggedOn if (defined $remoteUserLoggedOn);
      $htmlTitle    = "Edit user $CremoteUser from $CcatalogID";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $htmlTitle    = "User $CremoteUser from $CcatalogID updated";
      my $dummyPassword  = ($Cpassword eq "***************") ? '' : ', password="' .$Cpassword. '"';
      $sql = 'UPDATE ' .$SERVERTABLUSERS. ' SET givenName="' .$CgivenName. '", familyName="' .$CfamilyName. '", email="' .$Cemail. '"' .$dummyPassword. ', keyLanguage="' .$CkeyLanguage. '" WHERE catalogID="' .$CcatalogID. '" and remoteUser="' .$CremoteUser. '"';
      $dbh->do( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $nextAction   = "listView" if ($rv);
    }

    if ($action eq 'editView') {
      $sql = "select catalogID, remoteUser, remoteAddr, remoteNetmask, givenName, familyName, email, password, keyLanguage from $SERVERTABLUSERS where catalogID = '$CcatalogID' and remoteUser = '$CremoteUser'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CcatalogID, $CremoteUser, $CremoteAddr, $CremoteNetmask, $CgivenName, $CfamilyName, $Cemail, $Cpassword, $CkeyLanguage) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $Cpassword = "***************" if ($Cpassword ne '');
        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      $sql = "select keyLanguage, languageName from $SERVERTABLLANGUAGE where languageActive = '1' order by languageName";
      ($rv, $keyLanguageSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CkeyLanguage, 'keyLanguage', '', '', '', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if ($action eq 'editView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', "<script type=\"text/javascript\" language=\"JavaScript\" src=\"$HTTPSURL/md5.js\"></script>", $sessionID);

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function validateForm() {
  // x\@y.z minimal
  var objectRegularExpressionEmailFormat     = /\^[\\w-_\\.]\+\\@[\\w-_]\+(\\.[\\w-_]\+)\+\$/;

  // The password must contain at least 1 number, at least 1 lower case letter, and at least 1 upper case letter.
  var objectRegularExpressionPasswordFormat  = /\^[\\w|\\W]*(?=[\\w|\\W]*\\d)(?=[\\w|\\W]*[a-z])(?=[\\w|\\W]\*[A-Z])[\\w|\\W]*\$/;

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
      alert('Please enter new password!');
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
      alert('Please enter new password!');
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
      alert('Please re-enter passwords: Both new passwords are not equal!');
      return false;
    } else {
      document.users.password.value = hex_md5(document.users.password1.value);
    }
  }
  
  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="users" onSubmit="return validateForm();">
  <input type="hidden" name="pagedir"    value="$pagedir">
  <input type="hidden" name="pageset"    value="$pageset">
  <input type="hidden" name="debug"      value="$debug">
  <input type="hidden" name="CGISESSID"  value="$sessionID">
  <input type="hidden" name="action"     value="$nextAction">
  <input type="hidden" name="catalogID"  value="$CcatalogID">
  <input type="hidden" name="remoteUser" value="$CremoteUser">
  <input type="hidden" name="password"   value="$Cpassword">
HTML
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<br>\n";
    }

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td><table border="0" cellspacing="0" cellpadding="0">
HTML

    if ($action eq 'editView') {
      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td><b>Catalog ID: </b></td><td>
      <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled>
    </td></tr>
    <tr><td><b>Remote User: </b></td><td>
      <input type="text" name="remoteUser" value="$CremoteUser" size="15" maxlength="15" disabled>
    </td></tr><tr><td>Remote Address: </td><td>
      <input type="text" name="remoteAddr" value="$CremoteAddr" size="15" maxlength="15" disabled>&nbsp;&nbsp;format: x.[x.[x.[x]]]
    </td></tr><tr><td>Remote Netmask: </td><td>
      <input type="text" name="remoteNetmask" value="$CremoteNetmask" size="2" maxlength="2" disabled>&nbsp;&nbsp;format: 01-32
    </td></tr><tr><td>&nbsp;</td><td>
      <table width="100%">
        <tr><td><font color="#0000FF">32</font> 255.255.255.255</td><td><font color="#0000FF">31</font> 255.255.255.254</td><td><font color="#0000FF">30</font> 255.255.255.252</td><td><font color="#0000FF">29</font> 255.255.255.248</td><td><font color="#0000FF">28</font> 255.255.255.240</td><td><font color="#0000FF">27</font> 255.255.255.224</td><td><font color="#0000FF">26</font> 255.255.255.192</td><td><font color="#0000FF">25</font> 255.255.255.128</td></tr>
        <tr><td><font color="#0000FF">24</font> 255.255.255.0</td><td><font color="#0000FF">23</font> 255.255.254.0</td><td><font color="#0000FF">22</font> 255.255.252.0</td><td><font color="#0000FF">21</font> 255.255.248.0</td><td><font color="#0000FF">20</font> 255.255.240.0</td><td><font color="#0000FF">19</font> 255.255.224.0</td><td><font color="#0000FF">18</font> 255.255.192.0</td><td><font color="#0000FF">17</font> 255.255.128.0</td></tr>
        <tr><td><font color="#0000FF">16</font> 255.255.0.0</td><td><font color="#0000FF">15</font> 255.254.0.0</td><td><font color="#0000FF">14</font> 255.252.0.0</td><td><font color="#0000FF">13</font> 255.248.0.0</td><td><font color="#0000FF">12</font> 255.240.0.0</td><td><font color="#0000FF">11</font> 255.224.0.0</td><td><font color="#0000FF">10</font> 255.192.0.0</td><td><font color="#0000FF">09</font> 255.128.0.0</td></tr>
        <tr><td><font color="#0000FF">08</font> 255.0.0.0</td><td><font color="#0000FF">07</font> 254.0.0.0</td><td><font color="#0000FF">06</font> 252.0.0.0</td><td><font color="#0000FF">05</font> 248.0.0.0</td><td><font color="#0000FF">04</font> 224.0.0.0</td><td><font color="#0000FF">03</font> 240.0.0.0</td><td><font color="#0000FF">02</font> 192.0.0.0</td><td><font color="#0000FF">01</font> 128.0.0.0</td></tr>
      </table>
    </td></tr><tr><td><b>Given Name: </b></td><td>
      <input type="text" name="givenName" value="$CgivenName" size="50" maxlength="50">
    </td></tr><tr><td><b>Surname: </b></td><td>
      <input type="text" name="familyName" value="$CfamilyName" size="50" maxlength="50">
    </td></tr><tr><td><b>Email: </b></td><td>
      <input type="text" name="email" value="$Cemail" size="64" maxlength="64">
    </td></tr><tr><td><b>New password: </b></td><td>
      <input type="password" name="password1" value="$Cpassword" size="15" maxlength="15">&nbsp;&nbsp;The password must contain at least 1 number, at least 1 lower case letter, and at least 1 upper case letter.
    </td></tr><tr><td><b>Confirm password: </b></td><td>
      <input type="password" name="password2" value="$Cpassword" size="15" maxlength="15">&nbsp;&nbsp;The password must contain at least 1 number, at least 1 lower case letter, and at least 1 upper case letter.
    </td></tr><tr><td><b>Language: </b></td><td>
      $keyLanguageSelect
    </td></tr><tr><td>&nbsp;</td><td>
      <br>Please enter all required information before committing the required information. Required fields are marked in bold.
    </td></tr><tr align="left"><td align="right">
      <br><input type="submit" value="$submitButton"></td><td><br><input type="reset" value="Reset">
    </td></tr>
HTML

    } else {
      print "    <tr><td align=\"center\"><h1>Remote User: $htmlTitle</h1></td></tr>";
    }

    print "  </table>\n  </td></tr></table>\n";

    if ($action eq 'editView') {
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

