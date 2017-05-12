#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_memory-free.pl
# ----------------------------------------------------------------------------------------------------------
# Linux: memory
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
$objectNagios->printUsage ('WARNING level must not be greater than CRITICAL when checking memory!') if ($warning >= $critical);

my $warn_level = $warning;
my $crit_level = $critical;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($returnCode, $warn_level_perfdata, $crit_level_perfdata, $result, $total_mem, $free_mem, $used_mem, $percent, $fmt_pct);

$objectNagios->exit (5) if ( $objectNagios->call_system ( 'free' ) );
$result = $objectNagios->pluginValue ('result');

if ($result !~ /Mem:\s+(\d+)\s+(\d+)\s+(\d+)/) {
  $objectNagios->pluginValue ( stateValue => $ERRORS{UNKNOWN} );
  $objectNagios->exit (5);
}

# Define the calculating scalars
$total_mem = convert_to_KB('kB', $1);
$used_mem  = convert_to_KB('kB', $2);
$free_mem  = convert_to_KB('kB', $3);

# Convert the scalars
$total_mem = int(convert_from_KB_to_metric($metric, $total_mem));
$used_mem  = int(convert_from_KB_to_metric($metric, $used_mem));
$free_mem  = int(convert_from_KB_to_metric($metric, $free_mem));

$warn_level_perfdata = ($total_mem / 100) * $warn_level;
$warn_level_perfdata = sprintf("%.2f", $warn_level_perfdata) if ($metric ne 'kB');

$crit_level_perfdata = ($total_mem / 100) * $crit_level;
$crit_level_perfdata = sprintf("%.2f", $crit_level_perfdata) if ($metric ne 'kB');

$objectNagios->appendPerformanceData ( "'Used mem'=$used_mem$metric;$warn_level_perfdata;$crit_level_perfdata;0;$total_mem" );

$percent = ($used_mem / $total_mem) * 100;
$fmt_pct = sprintf "%.2f", $percent;

$returnCode = ( $percent >= $crit_level ? $ERRORS{CRITICAL} : ( $percent >= $warn_level ? $ERRORS{WARNING} : $ERRORS{OK} ) );
$objectNagios->pluginValues ( { stateValue => $returnCode, alert => "$fmt_pct% ($total_mem $metric) used" }, $TYPE{APPEND} );
$objectNagios->exit (5);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

