#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, getArchivedDebug.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MEMBER :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "getArchivedDebug.pl";
my $prgtext     = "Get Archived Debug";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $CcatalogID       = (defined $cgi->param('catalogID'))       ? $cgi->param('catalogID')       : $CATALOGID;
my $CcatalogIDreload = (defined $cgi->param('catalogIDreload')) ? $cgi->param('catalogIDreload') : 0;
my $uKey             = (defined $cgi->param('uKey'))            ? $cgi->param('uKey')            : '<NIHIL>';  $uKey    =~ s/\+/ /g;
my $pagedir          = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : 'index';    $pagedir =~ s/\+/ /g;
my $pageset          = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : 'index-cv'; $pageset =~ s/\+/ /g;
my $debug            = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : 'F';
my $ascending        = (defined $cgi->param('ascending'))       ? $cgi->param('ascending')       : 0;
my $archived         = (defined $cgi->param('archived'))        ? $cgi->param('archived')        : 'off';

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

my $htmlTitle   = "Get Archived Debug Report(s) from $CcatalogID";

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'member', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Debug Archive", "catalogID=$CcatalogID&uKey=$uKey");

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&uKey=$uKey&ascending=$ascending";

# Debug information
print "<pre>pagedir   : $pagedir<br>pageset   : $pageset<br>debug     : $debug<br>CGISESSID : $sessionID<br>catalog ID: $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br>uKey      : $uKey<br>ascending : $ascending<br>URL ...   : $urlAccessParameters</pre>" if ( $debug eq 'T' );

