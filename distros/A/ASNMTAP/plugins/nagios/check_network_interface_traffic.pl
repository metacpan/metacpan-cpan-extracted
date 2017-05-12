#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_network_interface_traffic.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.002.003;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins::Nagios->new (
  _programName        => 'check_network_interface_traffic.pl',
  _programDescription => 'Network Interface Traffic',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '--interface=<interface>',
  _programHelpPrefix  => '--interface=<interface>',
  _programGetOptions  => ['interface|i:s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $interface = $objectNagios->getOptionsArgv ('interface');
# $objectNagios->printUsage ('Missing command line argument interface') unless (defined $interface);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($topHeader, $topDetail, $result);
$topHeader = '\\s*Name\\s+Mtu\\s+Net\/Dest\\s+Address\\s+Ipkts\\s+Ierrs\\s+Opkts\\s+Oerrs\\s+Collis\\s+Queue\\s*';
$topDetail = '\\s*(\\w+)\\s+\\d+\\s+[\\w-]+\\s+[\\w-]+\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+(\\d+)\\s*';

$objectNagios->exit (5) if ( $objectNagios->call_system ( 'netstat -'. ( defined $interface ? "I $interface" : 'i' ) ) );
$result = $objectNagios->pluginValue ('result');

my ($Ipkts, $Ierrs, $Opkts, $Oerrs, $Collis, $Queue, $topHeaderFound, $eol, $value) = (-1, -1, -1, -1, -1, -1, 0, '\n');
my @result = split (/$eol/, $result);

foreach my $line (@result) {
  if ($topHeaderFound) {
    $line =~ s/\n$//g;
    $line =~ s/\r$//g;
    ($interface, $Ipkts, $Ierrs, $Opkts, $Oerrs, $Collis, $Queue) = ( $line =~ m/^$topDetail/i ) if ($line);

    unless ( $interface ) {
      $objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => 'No data for interface found. Something wrong?' }, $TYPE{APPEND} );
    } else {
      $objectNagios->pluginValues ( { stateValue => $ERRORS{OK}, alert => 'Interface \''. $interface. '\' found.' }, $TYPE{APPEND} );
      $objectNagios->appendPerformanceData ( "'$interface input packets'=${Ipkts}c;;;; '$interface input errors'=${Ierrs}c;;;; '$interface output packets'=${Opkts}c;;;; '$interface output errors'=${Oerrs}c;;;; '$interface collisions'=${Collis}c;;;; '$interface queue'=${Queue}c;;;;" );

      # (Collis+Ierrs+Oerrs)/(Ipkts+Opkts) > 2% : This may indicate a network hardware issue.
      $value = ( $Collis + $Ierrs + $Oerrs ) / ( $Ipkts + $Opkts );
      $objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => 'Interface \''. $interface. '\' network hardware issue?' }, $TYPE{APPEND} ) if ( $value > 2 );
      $objectNagios->appendPerformanceData ( "'$interface hardware'=${value}%;;2;;" );

      # (Collis/Opkts) > 10%                    : The interface is overloaded. Traffic will need to be reduced or redistributed to other interfaces or servers.
      $value = ( $Collis / $Opkts );
      $objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => 'Interface \''. $interface. '\' overloaded?' }, $TYPE{APPEND} ) if ( $value > 10 );
      $objectNagios->appendPerformanceData ( "'$interface overloaded'=${value}%;;10;;" );

      # (Ierrs/Ipkts) > 25%                     : Packets are probably being dropped by the host, indicating an overloaded network (and/or server).
      $value = ( $Ierrs / $Ipkts );
      $objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => 'Interface \''. $interface. '\' indicating an overloaded network?' }, $TYPE{APPEND} ) if ( $value > 25 );
      $objectNagios->appendPerformanceData ( "'$interface dropped'=${value}%;;25;;" );
    };
  } elsif ($line =~ /^$topHeader$/) {
    $topHeaderFound = 1;
  }
}

$objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => 'No data for interface(s) found. Something wrong?' }, $TYPE{APPEND} ) unless ( $topHeaderFound );
$objectNagios->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
