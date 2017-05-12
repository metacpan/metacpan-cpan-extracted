#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, getArchivedReport.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;
use Date::Calc qw(Add_Delta_Days Monday_of_Week Week_of_Year);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MEMBER :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "getArchivedReport.pl";
my $prgtext     = "Get Archived Report";
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
my $day              = (defined $cgi->param('day'))             ? $cgi->param('day')             : 'off';
my $week             = (defined $cgi->param('week'))            ? $cgi->param('week')            : 'off';
my $month            = (defined $cgi->param('month'))           ? $cgi->param('month')           : 'off';
my $quarter          = (defined $cgi->param('quarter'))         ? $cgi->param('quarter')         : 'off';
my $year             = (defined $cgi->param('year'))            ? $cgi->param('year')            : 'off';

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

my $htmlTitle   = "Get Archived Report(s) from $CcatalogID";

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Report Archive", "catalogID=$CcatalogID&uKey=$uKey");

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&uKey=$uKey&ascending=$ascending&day=$day&week=$week&month=$month&quarter=$quarter&year=$year";

# Debug information
print "<pre>pagedir   : $pagedir<br>pageset   : $pageset<br>debug     : $debug<br>CGISESSID : $sessionID<br>catalog ID: $CcatalogID<br>catalog ID reload : $CcatalogIDreload<br>uKey      : $uKey<br>ascending : $ascending<br>day       : $day<br>week      : $week<br>month     : $month<br>quarter   : $quarter<br>year      : $year<br>URL ...   : $urlAccessParameters</pre>" if ( $debug eq 'T' );

