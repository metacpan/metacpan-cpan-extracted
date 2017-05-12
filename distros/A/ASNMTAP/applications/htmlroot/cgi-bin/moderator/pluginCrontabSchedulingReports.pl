#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, pluginCrontabSchedulingReports.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MODERATOR :REPORTS :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "pluginCrontabSchedulingReports.pl";
my $prgtext     = "Plugin Crontab Scheduling Reports";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1]);
my $currentSec = 0;

# URL Access Parameters
my $cgi = new CGI;
my $pagedir          = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : 'index';    $pagedir =~ s/\+/ /g;
my $pageset          = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : 'index-cv'; $pageset =~ s/\+/ /g;
my $debug            = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : 'F';
my $CcatalogID       = (defined $cgi->param('catalogID'))       ? $cgi->param('catalogID')       : $CATALOGID;
my $CcatalogIDreload = (defined $cgi->param('catalogIDreload')) ? $cgi->param('catalogIDreload') : 0;
my $CuKey            = (defined $cgi->param('uKey'))            ? $cgi->param('uKey')            : '';
my $width            = (defined $cgi->param('width'))           ? $cgi->param('width')           : 1000;
my $xOffset          = (defined $cgi->param('xOffset'))         ? $cgi->param('xOffset')         : 48;
my $yOffset          = (defined $cgi->param('yOffset'))         ? $cgi->param('yOffset')         : 42;
my $labelOffset      = (defined $cgi->param('labelOffset'))     ? $cgi->param('labelOffset')     : 18;
my $AreaBOffset      = (defined $cgi->param('AreaBOffset'))     ? $cgi->param('AreaBOffset')     : 78;
my $hightMin         = (defined $cgi->param('hightMin'))        ? $cgi->param('hightMin')        : 195;
my $pf               = (defined $cgi->param('pf'))              ? $cgi->param('pf')              : 'off';
my $htmlToPdf        = (defined $cgi->param('htmlToPdf'))       ? $cgi->param('htmlToPdf')       : 0;

my $htmlTitle        = $prgtext;

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'moderator', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Crontabs", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&width=$width&xOffset=$xOffset&yOffset=$yOffset&labelOffset=$labelOffset&AreaBOffset=$AreaBOffset&hightMin=$hightMin&pf=$pf&htmlToPdf=$htmlToPdf";

# Debug information
print "<pre>pagedir    : $pagedir<br>pageset    : $pageset<br>debug      : $debug<br>CGISESSID  : $sessionID<br>catalog ID : $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br>width      : $width<br>xOffset    : $xOffset<br>yOffset    : $yOffset<br>labelOffset: $labelOffset<br>AreaBOffset: $AreaBOffset<br>hightMin   : $hightMin<br>pf         : $pf<br>htmlToPdf  : $htmlToPdf<br>URL ...    : $urlAccessParameters</pre>" if ( $debug eq 'T' );

