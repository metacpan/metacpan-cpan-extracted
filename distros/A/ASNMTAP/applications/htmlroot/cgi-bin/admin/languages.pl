#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, languages.pl for ASNMTAP::Asnmtap::Applications::CGI
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

$PROGNAME       = "languages.pl";
my $prgtext     = "Languages";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir         = (defined $cgi->param('pagedir'))        ? $cgi->param('pagedir')        : '<NIHIL>'; $pagedir =~ s/\+/ /g;
my $pageset         = (defined $cgi->param('pageset'))        ? $cgi->param('pageset')        : 'admin';   $pageset =~ s/\+/ /g;
my $debug           = (defined $cgi->param('debug'))          ? $cgi->param('debug')          : 'F';
my $pageNo          = (defined $cgi->param('pageNo'))         ? $cgi->param('pageNo')         : 1;
my $pageOffset      = (defined $cgi->param('pageOffset'))     ? $cgi->param('pageOffset')     : 0;
my $orderBy         = (defined $cgi->param('orderBy'))        ? $cgi->param('orderBy')        : 'languageName';
my $action          = (defined $cgi->param('action'))         ? $cgi->param('action')         : 'listView';
my $CkeyLanguage    = (defined $cgi->param('keyLanguage'))    ? $cgi->param('keyLanguage')    : '';
my $ClanguageName   = (defined $cgi->param('languageName'))   ? $cgi->param('languageName')   : '';
my $ClanguageFamily = (defined $cgi->param('languageFamily')) ? $cgi->param('languageFamily') : '';
my $ClanguageActive = (defined $cgi->param('languageActive')) ? $cgi->param('languageActive') : 'off';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($rv, $dbh, $sth, $sql, $header, $numberRecordsIntoQuery, $nextAction, $formDisabledAll, $formDisabledPrimaryKey, $submitButton);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'admin', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Languages", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&pageNo=$pageNo&pageOffset=$pageOffset&orderBy=$orderBy&action=$action&keyLanguage=$CkeyLanguage&languageName=$ClanguageName&languageFamily=$ClanguageFamily&languageActive=$ClanguageActive";