unless ( defined $errorUserAccessControl ) {
  unless ( defined $userType ) {
    print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', 'F', '', $sessionID);
    print "<br>\n<table WIDTH=\"100%\" border=0><tr><td class=\"HelpPluginFilename\">\n<font size=\"+1\">$errorUserAccessControl</font>\n</td></tr></table>\n<br>\n";
  } else {
    my ($rv, $dbh, $sth, $sql, $title, $resultsdir, $catalogIDSelect, $uKeySelect, $reportsSelect, %timeperiods);

    # open connection to database and query data
    $rv  = 1;
    $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY", ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

    if ( $dbh and $rv ) {
      $uKey = '<NIHIL>' if ( $CcatalogIDreload );

      $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
      ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      $sql = "select distinct $SERVERTABLPLUGINS.uKey, concat( LTRIM(SUBSTRING_INDEX($SERVERTABLPLUGINS.title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle from $SERVERTABLREPORTS, $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where $SERVERTABLREPORTS.catalogID = '$CcatalogID' and $SERVERTABLREPORTS.activated = 1 and $SERVERTABLPLUGINS.catalogID = $SERVERTABLREPORTS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLREPORTS.uKey and $SERVERTABLPLUGINS.environment = '$environment' and $SERVERTABLPLUGINS.pagedir REGEXP '/$pageDir/' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by optionValueTitle";
      ($rv, $uKeySelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $uKey, 'uKey', '', '', '', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

      if ($uKey ne '<NIHIL>') {
        $sql = "select concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ), resultsdir from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where catalogID = '$CcatalogID' and uKey = '$uKey' and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          ($title, $resultsdir) = $sth->fetchrow_array() or $rv = error_trap_DBI(*STDOUT, "Cannot $sth->fetchrow_array: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if ($sth->rows);
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        }

        $sql = "select $SERVERTABLREPORTS.id, $SERVERTABLTIMEPERIODS.timeperiodName from $SERVERTABLREPORTS, $SERVERTABLTIMEPERIODS where $SERVERTABLREPORTS.catalogID = '$CcatalogID' and $SERVERTABLREPORTS.uKey = '$uKey' and $SERVERTABLREPORTS.catalogID = $SERVERTABLTIMEPERIODS.catalogID and $SERVERTABLREPORTS.timeperiodID = $SERVERTABLTIMEPERIODS.timeperiodID";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          while (my $ref = $sth->fetchrow_hashref()) { $timeperiods{ $ref->{id} } = $ref->{timeperiodName}; }
          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        }
      }

      # Close database connection - - - - - - - - - - - - - - - - - - - - -
      $dbh->disconnect or $rv = error_trap_DBI("Sorry, the database was unable to disconnect", $debug, '', "", '', "", '', -1, '', $sessionID);
    }

    if ($rv) {
      if (defined $resultsdir) {
        my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;catalogID=$CcatalogID&amp;uKey=$uKey&amp;day=$day&amp;week=$week&amp;month=$month&amp;quarter=$quarter&amp;year=$year";
        $reportsSelect = "  <table align=\"center\" border=0 cellpadding=1 cellspacing=1 bgcolor='$COLORSTABLE{TABLE}'>\n    <tr><th colspan=\"4\"><a href=\"$urlWithAccessParameters&amp;ascending=0\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{up}\" ALT=\"Up\" BORDER=0></a> Report <a href=\"$urlWithAccessParameters&amp;ascending=1\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{down}\" ALT=\"Down\" BORDER=0></a></th></tr>";

        my $rvOpendir = opendir(REPORTS, "$RESULTSPATH/$resultsdir/$REPORTDIR/");

        if ($rvOpendir) {
          my @archivedReportFiles = readdir(REPORTS);
          closedir(REPORTS);

          if ($ascending) {
            @archivedReportFiles = sort { lc($a) cmp lc($b) } @archivedReportFiles; # alphabetical sort ascending
          } else {
            @archivedReportFiles = sort { lc($b) cmp lc($a) } @archivedReportFiles; # alphabetical sort descending
          }

          my $noGeneratedReports = 1;

          foreach my $archivedReportFile (@archivedReportFiles) {
            my $catalogID_uKey = ( ( $CcatalogID eq 'CID' ) ? '' : $CcatalogID .'_' ) . $uKey;

            if ($archivedReportFile =~ /.pdf$/ and $archivedReportFile =~ /-$catalogID_uKey-/) {
              my $reportYear  = substr($archivedReportFile, 0, 4);
		  	      my $reportMonth = substr($archivedReportFile, 4, 2);
			        my $reportDay   = substr($archivedReportFile, 6, 2);

              my ($reportPeriode, $reportDate);

              if ( $day eq 'on' and $archivedReportFile =~ /-Day_(\w+)-id_(\d+)/ ) {
                $reportPeriode = "$1";
		  	        $reportDate    = "$reportYear/$reportMonth/$reportDay";
			        } elsif ( $week eq 'on' and $archivedReportFile =~ /-Week_(\d+)-id_(\d+)/ ) {
                $reportYear-- if ( $1 == 53 and ((localtime)[5] + 1900) == $reportYear );
                ($reportYear, my $f_month, my $f_day) = Monday_of_Week($1, $reportYear);
                my ($t_year, $t_month, $t_day) = Add_Delta_Days($reportYear, $f_month, $f_day, 6);
                $reportPeriode = "Week: $1";
                $f_month = sprintf ("%02d", $f_month);
                $f_day   = sprintf ("%02d", $f_day);
                $t_month = sprintf ("%02d", $t_month);
                $t_day   = sprintf ("%02d", $t_day);
			          $reportDate    = "from $reportYear/$f_month/$f_day until $t_year/$t_month/$t_day";
              } elsif ( $month eq 'on' and $archivedReportFile =~ /-Month_(\w+)-id_(\d+)/ ) {
                $reportPeriode = "Month: $1";
                $reportDate    = $reportYear;
		  	      } elsif ( $quarter eq 'on' and $archivedReportFile =~ /-Quarter_(\d+)-id_(\d+)/ ) {
                $reportPeriode = "Quarter: $1";
                $reportDate    = $reportYear;
              } elsif ( $year eq 'on' and $archivedReportFile =~ /-Year_(\d+)-id_(\d+)/ ) {
                $reportPeriode = "Year: $1";
                $reportDate    = "&nbsp;";
              }

              if (defined $reportPeriode) {
                $reportsSelect .= "\n    <tr><td><a href=\"$RESULTSURL/$resultsdir/$REPORTDIR/$archivedReportFile\" target=\"_blank\">$reportPeriode</a></td><td> - ". ( defined $timeperiods{ $2 } ? $timeperiods{ $2 } : 'UNDEF' ) ."</td><td>- id $2 -</td><td>$reportDate</td></tr>";
                $noGeneratedReports = 0;
              }
            }
          }

          $reportsSelect .= "\n    <tr><td>For this period there are no generated report(s) for '" .encode_html_entities('T', $title). "'</td></tr>" if ($noGeneratedReports);
        }

        $reportsSelect .= "\n  </table>";
      } else {
        $reportsSelect = "<h1>Contact the administrator, maybe no reports defined</h1><br>" if ($uKey ne '<NIHIL>');
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

      my $checkboxDay     = "<input type=\"checkbox\" name=\"day\"" .(($day eq 'on') ? ' checked' : ''). "> Daily";
      my $checkboxWeek    = "<input type=\"checkbox\" name=\"week\"" .(($week eq 'on') ? ' checked' : ''). "> Weekly";
      my $checkboxMonth   = "<input type=\"checkbox\" name=\"month\"" .(($month eq 'on') ? ' checked' : ''). "> Monthly";
      my $checkboxQuarter = "<input type=\"checkbox\" name=\"quarter\"" .(($quarter eq 'on') ? ' checked' : ''). "> Quarterly";
      my $checkboxYear    = "<input type=\"checkbox\" name=\"year\"" .(($year eq 'on') ? ' checked' : ''). "> Yearly";
	  
      print <<EndOfHtml;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.getArchivedReport.catalogIDreload.value = 1;
  document.getArchivedReport.submit();
  return true;
}
</script>
  <BR>
  <form action="$ENV{SCRIPT_NAME}" method="post" name="getArchivedReport">
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
	  <tr align="left"><td>Periode:</td><td>$checkboxDay $checkboxWeek $checkboxMonth $checkboxQuarter $checkboxYear</td></tr>
      <tr align="left"><td align="right"><br><input type="submit" value="Go"></td><td><br><input type="reset" value="Reset"></td></tr>
    </table>
  </form>
  <HR>
EndOfHtml

      if (defined $reportsSelect) {
        print "<br>$reportsSelect";
      } else {
        print "<br>Select application from the 'Archived Report Directory'.<br>";
      }
    }

    print '<BR>', "\n";
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
