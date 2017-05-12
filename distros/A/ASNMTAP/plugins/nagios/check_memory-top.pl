#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_memory-free.pl
# ----------------------------------------------------------------------------------------------------------
# Solaris 8, 9 & 10 and TRU64: memory
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
  _programName        => 'check_memory-free.pl',
  _programDescription => 'MEMORY',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '-w|--warning <percent> -c|--critical <percent> -n|--numberProcesses <number of processes> -s|--sortingOrder [cpu|size|res|time] -M|--memory [F|U]',
  _programHelpPrefix  => "-w, --warning=<percent>
    PERCENT: Percent allocated when to warn
-c, --critical=<percent>
    PERCENT: Percent allocated when critical
-n, --numberProcesses=<number of processes>
-s, --sortingOrder=[cpu|size|res|time]
-M, --memory=[F|U]
    Check F(ree)/U(sed) memory",
  _programGetOptions  => ['warning|w=s', 'critical|c=s', 'numberProcesses|n=f', 'sortingOrder|s=s', 'memory|M=s'],
  _timeout            => 10,
  _debug              => 0);

my $warning   = $objectNagios->getOptionsArgv ('warning');
my $critical  = $objectNagios->getOptionsArgv ('critical');

my $numberProcesses = $objectNagios->getOptionsArgv ('numberProcesses');
$objectNagios->printUsage ('Missing command line argument numberProcesses') unless ( defined $numberProcesses);
$objectNagios->printUsage ('You must select a number of processes to display!') unless ($numberProcesses and $numberProcesses != 0);

my $sortingOrder = $objectNagios->getOptionsArgv ('sortingOrder');
$objectNagios->printUsage ('Missing command line argument sortingOrder') unless ( defined $sortingOrder);
$objectNagios->printUsage ('You must select to monitor either cpu, size, res or time sorting order') unless ($sortingOrder =~ /^cpu|size|res|time$/);

my $memory    = $objectNagios->getOptionsArgv ('memory');
$objectNagios->printUsage ('Missing command line argument memory') unless ( defined $memory);
$objectNagios->printUsage ('You must select to monitor either U(sed) or F(ree) memory!') unless ($memory =~ /^F|U$/);

my $tOstype   = $objectNagios->getOptionsArgv ('ostype');
my $tMetric   = $objectNagios->getOptionsArgv ('metric');
$objectNagios->printUsage ('Missing command line argument metric') unless ( defined $tMetric);

my $osType    = $objectNagios->getOptionsValue ('osType');
my $metric    = $objectNagios->getOptionsValue ('metric');

$osType = $tOstype if ( defined $tOstype);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectNagios->printUsage ('Only ostype Solaris, Solaris10 and True64 is supported!') unless ( defined $osType and $osType =~ /^(?:Solaris|Solaris10|True64)$/ );
$objectNagios->printUsage ('You must define WARNING and CRITICAL levels!') unless ($warning != 0 and $critical != 0);
$objectNagios->printUsage ('WARNING level must not be greater than CRITICAL when checking memory!') if ($memory eq 'U' and $warning >= $critical);
$objectNagios->printUsage ('CRITICAL level must not be greater than WARNING when checking memory!') if ($memory eq 'F' and $critical >= $warning);

my $warn_level = $warning;
my $crit_level = $critical;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($returnCode, $result, $topHeader, $topDetail, $memory_line, $free_memory, $used_memory, $total_memory, $percent, $fmt_pct, $warn_level_perfdata, $crit_level_perfdata);

if ($osType eq 'TRU64') {
  $topHeader = '\\s+PID\\s+USERNAME\\s+PRI\\s+NICE\\s+SIZE\\s+RES\\s+STATE\\s+TIME\\s+CPU\\s+COMMAND';
  $topDetail = '\\s*\\d+\\s+\\w+\\s+\\d+\\s+-?\\d+\\s+([0-9.]+)([kMG])\\s+([0-9.]+)([kMG])\\s+[\\w|\\d|/]+\\s+([0-9:.H]+)\\s+([0-9.]+)%\\s+(\\w+)';
} else {
  $topHeader = '\\s+PID\\s+USERNAME\\s+\\w+\\s+PRI\\s+NICE\\s+SIZE\\s+RES\\s+STATE\\s+TIME\\s+CPU\\s+COMMAND';
  $topDetail = '\\s*\\d+\\s+\\w+\\s+\\d+\\s+\\d+\\s+-?\\d+\\s+([0-9.]+)([kKMG])\\s+([0-9.]+)([kKMG])\\s+[\\w|\\d|/]+\\s+([0-9:.H]+)\\s+([0-9.]+)%\\s+(\\w+)';
}

$objectNagios->exit (5) if ( $objectNagios->call_system ( "top -b $numberProcesses -S -o $sortingOrder | grep -v sleep" ) );
$result = $objectNagios->pluginValue ('result');

