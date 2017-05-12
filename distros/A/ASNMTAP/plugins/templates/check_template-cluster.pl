#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-cluster.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications v3.002.003;
use ASNMTAP::Asnmtap::Applications qw($CATALOGID);

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_template-cluster.pl',
  _programDescription => "Cluster plugin for testing the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programUsagePrefix => '--message=<message> --uKeys|-K=<uKey[%weight][:uKey[%weight]]> --method=[highest-status|non-OK|percentage|weight] --outOfDate=<THRESHOLD> -w|--warning=<VALUE> -c|--critical=<VALUE> [--downgradingStatus=[F|T]] [--ignoreDependent=[F|T]] [--ignoreOffline=[F|T]] [--ignoreNoTest=[F|T]] [-s|--server <hostname>] [--database=<database>]',
  _programHelpPrefix  => '--message=<message>
   --message=message
-K, --uKeys=<uKey[%weight][:uKey[%weight]]>
   highest-status: specifies the range of uKey in the cluster
   non-OK        : specifies the range of uKey in the cluster
   percentage    : specifies the range of uKey in the cluster
   weight        : specifies the range of uKey with weight in the cluster
-m, --method=[highest-status|non-OK|percentage|weight]
   highest-status: highest-status cluster monitoring
   non-OK        : non-OK cluster monitoring with WARNING and CRITICAL thresholds
   percentage    : percentage cluster monitoring with WARNING and CRITICAL percentages
   weight        : weight cluster monitoring with WARNING and CRITICAL percentages
--outOfDate==<THRESHOLD>
  specifies the out of date threshold in minutes for a single test
-w, --warning=<VALUE>
   highest-status: not applicable
   non-OK        : specifies the clusters threshold that must be in a non-OK state in order to return a WARNING status level
   percentage    : specifies the clusters percentage that must be in a WARNING state to return a WARNING status level
   weight        : specifies the clusters weight that must be in a WARNING state to return a WARNING status level
-c, --critical=<VALUE>
   highest-status: not applicable
   non-OK        : specifies the clusters threshold that must be in a non-OK state in order to return a CRITICAL status level
   percentage    : specifies the clusters percentage that must be in a CRITICAL or higher state to return a CRITICAL status level
   weight        : specifies the clusters weight that must be in a CRITICAL or higher state to return a CRITICAL status level
--downgradingStatus=[F|T]
   highest-status: not applicable
   non-OK        : if (highest event status = warning) and (calculated status = critical) then alarm status downgrated to warning level, default: true
   percentage    : not applicable
   weight        : not applicable
--ignoreDependent=[F|T]
   do ignore tests in scheduled dependent, default: false
--ignoreOffline=[F|T]
   do ignore tests in scheduled offline, default: false
--ignoreNoTest=[F|T]
   do ignore tests in scheduled no-test, default: false