unless ( defined $errorUserAccessControl ) {
  unless ( defined $userType ) {
    print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    print "<br>\n<table WIDTH=\"100%\" border=0><tr><td class=\"HelpPluginFilename\">\n<font size=\"+1\">$errorUserAccessControl</font>\n</td></tr></table>\n<br>\n";
  } else {
    my ($rv, $dbh, $sth, $sql, $title, $resultsdir, $catalogIDSelect, $uKeySelect, $debugsSelect);

    # open connection to database and query data
    $rv  = 1;
    $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY", ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

    if ( $dbh and $rv ) {
      $uKey = '<NIHIL>' if ( $CcatalogIDreload );

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select distinct $SERVERTABLPLUGINS.uKey, concat( LTRIM(SUBSTRING_INDEX($SERVERTABLPLUGINS.title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where $SERVERTABLPLUGINS.catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.environment = '$environment' and $SERVERTABLPLUGINS.pagedir REGEXP '/$pageDir/' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by optionValueTitle";
      ($rv, $uKeySelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $uKey, 'uKey', '', '', '', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      if ($uKey ne '<NIHIL>') {
        $sql = "select concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ), resultsdir from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where catalogID = '$CcatalogID' and uKey = '$uKey' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          ($title, $resultsdir) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        } 
      }

      # Close database connection - - - - - - - - - - - - - - - - - - - - -
      $dbh->disconnect or $rv = error_trap_DBI("Sorry, the database was unable to disconnect", $debug, '', "", '', "", '', -1, '', $sessionID);
    }

    if ($rv) {
      if (defined $resultsdir) {
        my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;catalogID=$CcatalogID&amp;uKey=$uKey&amp;archived=$archived";
        $debugsSelect = "  <table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='$COLORSTABLE{TABLE}'>\n    <tr><th colspan=\"2\"><a href=\"$urlWithAccessParameters&amp;ascending=0\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Debug Report <a href=\"$urlWithAccessParameters&amp;ascending=1\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th></tr>";

        my $rvOpendir = opendir(DEBUGS, "$RESULTSPATH/$resultsdir/$DEBUGDIR/");

        if ($rvOpendir) {
          my @archivedDebugFiles = readdir(DEBUGS);
          closedir(DEBUGS);

          if ($ascending) {
            @archivedDebugFiles = sort { lc($a) cmp lc($b) } @archivedDebugFiles; # alphabetical sort ascending
          } else {
            @archivedDebugFiles = sort { lc($b) cmp lc($a) } @archivedDebugFiles; # alphabetical sort descending
          }

          my $noGeneratedDebugs = 1;
          my $suffix = ($archived eq 'on') ? '.gz' : '';

          foreach my $archivedDebugFile (@archivedDebugFiles) {
            my $catalogID_uKey = ( ( $CcatalogID eq 'CID' ) ? '' : $CcatalogID .'_' ) . $uKey;

            if ($archivedDebugFile =~ /.htm$suffix$/ and $archivedDebugFile =~ /-$catalogID_uKey-/) {
              my $debugYear  = substr($archivedDebugFile, 0, 4);
  		      my $debugMonth = substr($archivedDebugFile, 4, 2);
			  my $debugDay   = substr($archivedDebugFile, 6, 2);
              my $debugDate  = "$debugYear/$debugMonth/$debugDay";

              my $debugHour  = substr($archivedDebugFile,  8, 2);
              my $debugMin   = substr($archivedDebugFile, 10, 2);
              my $debugSec   = substr($archivedDebugFile, 12, 2);
              my $debugTime  = "$debugHour:$debugMin:$debugSec";

              $debugsSelect .= "\n    <tr><td><a href=\"$RESULTSURL/$resultsdir/$DEBUGDIR/$archivedDebugFile\" target=\"_blank\">$debugDate</a></td><td>$debugTime</td></tr>";
              $noGeneratedDebugs = 0;
            }
          }

          $debugsSelect .= "\n    <tr><td>For this period there are no generated debug report(s) for '" .encode_html_entities('T', $title). "'</td></tr>" if ($noGeneratedDebugs);
        }

        $debugsSelect .= "\n  </table>";
      } else {
        $debugsSelect = "<h1>Contact the administrator, maybe no debug reports generated</h1><br>" if ($uKey ne '<NIHIL>');
      }

      # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      my $onload = ($uKey ne '<NIHIL>') ? "ONLOAD=\"if (document.images) document.Progress.src='".$IMAGESURL."/spacer.gif';\"" : '';
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, $onload, 'F', '', $sessionID);
      my $urlWithAccessParameters = "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;catalogID=$CcatalogID";

      if ( $userType >= 1 ) {
        print <<EndOfHtml;
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
    <tr align="center"><td>
	  <table border="0" cellspacing="0" cellpadding="0"><tr>
        <td class="StatusItem"><a href="getArchivedReport.pl$urlWithAccessParameters">[List report archive]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="getArchivedDebug.pl$urlWithAccessParameters">[List debug archive]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="getArchivedDisplays.pl$urlWithAccessParameters">[List display archive]</a></td>
        <td class="StatusItem">&nbsp;&nbsp;&nbsp;</td>
        <td class="StatusItem"><a href="getArchivedResults.pl$urlWithAccessParameters">[List results archive]</a></td>
	  </tr></table>
	</td></tr>
  </table>
EndOfHtml
      }

      my $checkboxArchived  = "<input type=\"checkbox\" name=\"archived\"" .(($archived eq 'on') ? ' checked' : ''). "> Archived";
	  
      print <<EndOfHtml;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.getArchivedDebug.catalogIDreload.value = 1;
  document.getArchivedDebug.submit();
  return true;
}
</script>
  <BR>
  <form action="$ENV{SCRIPT_NAME}" method="post" name="getArchivedDebug">
    <input type="hidden" name="pagedir"         value="$pagedir">
    <input type="hidden" name="pageset"         value="$pageset">
    <input type="hidden" name="debug"           value="$debug">
    <input type="hidden" name="CGISESSID"       value="$sessionID">
    <input type="hidden" name="ascending"       value="$ascending">
    <input type="hidden" name="catalogIDreload" value="0">
    <table border=0>
      <tr><td><b>Catalog ID: </b></td><td>
        <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled> $catalogIDSelect
      </td></tr>
	  <tr align="left"><td>Application:</td><td>$uKeySelect</td></tr>
	  <tr align="left"><td>Periode:</td><td>$checkboxArchived</td></tr>
      <tr align="left"><td align="right"><br><input type="submit" value="Go"></td><td><br><input type="reset" value="Reset"></td></tr>
    </table>
  </form>
  <HR>
EndOfHtml

      if (defined $debugsSelect) {
        print "<br>$debugsSelect";
      } else {
        print "<br>Select application from the 'Archived Debug Directory'.<br>";
      }
    }

    print '<BR>', "\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
