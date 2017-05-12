#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, trendlineCorrectionReports.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.002.003;
use ASNMTAP::Time qw(&get_epoch);

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MODERATOR :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "trendlineCorrectionReports.pl";
my $prgtext     = "Trendline Correction Reports (for the Collector)";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir          = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : '<NIHIL>';   $pagedir =~ s/\+/ /g;
my $pageset          = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : 'moderator'; $pageset =~ s/\+/ /g;
my $debug            = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : 'F';
my $action           = (defined $cgi->param('action'))          ? $cgi->param('action')          : 'listView';
my $CcatalogID       = (defined $cgi->param('catalogID'))       ? $cgi->param('catalogID')       : $CATALOGID;
my $CcatalogIDreload = (defined $cgi->param('catalogIDreload')) ? $cgi->param('catalogIDreload') : 0;
my $CsessionID       = (defined $cgi->param('sessionID'))       ? $cgi->param('sessionID')       : '';
my $shortlist        = (defined $cgi->param('shortlist'))       ? $cgi->param('shortlist')       : 1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# Init parameters
my ($nextAction, $matchingTrendlineCorrections);

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'moderator', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Trendlines", undef);

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&sessionID=$CsessionID&shortlist=$shortlist&catalogID=$CcatalogID";

# Debug information
print "<pre>pagedir     : $pagedir<br>pageset     : $pageset<br>debug       : $debug<br>CGISESSID   : $sessionID<br>action      : $action<br>catalog ID  : $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br>session ID  : $CsessionID<br>shortlist   : $shortlist<br>URL ...     : $urlAccessParameters</pre>" if ( $debug eq 'T' );