-s, --server=<hostname> (default: localhost)
--database=<database> (default: asnmtap)',
  _programGetOptions  => ['message=s', 'uKeys|K=s', 'method=s', 'outOfDate=i', 'warning|w:i', 'critical|c:i', 'downgradingStatus:s', 'ignoreDependent:s', 'ignoreOffline:s', 'ignoreNoTest:s', 'server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e:s', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $message         = $objectPlugins->getOptionsArgv ('message');
$objectPlugins->printUsage ( 'Missing command line argument message' ) unless (defined $message);
$objectPlugins->pluginValue ( message => $message );

my $uKeys             = $objectPlugins->getOptionsArgv ('uKeys');
$objectPlugins->printUsage ( 'Missing command line argument uKeys' ) unless ( defined $uKeys );

my $method            = $objectPlugins->getOptionsArgv ('method');
$objectPlugins->printUsage ( 'Missing command line argument method' ) unless ( defined $method );
$objectPlugins->printUsage ( 'Unsupported method' ) unless ( $method =~ /^(?:highest-status|non-OK|percentage|weight)$/ );

my ( %uKeys, @uKeys, $_uKey, $uKeyCount, %status, $_status, %cluster, %weight );
$uKeyCount = ( @uKeys = split ( /:/, $uKeys ) );
$objectPlugins->printUsage ( 'Cluster plugin need at least two uKey') unless ( $uKeyCount > 1 );

if ( $method eq 'weight' ) {
  my ( @_uKeys, $totalWeight );

  foreach $_uKey ( @uKeys ) {
    my ($uKey, $weight) = split ( /%/, $_uKey );
    $objectPlugins->printUsage ( 'Clusters need a weight for each uKey') unless ( defined $weight );
    push (@_uKeys, $uKey);
    $totalWeight += $weight;
    $uKeys{$uKey}{weight} = $weight;
  }

  $objectPlugins->printUsage ( 'Clusters total weight must equals 100%') unless ( $totalWeight == 100 );
  @uKeys = @_uKeys;
}

my ( $warning, $critical, $downgradingStatus );

if ( $method =~ /^(?:non-OK|percentage|weight)$/ ) {
  $warning            = $objectPlugins->getOptionsArgv ('warning');
  $critical           = $objectPlugins->getOptionsArgv ('critical');

  if ( $method eq 'non-OK' ) {
    $objectPlugins->printUsage ( 'Critical threshold ' .$critical. ' should be larger than warning threshold ' .$warning ) unless ( $critical > $warning );
    $objectPlugins->printUsage ( 'Warning threshold should be less than count uKey' ) unless ( $warning < $uKeyCount );
    $objectPlugins->printUsage ( 'Critical threshold should be less or equal than count uKey' ) unless ( $critical <= $uKeyCount );

    $downgradingStatus  =  $objectPlugins->getOptionsArgv ('downgradingStatus') ? $objectPlugins->getOptionsArgv ('downgradingStatus') : 'T';
    $objectPlugins->printUsage ( 'Command line parameters for downgradingStatus: F(alse) or T(rue)' ) unless ( $downgradingStatus =~ /^[FT]$/ );
  } elsif ( $method eq 'percentage' ) {
    $objectPlugins->printUsage ( 'Warning percentage should be less or equal than 100' ) unless ( $warning <= 100 );
    $objectPlugins->printUsage ( 'Critical percentage should be less or equal than 100' ) unless ( $critical <= 100 );
  } elsif ( $method eq 'weight' ) {
    $objectPlugins->printUsage ( 'Critical weight ' .$critical. ' should be larger than warning weight ' .$warning ) unless ( $critical > $warning );
  }
}

my $outOfDate         =  $objectPlugins->getOptionsArgv ('outOfDate');
$objectPlugins->printUsage ( 'Missing command line argument out of date' ) unless ( defined $outOfDate );
$outOfDate *= 60; # convert to seconds

my $ignoreDependent   =  $objectPlugins->getOptionsArgv ('ignoreDependent')   ? $objectPlugins->getOptionsArgv ('ignoreDependent')   : 'F';
$objectPlugins->printUsage ( 'Command line parameters for ignoreDependent: F(alse) or T(rue)' ) unless ( $ignoreDependent  =~ /^[FT]$/ );

my $ignoreOffline     =  $objectPlugins->getOptionsArgv ('ignoreOffline')     ? $objectPlugins->getOptionsArgv ('ignoreOffline')     : 'F';
$objectPlugins->printUsage ( 'Command line parameters for ignoreOffline: F(alse) or T(rue)' ) unless ( $ignoreOffline =~ /^[FT]$/ );

my $ignoreNoTest      =  $objectPlugins->getOptionsArgv ('ignoreNoTest')      ? $objectPlugins->getOptionsArgv ('ignoreNoTest')      : 'F';
$objectPlugins->printUsage ( 'Command line parameters for ignoreNoTest: F(alse) or T(rue)' ) unless ( $ignoreNoTest =~ /^[FT]$/ );

my $serverDB          = $objectPlugins->getOptionsArgv ('server')   ? $objectPlugins->getOptionsArgv ('server')   : 'localhost';
my $port              = $objectPlugins->getOptionsArgv ('port')     ? $objectPlugins->getOptionsArgv ('port')     : 3306;
my $database          = $objectPlugins->getOptionsArgv ('database') ? $objectPlugins->getOptionsArgv ('database') : 'asnmtap';
my $username          = $objectPlugins->getOptionsArgv ('username') ? $objectPlugins->getOptionsArgv ('username') : 'asnmtap';
my $password          = $objectPlugins->getOptionsArgv ('password') ? $objectPlugins->getOptionsArgv ('password') : '<PASSWORD>';

my $debug             = $objectPlugins->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

foreach $_uKey ( @uKeys ) { $uKeys{$_uKey}{status} = $ERRORS{'NO DATA'}; }
foreach $_status ( $ERRORS{'OK'} .. $ERRORS{'NO DATA'} ) { $status{$STATE{$_status}} = 0; }
$cluster{non_OK} = 0; foreach $_status ( $ERRORS{'OK'} .. $ERRORS{UNKNOWN} ) { $cluster{$STATE{$_status}} = 0; }
foreach $_status ( $ERRORS{OK} .. $ERRORS{CRITICAL} ) { $weight{$STATE{$_status}} = 0; };

my ( $dbh, $sth );

$dbh = DBI->connect ("DBI:mysql:$database:$serverDB:$port", "$username", "$password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );

if ( $dbh ) {
  my $rv = 1;

  foreach $_uKey ( keys ( %uKeys ) ) {
    my ($catalogID, $id, $uKey, $status, $step, $timeslot, $instability, $persistent, $downtime);

    my $sqlSTRING = "SELECT catalogID, id, uKey, status, step, timeslot, instability, persistent, downtime FROM `events` WHERE catalogID='$CATALOGID' and uKey='$_uKey' ORDER BY timeslot DESC LIMIT 1";
    $sth = $dbh->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->prepare: '. $sqlSTRING );
    $sth->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
    $sth->bind_columns( \$catalogID, \$id, \$uKey, \$status, \$step, \$timeslot, \$instability, \$persistent, \$downtime ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->bind: '. $sqlSTRING ) if $rv;
    print "$CATALOGID & $_uKey\n    $sqlSTRING\n" if ( $debug );

    if ( $rv ) {
      if ( $sth->rows ) {
        my $currentTimeslot = timelocal ( (localtime)[0,1,2,3,4,5] );

        while( $sth->fetch() ) {
          $objectPlugins->appendPerformanceData ( "'$uKey'=" .$ERRORS{$status}. ';1;2;0;7' );

          $uKeys{$uKey}{id}          = $id;
          $uKeys{$uKey}{uKey}        = $uKey;
          $uKeys{$uKey}{status}      = $status;
          $uKeys{$uKey}{step}        = $step;
          $uKeys{$uKey}{timeslot}    = $timeslot;
          $uKeys{$uKey}{instability} = $instability;
          $uKeys{$uKey}{persistent}  = $persistent;
          $uKeys{$uKey}{downtime}    = $downtime;
          print "$catalogID, $id, $uKey, $status, $step, $timeslot, $instability, $persistent, $downtime\n" if ( $debug );

          if ( $currentTimeslot - $timeslot > $outOfDate ) {
            $objectPlugins->pluginValues ( { alert => "Result for $uKey out of date: $currentTimeslot - $timeslot > $outOfDate" }, $TYPE{APPEND} );
            $status = $STATE{$ERRORS{UNKNOWN}};
          } elsif ( $status eq $STATE{$ERRORS{DEPENDENT}} and $ignoreDependent eq 'T' ) {
            $objectPlugins->pluginValues ( { alert => "Result for $uKey ignored: $status" }, $TYPE{APPEND} );
            $status = $STATE{$ERRORS{OK}};
          } elsif ( $status eq $STATE{$ERRORS{OFFLINE}} and $ignoreOffline eq 'T' ) {
            $objectPlugins->pluginValues ( { alert => "Result for $uKey ignored: $status" }, $TYPE{APPEND} );
            $status = $STATE{$ERRORS{OK}};
          } elsif ( $status eq $STATE{$ERRORS{'NO TEST'}} and $ignoreNoTest eq 'T' ) {
            $objectPlugins->pluginValues ( { alert => "Result for $uKey ignored: $status" }, $TYPE{APPEND} );
            $status = $STATE{$ERRORS{OK}};
          }

          $status{$status}++;

          if ( $status eq 'OK' ) { 
		    $cluster{OK}++; 
          } else {
            $cluster{non_OK}++;

            if ( $status =~ /^(?:WARNING|CRITICAL)$/ ) {
		      $cluster{$status}++;
            } else {
              $cluster{UNKNOWN}++;
            }
          }

          if ( $method eq 'weight' ) {
            if ( $status eq 'OK' ) { 
              $weight{OK} += $uKeys{$uKey}{weight};
            } elsif ( $status eq 'WARNING' ) {
              $weight{WARNING}  += $uKeys{$uKey}{weight};
            } else {
              $weight{CRITICAL} += $uKeys{$uKey}{weight};
            }
          }
        }
      } else {
        $status{'NO DATA'}++;
        $objectPlugins->pluginValues ( { stateValue => $ERRORS{'UNKNOWN'}, alert => "No result for '$_uKey'" }, $TYPE{APPEND} );
      }

      $sth->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->finish: '. $sqlSTRING );
    }
  }

  $dbh->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );
}

if ( $debug ) {
  foreach $_uKey ( keys ( %uKeys ) ) {
    print "\n--> $_uKey\n";

    while ( my ($key, $value) = each ( %{$uKeys{$_uKey}} ) ) {
      print "    $key => $value\n";
    }
  }

  print "\nStatus:\n"; while ( my ($key, $value) = each ( %status ) ) { print "$key => $value\n"; }
  print "\nCluster:\n"; while ( my ($key, $value) = each ( %cluster ) ) { print "$key => $value\n"; }
  print "\nWeight:\n"; while ( my ($key, $value) = each ( %weight ) ) { print "$key => $value\n"; }
}

my $clusterStatus = $method . ' method: ';

for ( $method ) {
  /^highest-status$/ && do {
    my $highestStatus = ( ( $cluster{DEPENDENT} ) ? $cluster{DEPENDENT} : ( ( $cluster{UNKNOWN} ) ? $STATE{$ERRORS{UNKNOWN}} : ( ( $cluster{CRITICAL} ) ? $STATE{$ERRORS{CRITICAL}} : ( ( $cluster{WARNING} ) ? $STATE{$ERRORS{WARNING}} : $STATE{$ERRORS{OK}} ) ) ) );
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{$highestStatus}, alert => $clusterStatus . $highestStatus }, $TYPE{APPEND} );
    last;
  };
  /^non-OK$/ && do {
    unless ( $cluster{non_OK} ) {
      $objectPlugins->pluginValues ( { stateValue => $ERRORS{OK}, alert => $clusterStatus . 'OK' }, $TYPE{APPEND} );
    } elsif ( $status{OFFLINE} == $uKeyCount ) {
      $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $clusterStatus . 'OFFLINE' }, $TYPE{APPEND} );
    } elsif ( $status{'NO TEST'} == $uKeyCount ) {
      $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $clusterStatus . 'NO TEST' }, $TYPE{APPEND} );
    } else {
      if ( $critical and $cluster{non_OK} >= $critical ) {
        if ( $downgradingStatus eq 'T' and $cluster{non_OK} == $cluster{WARNING} ) {
          $objectPlugins->pluginValues ( { stateValue => $ERRORS{WARNING}, alert => $clusterStatus . 'WARNING - Performance degraded' }, $TYPE{APPEND} );
        } else {
          $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => $clusterStatus . 'CRITICAL - Service unavailable' }, $TYPE{APPEND} );
        }
      } elsif ( $warning and $cluster{non_OK} >= $warning ) {
        $objectPlugins->pluginValues ( { stateValue => $ERRORS{WARNING}, alert => $clusterStatus . 'WARNING - Performance degraded' }, $TYPE{APPEND} );
      } else {
        $objectPlugins->pluginValues ( { stateValue => $ERRORS{OK}, alert => $clusterStatus . 'OK' }, $TYPE{APPEND} );
      }
    }

    last;
  };
  /^percentage$/ && do {
    my $clusterCRITICAL    = $uKeyCount - $cluster{OK} - $cluster{WARNING};
    my $percentageCRITICAL = ( $clusterCRITICAL / $uKeyCount ) * 100;
    my $percentageWARNING  = ( $cluster{WARNING} / $uKeyCount ) * 100;
    my $percentageStatus   = ( ( $percentageCRITICAL >= $critical ) ? $STATE{$ERRORS{CRITICAL}} : ( ( $percentageCRITICAL + $percentageWARNING >= $warning ) ? $STATE{$ERRORS{WARNING}} : $STATE{$ERRORS{OK}} ) );

    $clusterStatus .= 'WARNING ' .$percentageWARNING. '% - CRITICAL ' .$percentageCRITICAL. '% : ';
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{$percentageStatus}, alert => $clusterStatus . $percentageStatus }, $TYPE{APPEND} );
    $objectPlugins->appendPerformanceData ( 'WARNING=' .$percentageWARNING. '"%;' .$warning. ';;; CRITICAL=' .$percentageCRITICAL. '%;' .$critical. ';;;' );
    last;
  };
  /^weight$/ && do {
    my $weightStatus = ( ( $weight{CRITICAL} >= $critical ) ? $STATE{$ERRORS{CRITICAL}} : ( ( $weight{CRITICAL} + $weight{WARNING} >= $warning ) ? $STATE{$ERRORS{WARNING}} : $STATE{$ERRORS{OK}} ) );

    $clusterStatus .= 'WARNING ' .$weight{WARNING}. '% - CRITICAL ' .$weight{CRITICAL}. '% : ';
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{$weightStatus}, alert => $clusterStatus . $weightStatus }, $TYPE{APPEND} );
    $objectPlugins->appendPerformanceData ( 'WARNING=' .$weight{WARNING}. '"%;' .$warning. ';;; CRITICAL=' .$weight{CRITICAL}. '%;' .$critical. ';;;' );
    last;
  };

  $objectPlugins->exit (0);
}

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _ErrorTrapDBI {
  my ($asnmtapInherited, $error_message) = @_;

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $error_message, error => "$DBI::err ($DBI::errstr)" }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-cluster.pl

Cluster plugin template for the 'Application Monitor'

The ASNMTAP plugins come with ABSOLUTELY NO WARRANTY.

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut
