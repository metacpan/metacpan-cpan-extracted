#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, runCmdOnDemand.pl for ASNMTAP::Asnmtap::Applications::CGI
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use CGI;
use Shell;
use Date::Calc qw(Delta_Days);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MEMBER :DBREADONLY :DBTABLES $PERLCOMMAND $SSHCOMMAND $SSHLOGONNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "runCmdOnDemand.pl";
my $prgtext     = "Run command on demand for the '$APPLICATION'";
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

my ($pageDir, $environment) = split (/\//, $pagedir, 2);
$environment = 'P' unless (defined $environment);

my $htmlTitle = $APPLICATION .' - '. $ENVIRONMENT{$environment};

my $selectF = ($debug eq 'F') ? "selected" : '';
my $selectT = ($debug eq 'T') ? "selected" : '';
my $selectL = ($debug eq 'L') ? "selected" : '';
my $selectM = ($debug eq 'M') ? "selected" : '';
my $selectA = ($debug eq 'A') ? "selected" : '';
my $selectS = ($debug eq 'S') ? "selected" : '';

my ($command, $FQDN, $typeActiveServer, $masterFQDN, $slaveFQDN) = ('', '');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'guest', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "On demand", "catalogID=$CcatalogID&uKey=$uKey");

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&catalogID=$CcatalogID&catalogIDreload=$CcatalogIDreload&uKey=$uKey";

