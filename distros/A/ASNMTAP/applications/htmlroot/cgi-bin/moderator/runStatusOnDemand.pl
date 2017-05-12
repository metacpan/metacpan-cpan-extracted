#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, runStatusOnDemand.pl for ASNMTAP::Asnmtap::Applications::CGI
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MODERATOR $PERLCOMMAND $SSHCOMMAND &call_system);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "runStatusOnDemand.pl";
my $prgtext     = "Run status Collector/Display on demand for the '$APPLICATION'";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;
use Shell;
use Date::Calc qw(Delta_Days);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# URL Access Parameters
my $cgi = new CGI;
my $pagedir    = (defined $cgi->param('pagedir'))   ? $cgi->param('pagedir')   : '<NIHIL>';   $pagedir =~ s/\+/ /g;
my $pageset    = (defined $cgi->param('pageset'))   ? $cgi->param('pageset')   : 'moderator'; $pageset =~ s/\+/ /g;
my $debug      = (defined $cgi->param('debug'))     ? $cgi->param('debug')     : 'F';
my $status     = (defined $cgi->param('status'))    ? $cgi->param('status')    : '<NIHIL>';   $status  =~ s/\+/ /g;
my $action     = (defined $cgi->param('action'))    ? $cgi->param('action')    : '<NIHIL>';
my $Cpid       = (defined $cgi->param('pid'))       ? $cgi->param('pid')       : -1;
my $Cppid      = (defined $cgi->param('ppid'))      ? $cgi->param('ppid')      : -1;
my $Ccommand   = (defined $cgi->param('command'))   ? $cgi->param('command')   : '<NIHIL>';

my $command    = '';

my $FORMATPSA  = "<tr><td class=\"%s\">%s %s %s %s %s %s %s %s</td><td class=\"%s\">%s</td></tr>\n";
my $FORMATPS   = "<tr><td colspan=\"2\" class=\"%s\">%s %s %s %s %s %s %s %s</td>\n";

my (%daemonProcessTableCmndline, %daemonProcessTablePctmem, %daemonProcessTableSize, %daemonProcessTableTtydev, %daemonProcessTableStart, %daemonProcessTableState) = ();

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $htmlTitle = $APPLICATION;

# User Session and Access Control
my ($sessionID, $iconAdd, $iconDelete, $iconDetails, $iconEdit, $iconQuery, $iconTable, $errorUserAccessControl, undef, undef, undef, undef, undef, undef, undef, $userType, undef, undef, undef, $subTitle) = user_session_and_access_control (1, 'moderator', $cgi, $pagedir, $pageset, $debug, $htmlTitle, "Status", "status=$status");

# Serialize the URL Access Parameters into a string
my $urlAccessParameters = "pagedir=$pagedir&pageset=$pageset&debug=$debug&CGISESSID=$sessionID&status=$status";

# Debug information
print "<pre>pagedir     : $pagedir<br>pageset     : $pageset<br>debug       : $debug<br>status      : $status<br>action      : $action<br>pid         : $Cpid<br>ppid        : $Cppid<br>command     : $Ccommand<br>URL ...     : $urlAccessParameters</pre>" if ( $debug eq 'T' );

my $urlWithAccessParameters = $ENV{SCRIPT_NAME} . "?pagedir=$pagedir&amp;pageset=$pageset&amp;debug=$debug&amp;CGISESSID=$sessionID&amp;status=$status";