unless ( defined $errorUserAccessControl ) {
  my ($rv, $dbh, $sth, $sql, $errorMessage, $catalogIDSelect, $uKeySelect, $nextAction);

  # open connection to database and query data
  $rv  = 1;
  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ( $dbh and $rv ) {
    $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
    ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

    my $hostname = '';
    (undef, undef, $hostname, undef) = split ( /\//, $ENV{HTTP_REFERER} ) if ( $ENV{HTTP_REFERER} );

    $sql = "select distinct $SERVERTABLPLUGINS.uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT, $SERVERTABLCRONTABS, $SERVERTABLCLLCTRDMNS, $SERVERTABLSERVERS where $SERVERTABLPLUGINS.catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.activated = '1' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment and $SERVERTABLPLUGINS.catalogID = $SERVERTABLCRONTABS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLCRONTABS.uKey and $SERVERTABLCRONTABS.activated = '1' and $SERVERTABLCRONTABS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLCRONTABS.collectorDaemon = $SERVERTABLCLLCTRDMNS.collectorDaemon and $SERVERTABLCLLCTRDMNS.activated = '1' and $SERVERTABLCLLCTRDMNS.catalogID = $SERVERTABLSERVERS.catalogID and $SERVERTABLCLLCTRDMNS.serverID = $SERVERTABLSERVERS.serverID and $SERVERTABLSERVERS.activated = 1". ($TYPEMONITORING eq 'central' ? '' : " and ($SERVERTABLSERVERS.masterFQDN = '$hostname' or $SERVERTABLSERVERS.slaveFQDN = '$hostname')") ." order by optionValueTitle";
    ($rv, $uKeySelect, $htmlTitle) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CuKey, 'uKey', 'none', '-Select-', '', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

    # Close database connection - - - - - - - - - - - - - - - - - - - - -
    $dbh->disconnect or $rv = error_trap_DBI("Sorry, the database was unable to disconnect", $debug, '', "", '', "", '', -1, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if ($htmlToPdf) {
      print <<EndOfHtml;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">  
<html>
<head>
  <title>$htmlTitle</title>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" href="$HTTPSURL/asnmtap.css">
</head>
<BODY>
<H1>$DEPARTMENT \@ $BUSINESS: '$APPLICATION' $prgtext</H1>
EndOfHtml
    } else {
      print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);

      my $dummy = ($pf eq 'on') ? ' checked' : '';
      my $printerFriendlyOutputBox = "<input type=\"checkbox\" name=\"pf\"$dummy> Printer friendly output\n";

      print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.crontabs.catalogIDreload.value = 1;
  document.crontabs.submit();
  return true;
}

function validateForm() {
  var objectRegularExpressionSqlPeriode = /\^(12|24|36|48|60|72|84|94)00\$/;

  if ( document.crontabs.sqlPeriode.value == null || document.crontabs.sqlPeriode.value == '' ) {
    document.crontabs.sqlPeriode.focus();
    alert('Please enter Periode!');
    return false;
  } else {
    if ( ! objectRegularExpressionSqlPeriode.test(document.crontabs.sqlPeriode.value) ) {
      document.crontabs.sqlPeriode.focus();
      alert('Please re-enter Periode (1200|2400|3600|4800|6000|7200|8400|9400): Bad Periode value!');
      return false;
    }
  }

  var objectRegularExpressionWidth = /\^(1[0-9][0-9][0-9])\$/;

  if ( document.crontabs.width.value == null || document.crontabs.width.value == '' ) {
    document.crontabs.width.focus();
    alert('Please enter Width!');
    return false;
  } else {
    if ( ! objectRegularExpressionWidth.test(document.crontabs.width.value) ) {
      document.crontabs.width.focus();
      alert('Please re-enter Width  (1000-1999): Bad Width value!');
      return false;
    }
  }

  var objectRegularExpressionXoffset = /\^([1-3][0-9][0-9])\$/;
  
  if ( document.crontabs.xOffset.value == null || document.crontabs.xOffset.value == '' ) {
    document.crontabs.xOffset.focus();
    alert('Please enter x Offset!');
    return false;
  } else {
    if ( ! objectRegularExpressionXoffset.test(document.crontabs.xOffset.value) ) {
      document.crontabs.xOffset.focus();
      alert('Please re-enter x Offset (100-399): Bad x Offset value !');
      return false;
    }
  }

  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="crontabs" onSubmit="return validateForm();">
  <input type="hidden" name="pagedir"         value="$pagedir">
  <input type="hidden" name="pageset"         value="$pageset">
  <input type="hidden" name="debug"           value="$debug">
  <input type="hidden" name="CGISESSID"       value="$sessionID">
  <input type="hidden" name="catalogIDreload" value="0">
  <table border="0">
    <tr><td><b>Catalog ID: </b></td><td>
      <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled> $catalogIDSelect
    </td></tr>
    <tr>
	  <td><b>Application: </b></td><td>$uKeySelect&nbsp;&nbsp;&nbsp;</td>
      <td>Width:</td><td><input name="width" type="text" value="$width" size="4" maxlength="4">&nbsp;&nbsp;&nbsp;</td>
      <td>x offset:</td><td><input name="xOffset" type="text" value="$xOffset" size="3" maxlength="3"></td>
    </tr>
    <tr align="left"><td>Options:</td><td colspan="5">$printerFriendlyOutputBox</td></tr>
    <tr align="left"><td align="right"><br>
      <input type="submit" value="Scheduling"></td><td colspan="5"><br><input type="reset" value="Reset">
    </td></tr>
  </table>
</form>
<hr>
HTML
    }

    if (defined $errorMessage) {
      print $errorMessage, "\n" ;
    } else {
      if (!$CcatalogIDreload and $CuKey and $CuKey ne 'none') {
        print "<br><center><img src=\"$HTTPSURL/cgi-bin/moderator/generatePluginCrontabSchedulingReport.pl?catalogID=$CcatalogID&amp;uKey=$CuKey&amp;".encode_html_entities('U', $urlAccessParameters)."\"></center>\n";
        print "<br><center><a href=\"$HTTPSURL/cgi-bin/htmlToPdf.pl?HTMLtoPDFprg=$HTMLTOPDFPRG&amp;HTMLtoPDFhow=$HTMLTOPDFHOW&amp;scriptname=", $ENV{SCRIPT_NAME}, "&amp;",encode_html_entities('U', $urlAccessParameters),"\" target=\"_blank\">[Generate PDF file]</a></center>\n" if ((! defined $errorMessage) and ($HTMLTOPDFPRG ne '<nihil>' and $HTMLTOPDFHOW ne '<nihil>') and (! $htmlToPdf));
      } else {
        print "<br>There is no Application selected<br>\n";
      }
    }

    print '<BR>', "\n";
  } 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
