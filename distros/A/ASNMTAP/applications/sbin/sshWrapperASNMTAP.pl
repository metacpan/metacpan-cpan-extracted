#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, sshWrapperASNMTAP.pl for ASNMTAP::Applications
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Getopt::Long;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications v3.002.003;
use ASNMTAP::Asnmtap::Applications qw(:APPLICATIONS $APPLICATIONPATH $PIDPATH $PERLCOMMAND);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($opt_C $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = 'sshWrapperASNMTAP.pl';
my $prgtext     = "ASNMTAP SSH Wrapper for the '$APPLICATION'";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $debug       = 1;                                            # default

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Where to log successes and failures to set to /dev/null to turn off logging.
my $filename    = "$LOGPATH/sshWrapperASNMTAP.log";

# What you want sent if access is denied.
my $denyString  = 'Access Denied! Sorry';

my $sshCmdRm    = 'remove';
my $sshCmdKill  = 'killall';
my $sshCmdSRSR  = 'script ';
my $sshCmdSRDA  = 'archive ';

my $regex       = '^((?:'. $sshCmdKill .' \d+)|(?:'. $sshCmdRm .' '. $PIDPATH .'\/(?:(?:Collector|Display)CT-(?:[\w-]+)|importDataThroughCatalog)\.pid)|(?:'. $sshCmdSRSR . $APPLICATIONPATH .'\/(?:master|slave|bin)\/(?:(?:Collector|Display)CT-(?:[\w-]+)|asnmtap-importDataThroughCatalog)\.sh (?:start|stop|restart|reload|status))|(?:'. $sshCmdSRDA .'cd '. $APPLICATIONPATH .'; '. $PERLCOMMAND .' \.\/display.pl --loop=F --creationTime=\"20\d\d-\d\d-\d\d \d\d:\d\d:\d\d\" --displayTime=T --lockMySQL=F --debug=F --hostname=(?:[\w.-]+) --checklist=DisplayCT-(?:[\w-]+) --pagedir=_loop_(?:[\w]+)_(?:[\w]+)))*';

my $commandRm   = '/bin/rm';
my $commandKill = '/bin/kill -9';
my $commandSRSR = '';
my $commandSRDA = '';

my ($command, $rvOpen);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Getopt::Long::Configure('bundling');
GetOptions ( "C:s" => \$opt_C, "command:s" => \$opt_C );

$command = $1 if ( defined $opt_C and $opt_C =~ /$regex/ );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$rvOpen = open (SSHOUT, "+>>$filename");

unless ($rvOpen) { print STDERR "Couldn't open log '$filename'!\n"; exit 0; }

my $now = localtime;

# Unset the path, so all commands must have the full path. This avoids any path attacks.
delete $ENV{PATH};

unless ( defined $command ) {
  # Since this script is called as a forced command, need to get the original ssh command given by the client.
  my $commandSSH = $ENV{SSH_ORIGINAL_COMMAND};

  unless ( defined $commandSSH ) {
    print SSHOUT ("$now environment variable SSH_ORIGINAL_COMMAND not set\n\n"); close (SSHOUT);
    print STDERR "$denyString\n"; exit 0;
  }

  # Log the command for tracking and debugging purposes
  if ( $debug ) {
    print SSHOUT ("$now EVALUATING: '$commandSSH'\n");
    print "EVALUATING '$commandSSH'\n";
  }

  $command = $1 if ( $commandSSH =~ /$regex/ );

  unless ( defined $command ) {
    print SSHOUT ("$now SSH REQUEST FAILED INSPECTION - SKIPPING '$commandSSH'\n\n"); close (SSHOUT); 
    print STDERR "SSH REQUEST FAILED INSPECTION - SKIPPING '$commandSSH'\n\n"; exit 0;
  }
}

$command =~ s/^$sshCmdRm/$commandRm/;
$command =~ s/^$sshCmdKill/$commandKill/;
$command =~ s/^$sshCmdSRSR/$commandSRSR/;
$command =~ s/^$sshCmdSRDA/$commandSRDA/;

$command = "ASNMTAP_PERL5LIB=$ENV{ASNMTAP_PERL5LIB}; $command" if ( $ENV{ASNMTAP_PERL5LIB} );

$now = localtime;

if ( $debug ) {
  print SSHOUT ("$now SSH REQUEST PASSED INSPECTION - INITIATING '$command'\n");
  print "SSH REQUEST PASSED INSPECTION - INITIATING '$command'\n";
}

# Interesting issue here, printing is queued until file is closed
# if ssh fails and exits out of the script earlier input would never
# be seen. In fact 'exec' call was replaced with 'system' call for the
# reason that exec did not return to the shell and the print output was
# never seen because the close was never reached.

# close and reopen output file to empty print queue to this point
close (SSHOUT);
$rvOpen = open (SSHOUT, "+>>$filename");
unless ($rvOpen) { print STDERR "Couldn't reopen log '$filename'!\n"; exit 0; }

my ($stdout, $stderr, $exit_value, $signal_num, $dumped_core);

print "EXECUTE '$command'\n" if ($debug);

if ($CAPTUREOUTPUT) {
  use IO::CaptureOutput qw(capture_exec);
  ($stdout, $stderr) = capture_exec($command);
} else {
  system ($command); $stdout = $stderr = '';
}

$exit_value  = $? >> 8;
$signal_num  = $? & 127;
$dumped_core = $? & 128;

$now = localtime;

if ( $exit_value == 0 && $signal_num == 0 && $dumped_core == 0 && $stderr eq '' ) {
  if ($debug) {
    print SSHOUT ("$now '$command' COMPLETED\n");
    print "'$command' COMPLETED\n";
  }
} else {
  print SSHOUT ("$now '$command' FAILED: $stderr\n\n"); close (SSHOUT);
  print STDERR "'$command' FAILED: $stderr\n"; exit 0;
}

print SSHOUT ("\n");
close (SSHOUT);
exit 1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