if ( defined $sessionID and ! defined $errorUserAccessControl ) {
  my ($catalogIDSelect, $matchingSessionDetails, $matchingSessionsBlocked, $matchingSessionsActive, $matchingSessionsExpired, $matchingSessionsEmpty, $navigationBar);

  my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;catalogID=$CcatalogID";

  if ($action eq 'listView') {
    $htmlTitle = "Trendline Correction Reports";

    my ($rv, $dbh, $sth, $sql);
    $rv = 1;

    # open connection to database and query data
    $dbh = DBI->connect("DBI:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

    if ( $dbh and $rv ) {
      my $startDateEpoch = get_epoch ('-14 days');
      my $startDate = sprintf ( "%04d-%02d-%02d", (localtime($startDateEpoch))[5]+1900, (localtime($startDateEpoch))[4]+1, (localtime($startDateEpoch))[3] );

      my $yesterdayEpoch = get_epoch ('yesterday');
      my $yesterday = sprintf ( "%04d-%02d-%02d", (localtime($yesterdayEpoch))[5]+1900, (localtime($yesterdayEpoch))[4]+1, (localtime($yesterdayEpoch))[3] );

      my $actionPressend = ($iconDetails or $iconEdit) ? 1 : 0;
      my $actionHeader = ($actionPressend) ? "<th>Action</th>" : '';
      my $colspan = 10 + $actionPressend;
      my $header = "<tr><th> Catalog ID </th><th> Title </th><th> uKey </th><th> Trendline </th><th> - </th><th> Average </th><th> % </th><th> + </th><th> % </th><th> Proposal </th>$actionHeader</tr>\n";

      my $hostname = '';
      (undef, undef, $hostname, undef) = split ( /\//, $ENV{HTTP_REFERER} ) if ( $ENV{HTTP_REFERER} );

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      my ($catalogID, $uKey, $title, $test, $resultsdir, $trendline, $percentage, $tolerance, $hour, $calculated);
      $sql = "select SQL_NO_CACHE $SERVERTABLPLUGINS.catalogID, $SERVERTABLPLUGINS.uKey, concat( LTRIM(SUBSTRING_INDEX($SERVERTABLPLUGINS.title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as Title, $SERVERTABLPLUGINS.test, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLPLUGINS.trendline, $SERVERTABLPLUGINS.percentage, $SERVERTABLPLUGINS.tolerance, hour($SERVERTABLEVENTS.startTime) as hour, round(avg(time_to_sec($SERVERTABLEVENTS.duration)), 2) from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT, $SERVERTABLEVENTS, $SERVERTABLCRONTABS, $SERVERTABLCLLCTRDMNS, $SERVERTABLSERVERS where $SERVERTABLPLUGINS.catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.trendline <> 0 and $SERVERTABLPLUGINS.catalogID = $SERVERTABLEVENTS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLEVENTS.uKey and ($SERVERTABLEVENTS.startDate between '$startDate' and '$yesterday') and hour($SERVERTABLEVENTS.startTime) between 9 and 17 and $SERVERTABLEVENTS.status = 'OK' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment and $SERVERTABLPLUGINS.catalogID = $SERVERTABLCRONTABS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLCRONTABS.uKey and $SERVERTABLCRONTABS.activated = '1' and $SERVERTABLCRONTABS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLCRONTABS.collectorDaemon = $SERVERTABLCLLCTRDMNS.collectorDaemon and $SERVERTABLCLLCTRDMNS.activated = '1' and $SERVERTABLCLLCTRDMNS.catalogID = $SERVERTABLSERVERS.catalogID and $SERVERTABLCLLCTRDMNS.serverID = $SERVERTABLSERVERS.serverID and $SERVERTABLSERVERS.activated = 1". ($TYPEMONITORING eq 'central' ? '' : " and ($SERVERTABLSERVERS.masterFQDN = '$hostname' or $SERVERTABLSERVERS.slaveFQDN = '$hostname')") ." group by $SERVERTABLPLUGINS.title, $SERVERTABLPLUGINS.catalogID, $SERVERTABLPLUGINS.uKey, hour order by catalogID, Title";
      $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
      $sth->bind_columns( \$catalogID, \$uKey, \$title, \$test, \$resultsdir, \$trendline, \$percentage, \$tolerance, \$hour, \$calculated ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

      $matchingTrendlineCorrections .= '<table width="100%" border="0" cellspacing="1" cellpadding="1" bgcolor="'. $COLORSTABLE{TABLE} .'"><tr><th align="center" colspan="'. $colspan .'"> Trendline > 0 </th></tr>'. $header;

      if ( $rv ) {
        sub matchingTrendlineCorrections {
          my ($catalogID, $uKey, $title, $test, $resultsdir, $trendline, $percentage, $tolerance, $calculated) = @_;

          use POSIX qw(ceil floor);

          my ($calculatedMIN, $calculatedMAX, $calculatedNEW, $ActionItem);
          $calculated = sprintf("%.2f", $calculated * ( 100 + $percentage ) / 100 );

          if ( $tolerance ) {
            $calculatedMIN = sprintf("%.2f", $calculated * ( 100 - $tolerance  ) / 100 );
            $calculatedMAX = sprintf("%.2f", $calculated * ( 100 + $tolerance  ) / 100 );

            $calculatedNEW = $trendline >= $calculatedMIN && $trendline <= $calculatedMAX ? 0 : ( $calculatedMAX > $trendline ? ceil( $calculatedMAX ) : ( floor( ($calculatedMAX + $trendline) / 2 ) < $calculatedMAX ? ceil( ($calculatedMAX + $trendline) / 2 ) : floor( ($calculatedMAX + $trendline) / 2 ) ) );
            $calculatedNEW = '' if ( $calculatedNEW == 0 or $calculatedNEW == $trendline );
          } else {
            $calculatedMIN = $calculatedMAX = $calculatedNEW = '';
          }

          $ActionItem = ( $actionPressend and $calculatedNEW ) ? 1 : '';

          if ( $ActionItem or ! $shortlist ) {
            $test =~ s/\.pl//g;
            my $catalogID_uKey = ( ( $catalogID eq 'CID' ) ? '' : $catalogID .'_' ) . $uKey;
            $ActionItem  = "&nbsp";
            $ActionItem .= "<A HREF=\"#\" onclick=\"openPngImage('/results/$resultsdir/$test-$catalogID_uKey-sql.html',912,576,null,null,'Trendline',10,false,'Trendline');\"><img src=\"$IMAGESURL/$ICONSRECORD{table}\" title=\"Trendline MRTG Chart\" alt=\"Trendline MRTG Chart\" border=\"0\"></A>&nbsp;" if ($catalogID eq $CATALOGID);
            $ActionItem .= "<A HREF=\"#\" onclick=\"openPngImage('$HTTPSURL/cgi-bin/generateChart.pl?$urlAccessParameters&detailed=on&catalogID=$CcatalogID&uKey1=$uKey&uKey2=none&uKey3=none&startDate=$startDate&endDate=$yesterday&inputType=fromto&chart=Bar',1016,400,null,null,'Bar',10,false,'Bar');\"><img src=\"$IMAGESURL/$ICONSRECORD{table}\" title=\"Trendline Bar Chart\" alt=\"Trendline Bar Chart\" border=\"0\"></A>&nbsp;";

            my $actionSkip = ( ( $catalogID eq $CATALOGID ) ? 0 : 1 );

            unless ( $actionSkip ) {
              if ( $userType >= 2 ) {
                $ActionItem .= "&nbsp;<A HREF=\"#\" onclick=\"openPngImage('$HTTPSURL/cgi-bin/". ( ( $userType == 2 ) ? 'moderator' : 'admin' ) ."/plugins.pl?$urlAccessParameters&action=editView&catalogID=$CcatalogID&uKey=$uKey&orderBy=uKey',1016,760,null,null,'Edit',10,false,'Edit');\"><img src=\"$IMAGESURL/$ICONSRECORD{edit}\" title=\"Edit Trendline\" alt=\"Edit Trendline\" border=\"0\"></A>&nbsp;";

                if ( $calculatedNEW ) {
                  $ActionItem .= "<A HREF=\"#\">";
                  $ActionItem .= ( $calculatedNEW > $trendline ? "<IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" title=\"Update Trendline\" ALT=\"Update Trendline\" BORDER=0>" : "<IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" title=\"Update Trendline\" ALT=\"Update Trendline\" BORDER=0>" );
                  $ActionItem .= "<img src=\"$IMAGESURL/$ICONSRECORD{query}\" title=\"Update Trendline\" alt=\"Update Trendline\" border=\"0\">" if ( $userType >= 4 );
                  $ActionItem .= "</A>&nbsp;" if ( $userType >= 4 );
                }
              }
            }

            $matchingTrendlineCorrections .= "<tr bgcolor=\"$COLORSTABLE{STARTBLOCK}\"><td>$catalogID</td><td>$title</td><td>$uKey</td><td align=\"right\" bgcolor=\"#0F0F0F\">&nbsp;$trendline&nbsp;</td><td align=\"right\" bgcolor=\"#335566\">&nbsp;$calculatedMIN&nbsp;</td><td align=\"right\" bgcolor=\"#0F0F0F\">&nbsp;$calculated&nbsp;</td><td align=\"right\" bgcolor=\"#0F0F0F\">&nbsp;$percentage&nbsp;</td><td align=\"right\" bgcolor=\"#335566\">&nbsp;$calculatedMAX&nbsp;</td><td align=\"right\" bgcolor=\"#335566\">&nbsp;$tolerance&nbsp;</td><td align=\"right\" bgcolor=\"#000000\">&nbsp;<b>$calculatedNEW</b>&nbsp;</td><td bgcolor=\"#335566\">$ActionItem</td></tr>\n";
          }
        }

        my ($groupEND, $groupMAX, $catalogIDPREV, $uKeyPREV, $titlePREV, $testPREV, $resultsdirPREV, $trendlinePREV, $percentagePREV, $tolerancePREV) = (0, 0, 0, 0, 0, 25, 5);

        if ( $sth->rows ) {
		  while( $sth->fetch() ) {
            $groupEND = ( $uKeyPREV ne '0' and $uKeyPREV ne $uKey ) ? 1 : 0;

            if ( $groupEND ) {
              matchingTrendlineCorrections ($catalogIDPREV, $uKeyPREV, $titlePREV, $testPREV, $resultsdirPREV, $trendlinePREV, $percentagePREV, $tolerancePREV, $groupMAX);
              $groupMAX = $calculated;
            } else {
              $groupMAX = $calculated > $groupMAX ? $calculated : $groupMAX;
            }

            $catalogIDPREV  = $catalogID;
            $uKeyPREV       = $uKey;
            $titlePREV      = $title;
            $testPREV       = $test;
            $resultsdirPREV = $resultsdir;
            $trendlinePREV  = $trendline;
            $percentagePREV = $percentage;
		    $tolerancePREV  = $tolerance;
          }

          matchingTrendlineCorrections ($catalogIDPREV, $uKeyPREV, $titlePREV, $testPREV, $resultsdirPREV, $trendlinePREV, $percentagePREV, $tolerancePREV, $groupMAX);
        }

        $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
      }

      unless ( $shortlist ) {
        $sql = "select $SERVERTABLPLUGINS.catalogID, $SERVERTABLPLUGINS.uKey, concat( LTRIM(SUBSTRING_INDEX($SERVERTABLPLUGINS.title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as Title, $SERVERTABLPLUGINS.test, $SERVERTABLPLUGINS.resultsdir, $SERVERTABLPLUGINS.trendline, $SERVERTABLPLUGINS.percentage, $SERVERTABLPLUGINS.tolerance, round(avg(time_to_sec($SERVERTABLEVENTS.duration)), 2) from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT, $SERVERTABLEVENTS, $SERVERTABLCRONTABS, $SERVERTABLCLLCTRDMNS, $SERVERTABLSERVERS where $SERVERTABLPLUGINS.catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.trendline = 0 and $SERVERTABLPLUGINS.catalogID = $SERVERTABLEVENTS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLEVENTS.uKey and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment and $SERVERTABLPLUGINS.catalogID = $SERVERTABLCRONTABS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLCRONTABS.uKey and $SERVERTABLCRONTABS.activated = '1' and $SERVERTABLCRONTABS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLCRONTABS.collectorDaemon = $SERVERTABLCLLCTRDMNS.collectorDaemon and $SERVERTABLCLLCTRDMNS.activated = '1' and $SERVERTABLCLLCTRDMNS.catalogID = $SERVERTABLSERVERS.catalogID and $SERVERTABLCLLCTRDMNS.serverID = $SERVERTABLSERVERS.serverID and $SERVERTABLSERVERS.activated = 1". ($TYPEMONITORING eq 'central' ? '' : " and ($SERVERTABLSERVERS.masterFQDN = '$hostname' or $SERVERTABLSERVERS.slaveFQDN = '$hostname')") ." group by $SERVERTABLPLUGINS.title, $SERVERTABLPLUGINS.catalogID, $SERVERTABLPLUGINS.uKey order by catalogID, Title";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;
        $sth->bind_columns( \$catalogID, \$uKey, \$title, \$test, \$resultsdir, \$trendline, \$percentage, \$tolerance, \$calculated ) or $rv = error_trap_DBI(*STDOUT, "Cannot sth->bind_columns: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        $matchingTrendlineCorrections .= '<tr><td '. $colspan .'">&nbsp</th></tr><tr><th align="center" colspan="'. $colspan .'"> Trendline = 0 </th></tr>'. $header;

        if ( $rv ) {
          if ( $sth->rows ) {
            while( $sth->fetch() ) {
              matchingTrendlineCorrections ($catalogID, $uKey, $title, $test, $resultsdir, $trendline, $percentage, $tolerance, $calculated);
            }
          }

          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        }
      }

      $matchingTrendlineCorrections .= '</table>';
      $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
    }

    $nextAction = "listView";
  }

  # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'T', '', $sessionID);

  print <<HTML;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.trendlineCorrectionReport.catalogIDreload.value = 1;
  document.trendlineCorrectionReport.submit();
  return true;
}
</script>

<form action="$ENV{SCRIPT_NAME}" method="post" name="trendlineCorrectionReport">
  <input type="hidden" name="pagedir"         value="$pagedir">
  <input type="hidden" name="pageset"         value="$pageset">
  <input type="hidden" name="debug"           value="$debug">
  <input type="hidden" name="CGISESSID"       value="$sessionID">
  <input type="hidden" name="action"          value="$nextAction">
  <input type="hidden" name="sessionID"       value="$CsessionID">
  <input type="hidden" name="shortlist"       value="$shortlist">
  <input type="hidden" name="catalogIDreload" value="0">
  <br>
  <table border="0" cellspacing="0" cellpadding="0" align="center">
    <tr><td><table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='#333344'><tr><td align=\"left\"><b>Catalog ID: </b></td><td>$catalogIDSelect</td></tr></table><br></td></tr>
    <tr align="center"><td>$matchingTrendlineCorrections</td></tr>
  </table>
  <br>
HTML
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
