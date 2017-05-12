#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2010 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2010/mm/dd, v3.001.003, check_pargs.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.001.003;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins::Nagios->new (
  _programName        => 'check_pargs.pl',
  _programDescription => 'pargs',
  _programVersion     => '3.001.003',
  _programUsagePrefix => '--filter <filter> [--uid <uid>] [--gid <gid>] [--fname <fname>] [-w|--warning <process #>] |[-c--critical <process #>]',
  _programHelpPrefix  => "
--uid=<uid>
--gid=<gid>
--fname=<fname>
-w, --warning=<process #>
-c, --critical=<process #>",
  _programGetOptions  => ['filter=s', 'uid:s', 'gid:s', 'fname:s', 'warning|w:s', 'critical|c:s'],
  _timeout            => 10,
  _debug              => 0);

my $filter    = $objectNagios->getOptionsArgv ('filter');
$objectNagios->printUsage ('Missing command line argument filter') unless ( defined $filter );

my $uid       = $objectNagios->getOptionsArgv ('uid');
my $gid       = $objectNagios->getOptionsArgv ('gid');
my $fname     = $objectNagios->getOptionsArgv ('fname');

my $warning   = $objectNagios->getOptionsArgv ('warning');
my $critical  = $objectNagios->getOptionsArgv ('critical');

my $osType    = $objectNagios->getOptionsValue ('osType');
my $debug     = $objectNagios->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectNagios->printUsage ('Only ostype Solaris is supported!') unless ( defined $osType and $osType =~ /^Solaris$/ );

if ( defined $warning and defined $critical ) {
  $objectNagios->printUsage ('WARNING level must not be greater than CRITICAL!') unless ($warning <= $critical);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($processCount, $returnCode) = (0);

use Proc::ProcessTable;
my $tProcessTable = new Proc::ProcessTable;

foreach my $process ( @{$tProcessTable->table} ) {
  next if ( defined $uid and $uid ne $process->uid );
  next if ( defined $gid and $gid ne $process->gid );
  next if ( defined $fname and $fname ne $process->fname );

  if ( $debug ) {
    print 'uid   : ', $process->uid, "\n";
    print 'gid   : ', $process->gid, "\n";
    print 'fname : ', $process->fname, "\n";

    print 'pid   : ', $process->pid, "\n";
    print 'ppid  : ', $process->ppid, "\n";
    print 'cmnd  : ', $process->cmndline, "\n";
    print 'state : ', $process->state, "\n"; # run, onprocessor, sleep, defunct, ...

    print 'pargs : /usr/bin/pfexec /usr/bin/pargs -a -l '. $process->pid, "\n";
  }

  $objectNagios->exit (5) if ( $objectNagios->call_system ( '/usr/bin/pfexec /usr/bin/pargs -a -l '. $process->pid ) );
  my $result = $objectNagios->pluginValue ('result');
  print "filter: $filter\nresult: $result\n" if ( $debug );
  $processCount++ if ( $result !~ /\Qcheck_pargs.pl\E/ and $result =~ /$filter/ );
}

if ( defined $warning and defined $critical ) {
  $objectNagios->appendPerformanceData ( "'Process Count'=$processCount;$warning;$critical;0;3" );
  $returnCode = ( $processCount >= $critical ? $ERRORS{CRITICAL} : ( $processCount >= $warning ? $ERRORS{WARNING} : ( $processCount >= 1 ? $ERRORS{OK} : $ERRORS{UNKNOWN} ) ) );
} else {
  $objectNagios->appendPerformanceData ( "'Process Count'=$processCount;;;0;3" );
  $returnCode = ( $processCount >= 1 ? $ERRORS{OK} : $ERRORS{CRITICAL} );
}

$objectNagios->pluginValues ( { stateValue => $returnCode, alert => "Filter: '$filter', Process Count: $processCount" }, $TYPE{REPLACE} );
$objectNagios->exit (5);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

