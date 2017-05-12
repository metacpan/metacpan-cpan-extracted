#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_swap.pl
# ----------------------------------------------------------------------------------------------------------
# Linux: swap
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
  _programName        => 'check_swap.pl',
  _programDescription => 'SWAP',
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

$objectNagios->printUsage ('Only ostype Linux is supported!') unless ( defined $osType and $osType =~ /^Linux$/ );
$objectNagios->printUsage ('You must define WARNING and CRITICAL levels!') unless ($warning != 0 and $critical != 0);
$objectNagios->printUsage ('WARNING level must not be greater than CRITICAL when checking swap!') if ($warning >= $critical);

my $warn_level = $warning;
my $crit_level = $critical;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($returnCode, $warn_level_perfdata, $crit_level_perfdata, $result, $total_swap, $free_swap, $used_swap, $percent, $fmt_pct);

$objectNagios->exit (5) if ( $objectNagios->call_system ( 'free | tail -n1' ) );
$result = $objectNagios->pluginValue ('result');

if ($result !~ /^Swap:\s+(\d+)\s+(\d+)\s+(\d+)/) {
  $objectNagios->pluginValue ( stateValue => $ERRORS{UNKNOWN} );
  $objectNagios->exit (5);
}

# Define the calculating scalars
$total_swap = convert_to_KB('kB', $1);
$used_swap  = convert_to_KB('kB', $2);
$free_swap  = convert_to_KB('kB', $3);

# Convert the scalars
$total_swap = int(convert_from_KB_to_metric($metric, $total_swap));
$used_swap  = int(convert_from_KB_to_metric($metric, $used_swap));
$free_swap  = int(convert_from_KB_to_metric($metric, $free_swap));

$warn_level_perfdata = ($total_swap / 100) * $warn_level;
$warn_level_perfdata = sprintf("%.2f", $warn_level_perfdata) if ($metric ne 'kB');

$crit_level_perfdata = ($total_swap / 100) * $crit_level;
$crit_level_perfdata = sprintf("%.2f", $crit_level_perfdata) if ($metric ne 'kB');

$objectNagios->appendPerformanceData ( "'Used swap'=$used_swap$metric;$warn_level_perfdata;$crit_level_perfdata;0;$total_swap" );

$percent = ($used_swap / $total_swap) * 100;
$fmt_pct = sprintf "%.2f", $percent;

$returnCode = ( $percent >= $crit_level ? $ERRORS{CRITICAL} : ( $percent >= $warn_level ? $ERRORS{WARNING} : $ERRORS{OK} ) );
$objectNagios->pluginValues ( { stateValue => $returnCode, alert => "$fmt_pct% ($total_swap $metric) used" }, $TYPE{APPEND} );
$objectNagios->exit (5);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