unless ( defined $errorUserAccessControl ) {
  # 'Moderator' = 2, 'Administrator' = 4 & 'Server Administrator' = 8
  if ($userType >= 4) {
    ($iconAdd, $iconDelete, $iconDetails, $iconEdit) = (1, 1, 1, 1);
  } else {
    ($iconAdd, $iconDelete, $iconDetails, $iconEdit) = (0, 0, 0, 0);
  }

  my $typeStatusSelect = create_combobox_from_keys_and_values_pairs ('collector=>Collectors|display=>Displays|importDataThroughCatalog=>Import Data Through Catalog', 'K', 0, $status, 'status', 'none', '-Select-', '', '', $debug);

  # HTML  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  my $onload = ($status ne '<NIHIL>') ? "ONLOAD=\"if (document.images) document.Progress.src='".$IMAGESURL."/spacer.gif';\"" : '';
  print_header (*STDOUT, $pagedir, $pageset, $htmlTitle, $subTitle, 3600, $onload, 'F', '', $sessionID);

  print <<EndOfHtml;
  <BR>
  <form action="$ENV{SCRIPT_NAME}" name="params">
    <input type="hidden" name="pagedir"   value="$pagedir">
    <input type="hidden" name="pageset"   value="$pageset">
    <input type="hidden" name="CGISESSID" value="$sessionID">
    <input type="hidden" name="debug"     value="$debug">
    <table border=0>
	  <tr align="left"><td>Status:</td><td>$typeStatusSelect</td></tr>
      <tr align="left"><td align="right"><br><input type="submit" value="Launch"></td><td><br><input type="reset" value="Reset"></td></tr>
    </table>
  </form>
  <HR>
EndOfHtml

  if ($action eq 'kill') {
    doRequestedActions ($htmlTitle, "$Ccommand $Cpid", "$Ccommand $Cpid", "Process(es) killed.", "Process(es) not killed.", $debug);
  } elsif ($action =~ /^(?:start|stop|reload|restart)$/) {
    doRequestedActions ($htmlTitle, "script $Ccommand $action", "script $Ccommand $action", "$Ccommand ${action}ed.", "$Ccommand not ${action}ed.", $debug);
  } elsif ($action eq 'remove') {
    doRequestedActions ($htmlTitle, "remove $Ccommand", "remove $Ccommand", "$Ccommand removed.", "$Ccommand not removed.", $debug);
  } elsif ($status ne '<NIHIL>') {
    my $binMasterOrSlave = '<NIHIL>';

    if (-s "$APPLICATIONPATH/master/asnmtap-$status.sh") {
      $binMasterOrSlave = 'master';
    } elsif (-s "$APPLICATIONPATH/slave/asnmtap-$status.sh") {
      $binMasterOrSlave = 'slave';
    } elsif (-s "$APPLICATIONPATH/bin/asnmtap-$status.sh") {
      $binMasterOrSlave = 'bin';
    }

    if ($binMasterOrSlave ne '<NIHIL>') {
      my ($capture_array, $daemonCaptureHeader, $daemonCaptureStatus, $daemonCaptureParent);
      my (%daemonCaptureArrayName, %daemonCaptureArrayPid, %daemonCaptureArrayParent) = ();
      my (%daemonProcessTableParent, %daemonProcessTableChild, %daemonProcessTableSubChild) = ();

      $command = "asnmtap-$status.sh status";
      print "<P class=\"RunStatusOnDemandHtmlTitle\">$htmlTitle: <font class=\"RunStatusOnDemandCommand\">$APPLICATIONPATH/$binMasterOrSlave/$command</font></P><IMG SRC=\"".$IMAGESURL."/gears.gif\" HSPACE=\"0\" VSPACE=\"0\" BORDER=\"0\" NAME=\"Progress\" title=\"Please Wait ...\" alt=\"Please Wait ...\"><table width=\"100%\" bgcolor=\"#333344\" border=0>";

      my $_ppid = 1;

      if (-e '/usr/bin/zonename') { # Solaris 10 root into an non global zone where pid != 1 & pid == ppid 
        my $zonename = `/usr/bin/zonename`;

        if ( $zonename ne 'global' ) {
          $_ppid = `ps -e -o 'pid ppid zone fname' | grep zsched | awk '{print \$1}'`;
        }
      }

      my @capture_array = `cd $APPLICATIONPATH/$binMasterOrSlave; $PERLCOMMAND $command 2>&1`;

      use Proc::ProcessTable;
      my $tProcessTable = new Proc::ProcessTable;

      my $daemonPidStatus = ( ($status eq 'display') ? 'Display' : ( ($status eq 'collector') ? 'Collector' : 'importDataThroughCatalog' ) );

      my $prefix = ( ( $status eq 'importDataThroughCatalog' ) ? '' : 'CT-');

      my @daemonPidPathFilenames = glob("$PIDPATH/${daemonPidStatus}$prefix". ( $prefix eq '' ? '' : '*' ) ."\.pid");

      foreach my $daemonPidPathFilename (@daemonPidPathFilenames) {
        my $rvOpen = open(PID, "$daemonPidPathFilename");

        if ($rvOpen) {
          my $pid;
          while (<PID>) { chomp; $pid = $_; }
          close(PID);

          if ( $prefix eq '' ) {
            $daemonPidPathFilename =~ /^$PIDPATH\/(${daemonPidStatus})\.pid*/;
            $daemonCaptureArrayName {$1} = -1;
            $daemonCaptureArrayPid {$1}  = $pid;
          } else {
            $daemonPidPathFilename =~ /^$PIDPATH\/${daemonPidStatus}${prefix}([\w-]+)\.pid*/;
            $daemonCaptureArrayName {$1} = -1;
            $daemonCaptureArrayPid {$1}  = $pid;
          }
        }
      }

      for ($capture_array = 0; $capture_array < @capture_array; $capture_array++) {
        my $capture = $capture_array[$capture_array];
        chomp ($capture);
        $capture =~ s/^\s+//g;

        unless ( defined $daemonCaptureStatus ) {
          if ($capture =~ /^Status: 'All ASNMTAP (Collectors|Displays|Import Data Through Catalog)' ...$/) {
            $daemonCaptureHeader = $capture;
            $daemonCaptureStatus = ( ($1 eq 'Displays') ? 'display' : ( ($1 eq 'Collectors') ? 'collector' : 'importDataThroughCatalog' ) );
            $daemonCaptureParent = '';
          }
		} elsif ($capture =~ /^Status: '(?:Collector|Display|Import Data Through Catalog) ASNMTAP ([\w-]+)' is running$/) {
          $daemonCaptureParent = $1;
          $daemonCaptureArrayName {$1} = 1;
        } elsif ($capture =~ /^Status: '(?:Collector|Display|Import Data Through Catalog) ASNMTAP ([\w-]+)' is not running$/) {
          $daemonCaptureParent = '';
          $daemonCaptureArrayName {$1} = 0;
        } elsif ($capture =~ /\.\/$daemonCaptureStatus(?:-test)?\.pl/) {
          my (undef, $pid, $ppid, undef) = split (/\s+/, $capture, 4);

          if ($ppid == $_ppid and $daemonCaptureParent) {
            $daemonCaptureArrayName {$daemonCaptureParent} += 2;
            $daemonCaptureArrayPid {$daemonCaptureParent} = $pid;
            $daemonCaptureArrayParent {$pid} = 1;
          }
        }
      }

      if (defined $daemonCaptureHeader) {
        # pass 1 for the Parents
        foreach my $process ( @{$tProcessTable->table} ) {
          if ($process->ppid == $_ppid and $process->cmndline =~ /\.\/$daemonCaptureStatus(?:-test)?\.pl/) {
            $daemonProcessTableParent   {$process->pid} = (defined $daemonCaptureArrayParent {$process->pid}) ? 1 : 0;
            $daemonProcessTablePctmem   {$process->pid} = $process->pctmem;
            $daemonProcessTableSize     {$process->pid} = $process->size;
            $daemonProcessTableTtydev   {$process->pid} = $process->ttydev;
            $daemonProcessTableState    {$process->pid} = $process->state;
            $daemonProcessTableStart    {$process->pid} = $process->start;
            $daemonProcessTableCmndline {$process->pid} = $process->cmndline;
            delete $daemonCaptureArrayParent {$process->pid} if ($daemonProcessTableParent {$process->pid});
          }
        }

        # pass 2 for the Childs
        foreach my $process ( @{$tProcessTable->table} ) {
          if ($process->ppid != 1 and defined $daemonProcessTableParent {$process->ppid}) {
            $daemonProcessTableChild    {$process->pid} = $process->ppid;
            $daemonProcessTablePctmem   {$process->pid} = $process->pctmem;
            $daemonProcessTableSize     {$process->pid} = $process->size;
            $daemonProcessTableTtydev   {$process->pid} = $process->ttydev;
            $daemonProcessTableState    {$process->pid} = $process->state;
            $daemonProcessTableStart    {$process->pid} = $process->start;
            $daemonProcessTableCmndline {$process->pid} = $process->cmndline;
          }
        }

        # pass 3 for the SubChilds
        foreach my $process ( @{$tProcessTable->table} ) {
          if ($process->ppid != 1 and defined $daemonProcessTableChild {$process->ppid}) {
            $daemonProcessTableSubChild {$process->pid} = $process->ppid;
            $daemonProcessTablePctmem   {$process->pid} = $process->pctmem;
            $daemonProcessTableSize     {$process->pid} = $process->size;
            $daemonProcessTableTtydev   {$process->pid} = $process->ttydev;
            $daemonProcessTableState    {$process->pid} = $process->state;
            $daemonProcessTableStart    {$process->pid} = $process->start;
            $daemonProcessTableCmndline {$process->pid} = $process->cmndline;
          }
        }

        print "<tr><th colspan=\"2\" class=\"RunStatusOnDemandCaptureHeader\">$daemonCaptureHeader</th></tr>\n";

        while ( my ($daemon, $state) = each(%daemonCaptureArrayName) ) {
          if ($state == -1) {
            print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCaptureNotRunning\"><b>Daemon: '$daemonPidStatus ASNMTAP $daemon' not running but pid exists</b></td></tr>\n";
          } elsif ($state == 0) {
            print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCaptureNotRunning\"><b>Status: '$daemonPidStatus ASNMTAP $daemon' not running</b></td></tr>\n";
          } elsif ($state == 1) {
            print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCaptureNotRunning\"><b>Status: '$daemonPidStatus ASNMTAP $daemon' not running but pid exists</b></td></tr>\n";
          } elsif ($state == 2) {
            print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCaptureNotRunning\"><b>Daemon: '$daemonPidStatus ASNMTAP $daemon' not running</b></td></tr>\n";
          } elsif ($state == 3) {
            print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCaptureRunning\"><b>Daemon: '$daemonPidStatus ASNMTAP $daemon' running</b></td></tr>\n";
          } else {
            print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCaptureNotRunning\"><b>Daemon: '$daemonPidStatus ASNMTAP $daemon' running # $state</b></td></tr>\n";
          }

          my $urlPrefix = ( ( $prefix eq '' ) ? 'asnmtap-' : '');
          my $urlDaemon = ( ( $prefix eq '' ) ? '' : $prefix . $daemon);

          if ($state == 3 and defined $daemonCaptureArrayPid {$daemon}) {
            my $pidParent = $daemonCaptureArrayPid {$daemon};
            delete $daemonCaptureArrayPid {$daemon};

            if (defined $daemonProcessTableParent {$pidParent}) {
              my $cmndline = ($daemonProcessTableCmndline {$pidParent} =~ /(\.\/[\w-]+.pl)/) ? $1 . ' ...' : $daemonProcessTableCmndline {$pidParent};

              if ($iconAdd or $iconDelete or $iconDetails or $iconEdit ) {
                my $urlAction = '';
                $urlAction .= "<A HREF=\"$urlWithAccessParameters&amp;pid=$pidParent&amp;ppid=1&amp;command=$APPLICATIONPATH/$binMasterOrSlave/${urlPrefix}${daemonPidStatus}${urlDaemon}.sh&amp;action=reload\"><IMG SRC=\"$IMAGESURL/$ICONSSYSTEM{daemonReload}\" ALT=\"Reload\" BORDER=0></A>&nbsp;" if ($iconDetails);
                $urlAction .= "<A HREF=\"$urlWithAccessParameters&amp;pid=$pidParent&amp;ppid=1&amp;command=$APPLICATIONPATH/$binMasterOrSlave/${urlPrefix}${daemonPidStatus}${urlDaemon}.sh&amp;action=restart\"><IMG SRC=\"$IMAGESURL/$ICONSSYSTEM{daemonRestart}\" ALT=\"Restart\" BORDER=0></A>&nbsp;" if ($iconEdit);
                $urlAction .= "<A HREF=\"$urlWithAccessParameters&amp;pid=$pidParent&amp;ppid=1&amp;command=$APPLICATIONPATH/$binMasterOrSlave/${urlPrefix}${daemonPidStatus}${urlDaemon}.sh&amp;action=stop\"><IMG SRC=\"$IMAGESURL/$ICONSSYSTEM{daemonStop}\" ALT=\"Stop\" BORDER=0></A>" if ($iconDelete);
                printf($FORMATPSA, "RunStatusOnDemandCaptureParent", $pidParent, 1, $daemonProcessTablePctmem {$pidParent}, $daemonProcessTableSize {$pidParent}, $daemonProcessTableTtydev {$pidParent}, $daemonProcessTableState {$pidParent}, scalar(localtime($daemonProcessTableStart {$pidParent})), $cmndline, 'RunStatusOnDemandCaptureParentAction', $urlAction);
              } else {
                printf($FORMATPS, "RunStatusOnDemandCaptureParent", $pidParent, $daemonProcessTableParent {$pidParent}, $daemonProcessTablePctmem {$pidParent}, $daemonProcessTableSize {$pidParent}, $daemonProcessTableTtydev {$pidParent}, $daemonProcessTableState {$pidParent}, scalar(localtime($daemonProcessTableStart {$pidParent})), $cmndline);
              }
			  
              while ( my ($pidChild, $ppidChild) = each(%daemonProcessTableChild) ) {
                if ($ppidChild == $pidParent) {
                  my $cmndline = ($daemonProcessTableCmndline {$pidChild} =~ /^(sh -c cd \Q$PLUGINPATH\E; \.\/[\w-]+.pl)/) ? $1 . ' ...' : $daemonProcessTableCmndline {$pidChild};

                  if ($iconDelete) {
                    my $urlAction = "<A HREF=\"$urlWithAccessParameters&amp;pid=$pidChild&amp;ppid=$ppidChild&amp;command=killall&amp;action=kill\"><IMG SRC=\"$IMAGESURL/$ICONSSYSTEM{pidKill}\" ALT=\"Kill\" BORDER=0></A>";
                    printf($FORMATPSA, "RunStatusOnDemandCaptureChild", $pidChild, $ppidChild, $daemonProcessTablePctmem {$pidChild}, $daemonProcessTableSize {$pidChild}, $daemonProcessTableTtydev {$pidChild}, $daemonProcessTableState {$pidChild}, scalar(localtime($daemonProcessTableStart {$pidChild})), $cmndline, 'RunStatusOnDemandCaptureChildAction', $urlAction);
                  } else {
                    printf($FORMATPS, "RunStatusOnDemandCaptureChild", $pidChild, $ppidChild, $daemonProcessTablePctmem {$pidChild}, $daemonProcessTableSize {$pidChild}, $daemonProcessTableTtydev {$pidChild}, $daemonProcessTableState {$pidChild}, scalar(localtime($daemonProcessTableStart {$pidChild})), $cmndline);
                  }

                  while ( my ($pidSubChild, $ppidSubChild) = each(%daemonProcessTableSubChild) ) {
                    if ($ppidSubChild == $pidChild) {
                      my $cmndline = ($daemonProcessTableCmndline {$pidSubChild} =~ /^(\Q$PERLCOMMAND\E \.\/[\w-]+.pl)/) ? $1 . ' ...' : $daemonProcessTableCmndline {$pidSubChild};
                      printf($FORMATPS, "RunStatusOnDemandCaptureSubChild", $pidSubChild, $ppidSubChild, $daemonProcessTablePctmem {$pidSubChild}, $daemonProcessTableSize {$pidSubChild}, $daemonProcessTableTtydev {$pidSubChild}, $daemonProcessTableState {$pidSubChild}, scalar(localtime($daemonProcessTableStart {$pidSubChild})), $cmndline);
                      delete $daemonProcessTableSubChild {$pidSubChild};
                    }
                  }

                  delete $daemonProcessTableChild {$pidChild};
                }
              }

              delete $daemonProcessTableParent {$pidParent};
            }
          } else {
            if ($state == -1 or $state == 1) {
              if ($iconDelete) {
                my $urlAction = "<A HREF=\"$urlWithAccessParameters&amp;pid=<NIHIL>&amp;ppid=<NIHIL>&amp;command=$PIDPATH/${daemonPidStatus}$urlDaemon.pid&amp;action=remove\"><IMG SRC=\"$IMAGESURL/$ICONSSYSTEM{pidRemove}\" ALT=\"Remove\" BORDER=0></A>";
                print "<tr><td class=\"RunStatusOnDemandCaptureDebug\">No running process for pidfile '$PIDPATH/${daemonPidStatus}$urlDaemon.pid' found</td><td class=\"RunStatusOnDemandCaptureDebugAction\">$urlAction</td></tr>\n";
              } else {
                print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCaptureDebug\">No running process for pidfile '$PIDPATH/${daemonPidStatus}$urlDaemon.pid' found</td></tr>\n";
              }
            } elsif ($state == 0 or $state == 2) {
              if ($iconAdd) {
                my $urlAction = "<A HREF=\"$urlWithAccessParameters&amp;pid=<NIHIL>&amp;ppid=<NIHIL>&amp;command=$APPLICATIONPATH/$binMasterOrSlave/${urlPrefix}${daemonPidStatus}${urlDaemon}.sh&amp;action=start\"><IMG SRC=\"$IMAGESURL/$ICONSSYSTEM{daemonStart}\" ALT=\"Start\" BORDER=0></A>";
                print "<tr><td class=\"RunStatusOnDemandCaptureDebug\">$APPLICATIONPATH/$binMasterOrSlave/${urlPrefix}${daemonPidStatus}${urlDaemon}.sh start</td><td class=\"RunStatusOnDemandCaptureDebugAction\">$urlAction</td></tr>\n";
              } else {
                print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCaptureDebug\">$APPLICATIONPATH/$binMasterOrSlave/${urlPrefix}${daemonPidStatus}${urlDaemon}.sh start</td></tr>\n";
              }
            } else {
              print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCaptureDebug\">Under construction: Daemon: '$daemonPidStatus ASNMTAP $daemon' running # $state</td></tr>\n";
            }

            delete $daemonCaptureArrayPid {$daemon};
          }
        }

        print "</table><br><table width=\"100%\" bgcolor=\"#333344\" border=0><tr><th colspan=\"2\" class=\"RunStatusOnDemandCaptureHeader\">ERROR's regarding 'All ASNMTAP $status'</th></tr>\n";

        if (keys (%daemonCaptureArrayPid) + keys (%daemonCaptureArrayParent) + keys (%daemonProcessTableParent) + keys (%daemonProcessTableChild) + keys (%daemonProcessTableSubChild)) {
          listAllProblems ('Debug', 'Zombie Pids', $daemonPidStatus, $prefix, \%daemonCaptureArrayPid, undef, 'remove', $debug);
          listAllProblems ('Parent', 'Zombie Parents', $daemonPidStatus, $prefix, \%daemonCaptureArrayParent, '(\.\/[\w-]+.pl)', 'kill', $debug);
          listAllProblems ('Parent', 'Running Parents', $daemonPidStatus, $prefix, \%daemonProcessTableParent, '(\.\/[\w-]+.pl)', 'kill', $debug);
          listAllProblems ('Child', 'Running Childs', $daemonPidStatus, $prefix, \%daemonProcessTableChild, '^(sh -c cd ' .$PLUGINPATH. '; \.\/[\w-]+.pl)', 'kill', $debug);
          listAllProblems ('SubChild', 'Running SubChilds', $daemonPidStatus, $prefix, \%daemonProcessTableSubChild, '^(' .$PERLCOMMAND. ' \.\/[\w-]+.pl)', 'kill', $debug);
        } else {
          print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCaptureDebug\">There are no UNKNOWN errors !!!</td></tr>\n";
        }
      } else {
        print "<tr><th colspan=\"2\" class=\"RunStatusOnDemandCaptureHeader\">ERROR regarding 'All ASNMTAP $status'</th></tr>\n";
      }

      print "<tr><td>&nbsp;</td></tr>\n" if ($capture_array == 0);
      print '</table><br>';
    } else {
      print '<br>No '. ucfirst($status) .' daemons defined.<br>';
    }
  } else {
    print '<br>Select application for immediate launch.<br>';
  }

  print '<BR>', "\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_legend (*STDOUT);
print '</BODY>', "\n", '</HTML>', "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub listAllProblems {
  my ($classType, $text, $daemonPidStatus, $prefix, $daemonProcessTableHash, $regex, $action, $debug) = @_;

  print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCaptureRunning\">$text</td></tr>\n" if (keys (%$daemonProcessTableHash));

  while ( my ($pid, $ppid) = each(%$daemonProcessTableHash) ) {
    my $cmndline = (defined $regex and $daemonProcessTableCmndline {$pid} =~ /$regex/) ? $1 . ' ...' : $daemonProcessTableCmndline {$pid};

    if ($iconDelete) {
      if ($action eq 'remove') {
        my $urlAction = "<A HREF=\"$urlWithAccessParameters&amp;pid=<NIHIL>&amp;ppid=<NIHIL>&amp;command=$PIDPATH/${daemonPidStatus}${prefix}${pid}.pid&amp;action=remove\"><IMG SRC=\"$IMAGESURL/$ICONSSYSTEM{pidRemove}\" ALT=\"Remove\" BORDER=0></A>";
        print "<tr><td class=\"RunStatusOnDemandCapture$classType\">No running process for pidfile '$PIDPATH/${daemonPidStatus}${prefix}${pid}.pid' found</td><td class=\"RunStatusOnDemandCapture${classType}Action\">$urlAction</td></tr>\n";
      } else {
        my $urlAction = "<A HREF=\"$urlWithAccessParameters&amp;pid=$pid&amp;ppid=$ppid&amp;command=killall&amp;action=$action\"><IMG SRC=\"$IMAGESURL/$ICONSSYSTEM{pidKill}\" ALT=\"$action\" BORDER=0></A>";
        printf($FORMATPSA, "RunStatusOnDemandCapture$classType", $pid, $ppid, $daemonProcessTablePctmem {$pid}, $daemonProcessTableSize {$pid}, $daemonProcessTableTtydev {$pid}, $daemonProcessTableState {$pid}, scalar(localtime($daemonProcessTableStart {$pid})), $cmndline, "RunStatusOnDemandCapture${classType}Action", $urlAction);
      }
    } else {
      if ($action eq 'remove') {
        print "<tr><td colspan=\"2\" class=\"RunStatusOnDemandCapture$classType\">No running process for pidfile '$PIDPATH/${daemonPidStatus}${prefix}${pid}.pid' found</td></tr>\n";
      } else {
        printf($FORMATPS, "RunStatusOnDemandCapture$classType", $pid, $ppid, $daemonProcessTablePctmem {$pid}, $daemonProcessTableSize {$pid}, $daemonProcessTableTtydev {$pid}, $daemonProcessTableState {$pid}, scalar(localtime($daemonProcessTableStart {$pid})), $cmndline);
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub doRequestedActions {
  my ($htmlTitle, $title, $command, $statusOK, $statusNOK, $debug) = @_;

  print "<P class=\"RunStatusOnDemandHtmlTitle\">$htmlTitle: <font class=\"RunStatusOnDemandCommand\">$title</font></P><IMG SRC=\"".$IMAGESURL."/gears.gif\" HSPACE=\"0\" VSPACE=\"0\" BORDER=\"0\" NAME=\"Progress\" title=\"Please Wait ...\" alt=\"Please Wait ...\"><table width=\"100%\" bgcolor=\"#333344\" border=0>";

  my ($rStatus, $rStdout, $rStderr) = call_system ("$SSHCOMMAND -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=$WWWKEYPATH/.ssh/known_hosts' -i '$WWWKEYPATH/.ssh/ssh' $SSHLOGONNAME\@localhost '$command'", ($debug eq 'T') ? 1 : 0);
  $rStderr =~ s/^stdin: is not a tty//;
  chomp ($rStderr);
# my $message = ($rStderr) ? $rStderr : (($rStatus) ? $statusOK : $statusNOK);
  my $message = ($rStderr) ? $rStderr : $statusOK;

  print "<tr><td><pre>Status : '$rStatus'\n\nCommand: '$command'\n\nMessage: $message\n\nSTDOUT : '$rStdout'\n\nSTDERR : '$rStderr'></pre></tr></td></table>\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