unless ( defined $errorUserAccessControl ) {
  my ($rv, $dbh, $sth, $sql, $catalogIDSelect, $uKeySelect);

  $rv  = 1;
  $dbh = DBI->connect("dbi:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY", ) or $rv = error_trap_DBI(*STDOUT, "Cannot connect to the database", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);

  if ($dbh and $rv) {
    $sql = "select catalogID, catalogName from $SERVERTABLCATALOG where not catalogID = '$CATALOGID' and activated = '1' order by catalogName asc";
    ($rv, $catalogIDSelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $CcatalogID, 'catalogID', $CATALOGID, '-Parent-', '', 'onChange="javascript:submitForm();"', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

    $sql = "select uKey, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT where catalogID = '$CcatalogID' and ( $SERVERTABLPLUGINS.environment = '$environment' and pagedir REGEXP '/$pageDir/' and ondemand = '1' and activated = 1 ) and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment order by optionValueTitle";
    ($rv, $uKeySelect, undef) = create_combobox_from_DBI ($rv, $dbh, $sql, 1, '', $uKey, 'uKey', '', '', '', '', $pagedir, $pageset, $htmlTitle, $subTitle, $sessionID, $debug);

    if ( $rv ) {
      if ($uKey ne '<NIHIL>') {
        $sql = "select distinct test, $SERVERTABLPLUGINS.environment, $SERVERTABLPLUGINS.arguments, argumentsOndemand, concat( LTRIM(SUBSTRING_INDEX(title, ']', -1)), ' (', $SERVERTABLENVIRONMENT.label, ')' ) as optionValueTitle, trendline, typeActiveServer, masterFQDN, slaveFQDN from $SERVERTABLPLUGINS, $SERVERTABLENVIRONMENT, $SERVERTABLCRONTABS, $SERVERTABLCLLCTRDMNS, $SERVERTABLSERVERS where $SERVERTABLPLUGINS.catalogID = '$CcatalogID' and $SERVERTABLPLUGINS.uKey = '$uKey'  and $SERVERTABLPLUGINS.environment = $SERVERTABLENVIRONMENT.environment and $SERVERTABLPLUGINS.catalogID = $SERVERTABLCRONTABS.catalogID and $SERVERTABLPLUGINS.uKey = $SERVERTABLCRONTABS.uKey and $SERVERTABLCRONTABS.catalogID = $SERVERTABLCLLCTRDMNS.catalogID and $SERVERTABLCRONTABS.collectorDaemon = $SERVERTABLCLLCTRDMNS.collectorDaemon and $SERVERTABLCLLCTRDMNS.catalogID = $SERVERTABLSERVERS.catalogID and $SERVERTABLCLLCTRDMNS.serverID = $SERVERTABLSERVERS.serverID";
        $sth = $dbh->prepare( $sql ) or $rv = error_trap_DBI(*STDOUT, "Cannot dbh->prepare: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        $sth->execute() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->execute: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID) if $rv;

        if ( $rv ) {
          my ($dCommand, $environment, $arguments, $argumentsOndemand, $title, $trendline, $typeActiveServer, $masterFQDN, $slaveFQDN) = $sth->fetchrow_array();
          $command = $dCommand;
          $FQDN = (($typeActiveServer eq 'M') ? $masterFQDN : $slaveFQDN);
        # ($FQDN, undef) = split (/\./, $FQDN, 2);
          if ($environment ne '') { $command .= " --environment=" . $environment; }
          if ($arguments ne '') { $command .= " " . $arguments; }
          if ($argumentsOndemand ne '') { $command .= " " . $argumentsOndemand; }
          if (int($trendline) > 0) { $command .= " --trendline=" . $trendline; }
          $htmlTitle = 'Results for '. $title .' from '. $CcatalogID ." launched on $FQDN (?= $RUNCMDONDEMAND)";

          $sth->finish() or $rv = error_trap_DBI(*STDOUT, "Cannot sth->finish: $sql", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
        }
      }
    }

    $dbh->disconnect or $rv = error_trap_DBI(*STDOUT, "Sorry, the database was unable to add your entry.", $debug, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, '', $sessionID);
  }

  if ( $rv ) {
    # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    my $onload = ($uKey ne '<NIHIL>') ? "ONLOAD=\"if (document.images) document.Progress.src='".$IMAGESURL."/spacer.gif';\"" : '';
    print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, $onload, 'F', '', $sessionID);

    print <<EndOfHtml;
<script language="JavaScript1.2" type="text/javascript">
function submitForm() {
  document.runCmdOnDemand.catalogIDreload.value = 1;
  document.runCmdOnDemand.submit();
  return true;
}
</script>
  <BR>
  <form action="$ENV{SCRIPT_NAME}" method="post" name="runCmdOnDemand">
    <input type="hidden" name="pagedir"         value="$pagedir">
    <input type="hidden" name="pageset"         value="$pageset">
    <input type="hidden" name="CGISESSID"       value="$sessionID">
    <input type="hidden" name="catalogIDreload" value="0">
    <table border=0>
      <tr><td><b>Catalog ID: </b></td><td>
        <input type="text" name="catalogID" value="$CcatalogID" size="5" maxlength="5" disabled>
        $catalogIDSelect
      </td></tr>
	  <tr align="left"><td>Application:</td><td>$uKeySelect</td></tr>
	  <tr align="left"><td>Debug:</td><td>
        <select name="debug">
          <option value="F" $selectF>False</option>
          <option value="T" $selectT>True</option>
          <option value="L" $selectL>Long</option>
EndOfHtml

    print "<option value=\"M\" $selectM>Moderator</option>" if ($userType >= 2 );
    print "<option value=\"A\" $selectA>Admin</option>" if ($userType >= 4 );
    print "<option value=\"S\" $selectS>Server Admin</option>" if ($userType == 8 );

    print <<EndOfHtml;
        </select>
      </td></tr>
      <tr align="left"><td align="right"><br><input type="submit" value="Launch"></td><td><br><input type="reset" value="Reset"></td></tr>
    </table>
  </form>
  <HR>
EndOfHtml

    if (!$CcatalogIDreload and $uKey ne '<NIHIL>') {
      my $commandMaskedPassword = maskPassword ($command);
      print "<P class=\"RunCmdOnDemandHtmlTitle\">$htmlTitle:<br> <font class=\"RunCmdOnDemandCommand\">$commandMaskedPassword --onDemand=Y --debug=$debug --asnmtapEnv='F|F|F'</font></P><IMG SRC=\"".$IMAGESURL."/gears.gif\" HSPACE=\"0\" VSPACE=\"0\" BORDER=\"0\" NAME=\"Progress\" title=\"Please Wait ...\" alt=\"Please Wait ...\"><table width=\"100%\">";
      my ($capture_long, $capture_html, $capture_text, $capture_debug, $capture_array, @WebTransactResponses, @capture_array);
      $capture_long = $capture_html = $capture_text = $capture_debug = $capture_array = 0;

    # my $capture_exec = ( $RUNCMDONDEMAND eq 'probe' ) ? "$SSHCOMMAND -i '$SSHKEYPATH/$SSHLOGONNAME/.ssh/asnmtap.id' -o 'StrictHostKeyChecking=no' $SSHLOGONNAME\@$FQDN \"if [ -d /opt/monitoring/asnmtap/plugins/ ]; then cd /opt/monitoring/asnmtap/plugins/; else cd /opt/asnmtap/plugins/; fi; PATH=/opt/csw/bin:/opt/local/bin PERL5LIB=/opt/monitoring/lib/perl5:/opt/monitoring/lib/perl5/site_perl LD_LIBRARY_PATH=/opt/csw/lib:/usr/local/lib ./$command --onDemand=Y --debug=$debug --asnmtapEnv='F|F|F' 2>&1\"" : "cd $PLUGINPATH; $PERLCOMMAND $command --onDemand=Y --debug=$debug --asnmtapEnv='F|F|F' 2>&1";
      my $capture_exec = ( $RUNCMDONDEMAND eq 'probe' ) ? "$SSHCOMMAND -i '$SSHKEYPATH/$SSHLOGONNAME/asnmtap.id' -o 'StrictHostKeyChecking=no' $SSHLOGONNAME\@$FQDN \"if [ -d /opt/monitoring/asnmtap/plugins/ ]; then cd /opt/monitoring/asnmtap/plugins/; else cd /opt/asnmtap/plugins/; fi; PATH=/opt/monitoring/sbin:/opt/monitoring/bin:/opt/mysql/mysql/bin/:/usr/local/sbin:/usr/local/bin:/opt/csw/sbin:/opt/csw/bin:/usr/sbin:/usr/bin PERL5LIB=/opt/monitoring/lib/perl5:/opt/monitoring/lib/perl5/site_perl LD_LIBRARY_PATH=/opt/csw/mysql5/lib/mysql:/opt/csw/share/perl/5.8.8/unicore/lib:/opt/csw/sparc-sun-solaris2.8/lib:/opt/csw/lib:/usr/local/ssl/lib:/opt/mysql/mysql/lib:/usr/local/lib/mysql:/usr/local/lib:/usr/lib ./$command --onDemand=Y --debug=$debug --asnmtapEnv='F|F|F' 2>&1\"" : "cd $PLUGINPATH; $PERLCOMMAND $command --onDemand=Y --debug=$debug --asnmtapEnv='F|F|F' 2>&1";

      if ( 1 == 1 ) {
        @capture_array = `$capture_exec`;
      } else {
        my ($stdout, $stderr, $exit_value, $signal_num, $dumped_core);

        if ($CAPTUREOUTPUT) {
          use IO::CaptureOutput qw(capture_exec);
          ($stdout, $stderr) = capture_exec("$capture_exec");
        } else {
          system ("$capture_exec"); $stdout = $stderr = '';
        }

        $exit_value  = $? >> 8;
        $signal_num  = $? & 127;
        $dumped_core = $? & 128;
        @capture_array = split (/\n/, $stdout);
        print "< $capture_exec >< $exit_value >< $signal_num >< $dumped_core >< $stdout >< $stderr >\n" if ($debug eq 'S');
      }

      for (; $capture_array < @capture_array -1; $capture_array++) {
        my $capture = $capture_array[$capture_array];
        $capture =~ s/\r$//g;
        $capture =~ s/\n$//g;

        if ( $capture =~ /^--> URL: (?:GET|POST)/ ) {
          $capture_long = $capture_html = $capture_text = $capture_debug = 0;
          print "<tr><th class=\"RunCmdOnDemandCaptureHeader\">$capture</th></tr>\n";
        } elsif ( $capture =~ /LWP::UserAgent::request: Simple response:/ ) {
          $capture_long = 1;
          print "<tr><td class=\"RunCmdOnDemandCaptureTrue\">$capture</td></tr>\n<tr><td class=\"RunCmdOnDemandCaptureLong\">";
        } elsif ( ! $capture_html and $capture =~ /<HTML|<!DOCTYPE HTML PUBLIC/i ) {
          $capture_html = 1;
          print "</td></tr><tr><td class=\"RunCmdOnDemandCaptureHtml\">$capture\n";
        } elsif ( $capture =~ /<\/HTML>/i ) {
          $capture_html = 0;
          print "$capture\n</td></tr>\n";
        } elsif ( ! $capture_text and $capture =~ /^scan_socket_info :|^<!---Start debug:-->/ ) {
          $capture_text = 1;
          print "</td></tr><tr><td class=\"RunCmdOnDemandCaptureTrue\"><pre>$capture\n";
        } elsif ( ! $capture_debug and $capture =~ /^Start time   :|^Status       :/ ) {
          $capture_debug = 1;
          print "</td></tr><tr><td class=\"RunCmdOnDemandCaptureDebug\"><pre>$capture\n";
        } elsif ($capture =~ /WebTransact::response_time: /) {
          push (@WebTransactResponses, $capture);
        } elsif ($capture =~ /WebTransact::timing_tries: /) {
          push (@WebTransactResponses, $capture);
        } elsif ($capture ne '') {
          if ($capture_debug) {
            print "$capture\n";
          } elsif ($capture_text) {
            print "$capture\n";
          } elsif ($capture_html) {
            $capture =~ s/(window.location.href)/\/\/$1/gi;

            # RFC 1738 -> [ $\/:;=?@.\-!*'()\w&+,]+
            $capture =~ s/(<META\s+HTTP-EQUIV\s*=\s*\"Refresh\"\s+CONTENT\s*=\s*\"\d+;\s*URL\s*=[^"]+\"(?:\s+\/?)?>)/<!--$1-->/img;

            # remove password from Basic Authentication URL before putting into database!
            $capture =~ s/(http[s]?)\:\/\/(\w+)\:(\w+)\@/$1\:\/\/$2\:********\@/img;

            # comment <SCRIPT></SCRIPT>
            $capture =~ s/<SCRIPT/<!--<SCRIPT/gi;
            $capture =~ s/<\/SCRIPT>/<\/SCRIPT>-->/gi;

            # replace <BODY onload="..."> with <BODY>
            $capture =~ s/<BODY\s*onload\s*=\s*.*\s*>/<BODY>/gi;

            print "$capture\n";
          } elsif ($capture_long) {
            print "$capture<br>\n";
          } else {
            print "<tr><td class=\"RunCmdOnDemandCaptureTrue\">$capture</td></tr>\n";
	      }
  	    }
      }

      foreach my $WebTransactResponses (@WebTransactResponses) {
        print "</td></tr><tr><td class=\"RunCmdOnDemandCaptureTime\">$WebTransactResponses\n";
      }

      print "<tr><td>&nbsp;</td></tr>\n" if ($capture_array == 0);
      my ($status, undef) = split(/ - /, $capture_array[$capture_array], 2);
      $status = ( $status =~ /(^OK|^WARNING|^CRITICAL|^UNKNOWN|^DEPENDENT|^OFFLINE|^NO TEST)/ ) ? $1 : 'UNKNOWN';
      print '</table><br><IMG SRC="', $IMAGESURL, '/', $ICONS{$status}, '" ALT="$status" WIDTH="16" HEIGHT="16" BORDER=0 ALIGN="middle"> ', encode_html_entities('M', $capture_array[$capture_array]), "<br>";
    } else {
      print "<br>Select application for immediate launch.<br>";
    }
  }

  print '<BR>', "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub maskPassword {
  my ($parameters) =  @_;

  # --dnPass=
  if ($parameters =~ /--dnPass=/) {
    $parameters =~ s/(--dnPass=)\w+/$1********/g;
  }

  # --proxy=user:pasword\@proxy
  if ($parameters =~ /--proxy=/) {
    $parameters =~ s/(--proxy=\w*:)\w*(\@\w+)/$1********$2/g;
  }

  # -p user:pasword\@proxy
  if ($parameters =~ /-p / and ($parameters !~ /-u / and $parameters !~ /--username=/)) {
    $parameters =~ s/(-p \w*:)\w*(\@\w+)/$1********$2/g;
  }

  # --password=
  if ($parameters =~ /--password=/) {
    $parameters =~ s/(--password=)\w+/$1********/g;
  }

  # --username= or -u and --password= or -p (database plugins)
  if ($parameters =~ /-p / and ($parameters =~ /-u / or $parameters =~ /--username=/)) {
    $parameters =~ s/(-p )\w+/$1********/g;
  }

  # --username= or -U and --password= or -P (ftp plugins)
  if ($parameters =~ /-P / and ($parameters =~ /-U / or $parameters =~ /--username=/)) {
    $parameters =~ s/(-P )\w+/$1********/g;
  }

  # j_username= or j_password= (J2EE based Applications)
  if ($parameters =~ /j_username=/ and $parameters =~ /j_password=/) {
    $parameters =~ s/(j_password=)\w+/$1********/g;
  }

  return ($parameters);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