my ($totalSizeValue, $totalResValue, $topHeaderFound, $eol) = (0, 0, 0, '\n');
my @result = split (/$eol/, $result);

foreach my $line (@result) {
  if ($topHeaderFound) { 
    $line =~ s/\n$//g;
    $line =~ s/\r$//g;

    if ($line) {
      my ($sizeValue, $sizeMetric, $resValue, $resMetric, $time, $cpu, $command) = ( $line =~ m/^$topDetail/i );
      $totalSizeValue += convert_to_KB($sizeMetric, $sizeValue);
      $totalResValue  += convert_to_KB($resMetric, $resValue);
    }
  } elsif ($line =~ /^Memory:/) {
    $memory_line = $line;
  } elsif ($line =~ /^$topHeader$/) {
    $topHeaderFound = 1;
  }
}

$totalSizeValue = convert_from_KB_to_metric($metric, $totalSizeValue);
$totalResValue  = convert_from_KB_to_metric($metric, $totalResValue);

if (defined $memory_line) {
  if ($osType eq 'TRU64') {
    $memory_line =~ s/^Memory:\s+Real:\s+([0-9.]+)([kMG])\/([0-9.]+)([kMG])\s+act\/tot\s+Virtual:\s+([0-9.]+)([kMG])\/([0-9.]+)([kMG])\s+use\/tot\s+Free:\s+([0-9.]+)([kMG])\s*/$7;$8;$9;$10/gi;
  } elsif ($osType eq 'Solaris10') {
    $memory_line =~ s/^Memory:\s+([0-9.]+)([kKMG])\s+phys\s+mem,\s+([0-9.]+)([kKMG])\s+free\s+mem,\s+([0-9.]+)([kKMG])\s+(total\s+){0,1}swap,\s+([0-9.]+)([kKMG])\s+free\s+swap$/$1;$2;$3;$4/gi;
  } else {
    $memory_line =~ s/^Memory:\s+([0-9.]+)([kKMG])\s+real,\s+([0-9.]+)([kKMG])\s+free,\s+([0-9.]+)([kKMG])\s+swap\s+in\s+use,\s+([0-9.]+)([kKMG])\s+swap\s+free$/$1;$2;$3;$4/gi;
  }

  my @top = split(/;/, $memory_line);

  # Define the calculating scalars
  $total_memory = convert_to_KB($top[1], $top[0]);
  $free_memory  = convert_to_KB($top[3], $top[2]);
  $used_memory  = $total_memory - $free_memory;

  $total_memory = convert_from_KB_to_metric($metric, $total_memory);
  $free_memory  = convert_from_KB_to_metric($metric, $free_memory);
  $used_memory  = convert_from_KB_to_metric($metric, $used_memory);

  $warn_level_perfdata = ($total_memory / 100) * $warn_level;
  $warn_level_perfdata = sprintf("%.2f", $warn_level_perfdata) if ($metric ne 'kB');

  $crit_level_perfdata = ($total_memory / 100) * $crit_level;
  $crit_level_perfdata = sprintf("%.2f", $crit_level_perfdata) if ($metric ne 'kB');

  if ($memory eq 'F') {
    $warn_level_perfdata = $total_memory - $warn_level_perfdata;
    $crit_level_perfdata = $total_memory - $crit_level_perfdata;
  }

  $objectNagios->appendPerformanceData ( "'Memory usage'=$used_memory$metric;$warn_level_perfdata;$crit_level_perfdata;0;$total_memory" );
  $objectNagios->appendPerformanceData ( "Size=$totalSizeValue$metric;0;0;0;$total_memory" );
  $objectNagios->appendPerformanceData ( "Res=$totalResValue$metric;0;0;0;$total_memory" );

  if ($memory eq 'F') {
    $percent = ($free_memory / $total_memory) * 100;
    $fmt_pct = sprintf "%.1f", $percent;
    $returnCode = ( $percent <= $crit_level ? $ERRORS{CRITICAL} : ( $percent <= $warn_level ? $ERRORS{WARNING} : $ERRORS{OK} ) );
    $objectNagios->pluginValues ( { stateValue => $returnCode, alert => "$fmt_pct% ($free_memory $metric) free" }, $TYPE{APPEND} );
  } else {
    $percent = ($used_memory / $total_memory) * 100;
    $fmt_pct = sprintf "%.1f", $percent;
    $returnCode = ( $percent >= $crit_level ? $ERRORS{CRITICAL} : ( $percent >= $warn_level ? $ERRORS{WARNING} : $ERRORS{OK} ) );
    $objectNagios->pluginValues ( { stateValue => $returnCode, alert => "$fmt_pct% ($used_memory $metric) used" }, $TYPE{APPEND} );
  }
} else {
  $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => 'Memory information not found' }, $TYPE{APPEND} );
}

$objectNagios->pluginValues ( { alert => "Size: $totalSizeValue $metric - Res: $totalResValue $metric" }, $TYPE{APPEND} );
$objectNagios->exit (5);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
