#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_iowait.pl
# ----------------------------------------------------------------------------------------------------------
# Solaris: iowait
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.002.003;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins::Nagios->new (
  _programName        => 'check_iowait.pl',
  _programDescription => 'IOWAIT',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '-w|--warning <percent> -c|--critical <percent> -n|--numberStates <number of states> -i|--interval [cpu|size|res|time]',
  _programHelpPrefix  => "-w, --warning=<percent>
    PERCENT: Percent allocated when to warn
-c, --critical=<percent>
    PERCENT: Percent allocated when critical
-n, --numberStates=<number of states>
-i, --interval=<number in second between two states>",
  _programGetOptions  => ['warning|w=s', 'critical|c=s', 'numberStates|n=f', 'interval|i=s'],
  _timeout            => 10,
  _debug              => 0);

my $warning   = $objectNagios->getOptionsArgv ('warning');
my $critical  = $objectNagios->getOptionsArgv ('critical');

my $numberStates = $objectNagios->getOptionsArgv ('numberStates');
$objectNagios->printUsage ('Missing command line argument numberStates') unless ( defined $numberStates);
$objectNagios->printUsage ('You must select a number of states to display!') unless ($numberStates and $numberStates > 0);

my $interval = $objectNagios->getOptionsArgv ('interval');
$objectNagios->printUsage ('Missing command line argument interval') unless ( defined $interval);

my $tOstype   = $objectNagios->getOptionsArgv ('ostype');

my $osType    = $objectNagios->getOptionsValue ('osType');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectNagios->printUsage ('Only ostype Solaris is supported!') unless ( defined $osType and $osType =~ /^(?:Solaris)$/ );
$objectNagios->printUsage ('You must define WARNING and CRITICAL levels!') unless ($warning != 0 and $critical != 0);
$objectNagios->printUsage ('WARNING level must not be less than CRITICAL when checking IOWAIT!') unless ($warning < $critical);
$objectNagios->printUsage ('CRITICAL level must not be less than WARNING when checking IOWAIT!') unless ($critical > $warning);

my $warn_level = $warning;
my $crit_level = $critical;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($returnCode, $result, $iowait_line, $average_iowait, $warn_level_perfdata, $crit_level_perfdata);

$objectNagios->exit (5) if ( $objectNagios->call_system ( "iostat -cr $interval ". ($numberStates + 1) ) );
$result = $objectNagios->pluginValue ('result');

my ($states, $totalSizeValue, $totalResValue, $eol) = (0, 0, 0, '\n');
my @result = split (/$eol/, $result);

foreach my $line (@result) {
  if ($states) {
    $line =~ s/\n$//g;
    $line =~ s/\r$//g;

    if ($line) {
      if (defined $average_iowait) {
        my ($us, $sy, $wt, $id) = split (/,/, $line);
        $average_iowait += $wt;
      } else {
        $average_iowait = 0;
      }
    }
  } elsif ($line =~ /^us,sy,wt,id$/) {
    $states = 1;
  }
}

if (defined $average_iowait) {
  $average_iowait /= $numberStates;

  $warn_level_perfdata = $warn_level;
  $crit_level_perfdata = $crit_level;

  $objectNagios->appendPerformanceData ( "'IOWAIT'=$average_iowait;$warn_level_perfdata;$crit_level_perfdata;0;100" );

  $returnCode = ( $average_iowait >= $crit_level ? $ERRORS{CRITICAL} : ( $average_iowait >= $warn_level ? $ERRORS{WARNING} : $ERRORS{OK} ) );
  $objectNagios->pluginValues ( { stateValue => $returnCode, alert => "IOWAIT $average_iowait%" }, $TYPE{APPEND} );
} else {
  $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => 'IOWAIT information not found' }, $TYPE{APPEND} );
}

$objectNagios->exit (5);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
