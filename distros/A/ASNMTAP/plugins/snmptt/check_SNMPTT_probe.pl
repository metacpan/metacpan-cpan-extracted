#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_SNMPTT_probe.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduce a little process speed
#use diagnostics;       # Must be used in test mode only. This reduce a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_SNMPTT_probe.pl',
  _programDescription => 'Control SNMPTT TRAPs',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[-s|--server=<hostname>] [--database=<database>]',
  _programHelpPrefix  => '-s, --server=<hostname> (default: localhost)
--database=<database> (default: snmptt)',
  _programGetOptions  => ['community|C=s', 'host|H=s', 'server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e=s', 'proxy:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $community    = $objectPlugins->getOptionsArgv ('community') ? $objectPlugins->getOptionsArgv ('community') : '';
$objectPlugins->printUsage ('Missing command line argument community') unless ( defined $community);

my $hostname     = $objectPlugins->getOptionsArgv ('host');
my $eventname    = 'ucdStart';
my $category     = 'Status Events';
my $severity     = 'OK';
my $formatline   = 'This trap could in principle be sent when the agent start (ASNMTAP-CONTROL-SNMPTT-TRAP)';

my $environment  = $objectPlugins->getOptionsArgv ('environment');

my $debug        = $objectPlugins->getOptionsValue ('debug');
my $onDemand     = $objectPlugins->getOptionsValue ('onDemand');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $serverHost   = $objectPlugins->getOptionsArgv ('server')   ? $objectPlugins->getOptionsArgv ('server')   : 'localhost';
my $serverPort   = $objectPlugins->getOptionsArgv ('port')     ? $objectPlugins->getOptionsArgv ('port')     : 3306;
my $serverUser   = $objectPlugins->getOptionsArgv ('username') ? $objectPlugins->getOptionsArgv ('username') : 'asnmtap';
my $serverPass   = $objectPlugins->getOptionsArgv ('password') ? $objectPlugins->getOptionsArgv ('password') : '<PASSWORD>';
my $serverDb     = $objectPlugins->getOptionsArgv ('database') ? $objectPlugins->getOptionsArgv ('database') : 'snmptt';

my $serverTact   = 'snmptt';
my $serverTarc   = 'snmptt_archive';
my $outOffDate   = 300;                                        # seconds

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $message = $objectPlugins->pluginValue ('message') .' for host '. $hostname;
$objectPlugins->pluginValue ( message => $message );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $snmptrap = 'snmptrap -v 2c -c '. $community .' '. $hostname .':162 "" ucdStart sysContact.0 s "ASNMTAP-CONTROL-SNMPTT-TRAP"';
print "$snmptrap\n" if ( $debug );

if ( $objectPlugins->call_system ( $snmptrap, 1 ) ) {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => 'ASNMTAP CONTROL SNMPTT TRAPs not sended' }, $TYPE{APPEND} );
  $objectPlugins->exit (7);
}

# Amount of time in seconds to sleep between processing spool files + 2 (snmptt.ini)
sleep 7;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($dbh, $sth, $sthDO, $rv, $query);
$rv = 1;

$dbh = DBI->connect ( "dbi:mysql:$serverDb:$serverHost:$serverPort", "$serverUser", "$serverPass" ) or $rv = errorTrapDBI ( \$objectPlugins,  'Sorry, cannot connect to the database' );

if ( $dbh and $rv ) {
  my ($id, $eventid, $trapoid, $enterprise, $agentip, $uptime, $traptime, $system_running_SNMPTT, $trapread);

# $query = "SELECT SQL_NO_CACHE id, eventid, trapoid, enterprise, agentip, uptime, traptime, system_running_SNMPTT, trapread FROM `$serverTact` WHERE system_running_SNMPTT='$hostname' and community='$community' and eventname='$eventname' and category='$category' and severity='$severity' and formatline='$formatline' order by id desc";
  $query = "SELECT SQL_NO_CACHE id, eventid, trapoid, enterprise, agentip, uptime, traptime, system_running_SNMPTT, trapread FROM `$serverTact` WHERE system_running_SNMPTT='$hostname' and community='' and eventname='$eventname' and category='$category' and severity='$severity' and formatline='$formatline' order by id desc";
  print $query, "\n" if ( $debug );
  $sth = $dbh->prepare($query) or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot dbh->prepare: '. $query ) if ( $rv );
  $rv  = $sth->execute() or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot sth->execute: '. $query ) if ( $rv );
  $sth->bind_columns( \$id, \$eventid, \$trapoid, \$enterprise, \$agentip, \$uptime, \$traptime, \$system_running_SNMPTT, \$trapread ) or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot sth->bind_columns: '. $query ) if ( $rv );

  if ( $rv ) {
    if ( $sth->rows() ) {
      my $firstTrap;

      while( $sth->fetch() ) {
        if ( $debug >= 2 ) {
          print "\nid           : $id\neventname    : $eventname\neventid      : $eventid\ntrapoid      : $trapoid\nenterprise   : $enterprise\ncommunity    : $community\nhostname     : $hostname\nagentip      : $agentip\ncategory     : $category\nseverity     : $severity\nuptime       : $uptime\ntraptime     : $traptime\nformatline   : $formatline\nsystem SNMPTT: $system_running_SNMPTT\ntrapread     : $trapread\n";
        } elsif ( $debug ) {
          print "\n$id, $eventname, $eventid, $trapoid, $enterprise, $community, $hostname, $agentip, $category, $severity, $uptime, $traptime, $formatline, $system_running_SNMPTT, $trapread\n";
        }

        unless ( defined $firstTrap ) {
          $firstTrap = 1;

          my $currentTimeslot = timelocal ( 0, (localtime)[1,2,3,4,5] );

          use Date::Manip;
          my $epochtime = UnixDate ( ParseDate ( $traptime ), "%s" );

          if ($currentTimeslot - $epochtime > $outOffDate) {
            my $alert .= ' - Data is out of date!';
            $alert .= ' - From: ' .scalar(localtime($epochtime)). ' - Now: ' .scalar(localtime($currentTimeslot)) if ( $debug >= 2 );
            $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => $alert }, $TYPE{APPEND} );
          } else {
            $objectPlugins->pluginValues ( { stateValue => $ERRORS{OK}, alert => 'OK' }, $TYPE{APPEND} );
          }
        }

        unless ( $onDemand ) {
          my $sqlINSERT = "REPLACE INTO `$serverTarc` SELECT * FROM `$serverTact` WHERE id='$id'";
          print "             + $sqlINSERT\n" if ( $debug );
          $dbh->do ( $sqlINSERT ) or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot dbh->do: '. $sqlINSERT );

          my $sqlDELETE = "DELETE FROM `$serverTact` WHERE id='$id'";
          print "             - $sqlDELETE\n" if ( $debug );
          $dbh->do( $sqlDELETE ) or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot dbh->do: '. $sqlDELETE );
        }
      }
    } else {
      $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => 'ASNMTAP CONTROL SNMPTT TRAPs missing' }, $TYPE{APPEND} );
    }

    $sth->finish() or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot sth->finish: '. $query );
  } 

  $dbh->disconnect() or $rv = errorTrapDBI ( \$objectPlugins,  'The database $serverDb was unable to read your entry.' );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapDBI {
  my ($asnmtapInherited, $error_message) = @_;

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $error_message, error => "$DBI::err ($DBI::errstr)" }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

