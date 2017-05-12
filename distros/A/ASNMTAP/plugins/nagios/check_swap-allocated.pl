#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_swap-allocated.pl
# ----------------------------------------------------------------------------------------------------------
# Solaris: swap allocated
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
  _programName        => 'check_swap-allocated.pl',
  _programDescription => 'SWAP allocated',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '-w|--warning <percent> -c|--critical <percent>',
  _programHelpPrefix  => "-w, --warning=<percent>
    PERCENT: Percent allocated when to warn
-c, --critical=<percent>
    PERCENT: Percent allocated when critical",
  _programGetOptions  => ['warning|w=s', 'critical|c=s'],
  _timeout            => 10,
  _debug              => 0);

my $warning   = $objectNagios->getOptionsArgv ('warning');
my $critical  = $objectNagios->getOptionsArgv ('critical');
my $tOstype   = $objectNagios->getOptionsArgv ('ostype');
my $tMetric   = $objectNagios->getOptionsArgv ('metric');
$objectNagios->printUsage ('Missing command line argument metric') unless ( defined $tMetric);

my $osType    = $objectNagios->getOptionsValue ('osType');
my $metric    = $objectNagios->getOptionsValue ('metric');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectNagios->printUsage ('Only ostype Solaris is supported!') unless ( defined $osType and $osType =~ /^Solaris$/ );
$objectNagios->printUsage ('You must define WARNING and CRITICAL levels!') unless ($warning != 0 and $critical != 0);
$objectNagios->printUsage ('WARNING level must not be greater than CRITICAL when checking allocated swap!') if ($warning >= $critical);

my $warn_level = $warning;
my $crit_level = $critical;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($returnCode, $warn_level_perfdata, $crit_level_perfdata, $result, $total_swap, $free_swap, $used_swap, $allocated_swap, $reserved_swap, $percent, $fmt_pct);

$objectNagios->exit (5) if ( $objectNagios->call_system ( 'swap -s' ) );
$result = $objectNagios->pluginValue ('result');

$result =~ s/^total: ([0-9.]+)([kMG]) bytes allocated \+ ([0-9.]+)([kMG]) reserved \= ([0-9.]+)([kMG]) used, ([0-9.]+)([kMG]) available$/$1 $2 $3 $4 $5 $6 $7 $8/gi;

my @top = split (/ /, $result);

unless ( @top ) {
  $objectNagios->pluginValue ( stateValue => $ERRORS{UNKNOWN} );
  $objectNagios->exit (5);
}

# Define the calculating scalars
$allocated_swap = convert_to_KB($top[1], $top[0]);
$reserved_swap  = convert_to_KB($top[3], $top[2]);
$used_swap      = convert_to_KB($top[5], $top[4]);
$free_swap      = convert_to_KB($top[7], $top[6]);
$total_swap     = $free_swap + $used_swap;

# Convert the scalars
$allocated_swap = convert_from_KB_to_metric($metric, $allocated_swap);
$reserved_swap  = convert_from_KB_to_metric($metric, $reserved_swap);
$used_swap      = convert_from_KB_to_metric($metric, $used_swap);
$free_swap      = convert_from_KB_to_metric($metric, $free_swap);
$total_swap     = convert_from_KB_to_metric($metric, $total_swap);

$warn_level_perfdata = ($total_swap / 100) * $warn_level;
$warn_level_perfdata = sprintf("%.2f", $warn_level_perfdata) if ($metric ne 'kB');

$crit_level_perfdata = ($total_swap / 100) * $crit_level;
$crit_level_perfdata = sprintf("%.2f", $crit_level_perfdata) if ($metric ne 'kB');

$objectNagios->appendPerformanceData ( "'Allocated usage'=$allocated_swap$metric;$warn_level_perfdata;$crit_level_perfdata;0;$total_swap" );
$objectNagios->appendPerformanceData ( "'Reserved usage'=$reserved_swap$metric;;;0;$total_swap" );
$objectNagios->appendPerformanceData ( "'Used usage'=$used_swap$metric;;;0;$total_swap" );

$percent = ($allocated_swap / $total_swap) * 100;
$fmt_pct = sprintf "%.1f", $percent;

$returnCode = ( $percent >= $crit_level ? $ERRORS{CRITICAL} : ( $percent >= $warn_level ? $ERRORS{WARNING} : $ERRORS{OK} ) );
$objectNagios->pluginValues ( { stateValue => $returnCode, alert => "$fmt_pct% ($allocated_swap $metric) allocated" }, $TYPE{APPEND} );
$objectNagios->exit (5);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