# Debug information
print "<pre>pagedir       : $pagedir<br>pageset       : $pageset<br>debug         : $debug<br>CGISESSID     : $sessionID<br>page no       : $pageNo<br>page offset   : $pageOffset<br>order by      : $orderBy<br>action        : $action<br>unique key    : $CkeyLanguage<br>name          : $ClanguageName<br>family        : $ClanguageFamily<br>active        : $ClanguageActive<br>URL ...       : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($matchingLanguages, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;pageNo=$pageNo&amp;pageOffset=$pageOffset";

  # open connection to database and query data
  $rv  = 1;

  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADWRITE:$SERVERPORTREADWRITE", "$SERVERUSERREADWRITE", "$SERVERPASSREADWRITE" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $formDisabledAll = $formDisabledPrimaryKey = '';

    if ($action eq 'duplicateView' or $action eq 'insertView') {
      $htmlTitle    = "Insert Language";
      $submitButton = "Insert";
      $nextAction   = "insert" if ($rv);
    } elsif ($action eq 'insert') {
      $htmlTitle    = "Check if Language $CkeyLanguage exist before to insert";

      $sql = "select keyLanguage from $SERVERTABLLANGUAGE WHERE keyLanguage='$CkeyLanguage'";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ( $numberRecordsIntoQuery ) {
        $htmlTitle    = "Language $CkeyLanguage exist already";
        $nextAction   = "insertView";
      } else {
        $htmlTitle    = "Language $CkeyLanguage inserted";
        my $dummyLanguageActive = ($ClanguageActive eq 'on') ? 1 : 0;

        $sql = 'INSERT INTO ' .$SERVERTABLLANGUAGE. ' SET keyLanguage="' .$CkeyLanguage. '", languageName="' .$ClanguageName. '", languageFamily="' .$ClanguageFamily. '", languageActive="' .$dummyLanguageActive. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
      }
    } elsif ($action eq 'deleteView') {
      $formDisabledAll = $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Delete Language $CkeyLanguage";
      $submitButton = "Delete";
      $nextAction   = "delete" if ($rv);
    } elsif ($action eq 'delete') {
      $sql = "select remoteUser, email from $SERVERTABLUSERS where keyLanguage = '$CkeyLanguage' order by email, remoteUser";
      ($rv, $matchingLanguages) = check_record_exist ($rv, $dbh, $sql, 'Users', 'Remote User', 'Email', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

	  if ($matchingLanguages eq '') {
        $htmlTitle = "Language $CkeyLanguage deleted";
        $sql = 'DELETE FROM ' .$SERVERTABLLANGUAGE. ' WHERE keyLanguage="' .$CkeyLanguage. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction = "listView" if ($rv);
      } else {
        $htmlTitle = "Language $CkeyLanguage not deleted, still used by";
      }
    } elsif ($action eq 'displayView') {
      $formDisabledAll = $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Display language $CkeyLanguage";
      $nextAction   = "listView" if ($rv);
    } elsif ($action eq 'editView') {
      $formDisabledPrimaryKey = 'disabled';
      $htmlTitle    = "Edit language $CkeyLanguage";
      $submitButton = "Edit";
      $nextAction   = "edit" if ($rv);
    } elsif ($action eq 'edit') {
      $matchingLanguages = '';
      my $dummyLanguageActive = ($ClanguageActive eq 'on') ? 1 : 0;

      unless ( $dummyLanguageActive ) {
        $sql = "select remoteUser, email from $SERVERTABLUSERS where keyLanguage = '$CkeyLanguage'";
        ($rv, $matchingLanguages) = check_record_exist ($rv, $dbh, $sql, 'Users', 'Remote User', 'Email', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      }

	  if ($dummyLanguageActive or $matchingLanguages eq '') {
        $sql = 'UPDATE ' .$SERVERTABLLANGUAGE. ' SET keyLanguage="' .$CkeyLanguage. '", languageName="' .$ClanguageName. '", languageFamily="' .$ClanguageFamily. '", languageActive="' .$dummyLanguageActive. '" WHERE keyLanguage="' .$CkeyLanguage. '"';
        $dbh->do ( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->do: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $nextAction   = "listView" if ($rv);
        $htmlTitle    = "Language $CkeyLanguage updated";
      } else {
        $htmlTitle    = "Language $CkeyLanguage not deactivated and updated, still used by";
      }
    } elsif ($action eq 'listView') {
      $htmlTitle    = "All languages listed";

      $sql = "select SQL_NO_CACHE count(keyLanguage) from $SERVERTABLLANGUAGE";
      ($rv, $numberRecordsIntoQuery) = do_action_DBI ($rv, $dbh, $sql, $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);
      $navigationBar = record_navigation_bar ($pageNo, $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView&amp;orderBy=$orderBy");
 
      $navigationBar .= record_navigation_bar_alpha ($rv, $dbh, $SERVERTABLLANGUAGE, 'languageName', "'1'", $numberRecordsIntoQuery, $RECORDSONPAGE, $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;action=listView", $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select keyLanguage, languageName, languageFamily, languageActive from $SERVERTABLLANGUAGE order by $orderBy limit $pageOffset, $RECORDSONPAGE";
      $header = "<th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=keyLanguage desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Key Language <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=keyLanguage asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=languageName desc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Language Name <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=languageName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=languageFamily desc, languageName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Language Family <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=languageFamily asc, languageName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th><th><a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=languageActive desc, languageName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Activated <a href=\"$urlWithAccessParameters&amp;action=listView&amp;orderBy=languageActive asc, languageName asc\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th>";
      ($rv, $matchingLanguages, $nextAction) = record_navigation_table ($rv, $dbh, $sql, 'Language', 'keyLanguage', '0', '', '', '', $orderBy, $header, $navigationBar, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $nextAction, $pagedir, $pageset, $pageNo, $pageOffset, $htmlTitle, $subTitle, $sessionID, $debug);
    }

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView') {
      $sql = "select keyLanguage, languageName, languageFamily, languageActive from $SERVERTABLLANGUAGE where keyLanguage = '$CkeyLanguage'";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      if ( $rv ) {
        ($CkeyLanguage, $ClanguageName, $ClanguageFamily, $ClanguageActive) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
        $ClanguageActive = ($ClanguageActive == 1) ? 'on' : 'off';
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

  if ( document.languages.keyLanguage.value == null || document.languages.keyLanguage.value == '' ) {
    document.languages.keyLanguage.focus();
    alert('Please enter a language key!');
    return false;
  }

  if ( document.languages.languageName.value == null || document.languages.languageName.value == '' ) {
    document.languages.languageName.focus();
    alert('Please enter a language name!');
    return false;
  }

  if ( document.languages.languageFamily.value == null || document.languages.languageFamily.value == '' ) {
    document.languages.languageFamily.focus();
    alert('Please enter a language family!');
    return false;
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="languages" onSubmit="return validateForm();">
HTML
    } elsif ($action eq 'deleteView') {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
      print "<form action=\"" . $ENV{SCRIPT_NAME} . "\" method=\"post\" name=\"languages\">\n";
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

    print "  <input type=\"hidden\" name=\"keyLanguage\"   value=\"$CkeyLanguage\">\n" if ($formDisabledPrimaryKey ne '' and $action ne 'displayView');

    print <<HTML;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
HTML

    if ( $iconAdd ) {
      print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=insertView&amp;orderBy=$orderBy">[Insert language]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
HTML
    }

    print <<HTML;
        <td class="StatusItem"><a href="$urlWithAccessParameters&amp;action=listView&amp;orderBy=$orderBy">[List all languages]</a></td>
      </tr></table>
    </td></tr>
HTML

    if ($action eq 'deleteView' or $action eq 'displayView' or $action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView') {
      my $languageActiveChecked = ($ClanguageActive eq 'on') ? ' checked' : '';

      print <<HTML;
    <tr><td>&nbsp;</td></tr>
    <tr><td>
	  <table border="0" cellspacing="0" cellpadding="0">
        <tr><td><b>Key Language: </b></td><td>
          <input type="text" name="keyLanguage" value="$CkeyLanguage" size="2" maxlength="2" $formDisabledPrimaryKey>
        </td></tr>
		<tr><td><b>Language Name: </b></td><td>
          <input type="text" name="languageName" value="$ClanguageName" size="16" maxlength="16" $formDisabledAll>
        </td></tr>
		<tr><td><b>Language Family: </b></td><td>
          <input type="text" name="languageFamily" value="$ClanguageFamily" size="24" maxlength="24" $formDisabledAll>
        </td></tr>
		<tr><td><b>Activated: </b></td><td>
          <input type="checkbox" name="languageActive" $languageActiveChecked $formDisabledAll>
        </td></tr>
HTML

      print "        <tr><td>&nbsp;</td><td><br>Please enter all required information before committing the required information. Required fields are marked in bold.</td></tr>\n" if ($action eq 'duplicateView' or $action eq 'editView' or $action eq 'insertView');
      print "        <tr align=\"left\"><td align=\"right\"><br><input type=\"submit\" value=\"$submitButton\"></td><td><br><input type=\"reset\" value=\"Reset\"></td></tr>\n" if ($action ne 'displayView');
      print "      </table>\n";
    } elsif ($action eq 'delete' or $action eq 'edit' or $action eq 'insert') {
      print "    <tr><td align=\"center\"><br><br><h1>Language: $htmlTitle</h1></td></tr>";
      print "    <tr><td align=\"center\">$matchingLanguages</td></tr>" if (defined $matchingLanguages and $matchingLanguages ne '');
    } else {
      print "    <tr><td align=\"center\"><br>$matchingLanguages</td></tr>";
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

