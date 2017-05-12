#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, create_weblogic_configuration_for_SNMPTT.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.002.003;
use ASNMTAP::Time qw(&get_datetimeSignal);

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'create_weblogic_configuration_for_SNMPTT.pl',
  _programDescription => 'Create weblogic configuration for SNMPTT',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[-s|--server=<hostname>] [--database=<database>]',
  _programHelpPrefix  => "-s, --server=<hostname> (default: localhost)
--database=<database> (default: weblogicConfig)",
  _programGetOptions  => ['filename|F=s', 'server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e:s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $serverDB  = $objectPlugins->getOptionsArgv ('server')    ? $objectPlugins->getOptionsArgv ('server')    : 'localhost';
my $port      = $objectPlugins->getOptionsArgv ('port')      ? $objectPlugins->getOptionsArgv ('port')      : 3306;
my $database  = $objectPlugins->getOptionsArgv ('database')  ? $objectPlugins->getOptionsArgv ('database')  : 'weblogicConfig';
my $username  = $objectPlugins->getOptionsArgv ('username')  ? $objectPlugins->getOptionsArgv ('username')  : 'jUnit';
my $password  = $objectPlugins->getOptionsArgv ('password')  ? $objectPlugins->getOptionsArgv ('password')  : '<PASSWORD>';

my $filename  = $objectPlugins->getOptionsArgv ('filename');

my $debug     = $objectPlugins->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $configPathSNMPTT = '/etc/snmp';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ( $dbh, $sth, $prepareString, $nagiosCommands );

$dbh = DBI->connect ("DBI:mysql:$database:$serverDB:$port", "$username", "$password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );

if ( $dbh ) {
  my $rv = open(SNMPTT, ">$filename");

  if ($rv) {
    my ( $trapMBeanType, $trapMBeanType_MATCH, $trapAttributeName, $trapAttributeName_MATCH, $trapMonitorType, $trapMonitorType_MATCH, $trapLogSeverity, $trapLogSeverity_MATCH, $trapLogMessage, $trapLogMessage_MATCH, $snmpgetOID, $destination, $event_name, $category, $severity, $event_OID, $format_string, $command_string, $regular_expression, $sources_list, $mode, $description, $activated );
    my $sqlSTRING = "SELECT trapMBeanType, trapMBeanType_MATCH, trapAttributeName, trapAttributeName_MATCH, trapMonitorType, trapMonitorType_MATCH, trapLogSeverity, trapLogSeverity_MATCH, trapLogMessage, trapLogMessage_MATCH, snmpgetOID, destination, wls_snmptt_CONFIG.event_name, category, severity, event_OID, format_string, command_string, regular_expression, sources_list, mode, description, activated FROM `wls_snmptt_CONFIG`, `wls_snmp_CONFIG` WHERE activated='1' and wls_snmptt_CONFIG.event_name = wls_snmp_CONFIG.event_name order by event_OID, trapMBeanType, trapAttributeName, trapMonitorType";
    print "    $sqlSTRING\n" if ( $debug );

    $sth = $dbh->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->prepare: '. $sqlSTRING );
    $sth->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
    $sth->bind_columns( \$trapMBeanType, \$trapMBeanType_MATCH, \$trapAttributeName, \$trapAttributeName_MATCH, \$trapMonitorType, \$trapMonitorType_MATCH, \$trapLogSeverity, \$trapLogSeverity_MATCH, \$trapLogMessage, \$trapLogMessage_MATCH, \$snmpgetOID, \$destination, \$event_name, \$category, \$severity, \$event_OID, \$format_string, \$command_string, \$regular_expression, \$sources_list, \$mode, \$description, \$activated ) or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

    my $EVENTBLOK = "#\n# MIB: BEA-WEBLOGIC-MIB generated on ". get_datetimeSignal() ."\n#\n";
    my $prev_event_name = '';

    if ( $rv ) {
      while( $sth->fetch() ) {
        my $comment = ( $activated ? '' : '# ' );
        my ($AND, $MATCH) = (-1, undef);
 
        $EVENTBLOK .= ( $prev_event_name eq $event_name ? "###\n" : "# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n" );
	    $EVENTBLOK .= "#\n" . $comment . "EVENT $event_name $event_OID \"$category\" $severity\n";

        if ( defined $trapMonitorType_MATCH and defined $trapMonitorType and $trapMonitorType_MATCH and $trapMonitorType ) {
          $MATCH .= "MATCH $trapMonitorType_MATCH: ($trapMonitorType)\n";
          $AND++;
        }

        if ( defined $trapMBeanType_MATCH and defined $trapMBeanType and $trapMBeanType_MATCH and $trapMBeanType ) {
          $MATCH .= "MATCH $trapMBeanType_MATCH: ($trapMBeanType)\n";
          $AND++;
        }

        if ( defined $trapAttributeName_MATCH and defined $trapAttributeName and $trapAttributeName_MATCH and $trapAttributeName ) {
          $MATCH .= "MATCH $trapAttributeName_MATCH: ($trapAttributeName)\n";
          $AND++;
        }

        if ( defined $trapLogSeverity_MATCH and defined $trapLogSeverity and $trapLogSeverity_MATCH and $trapLogSeverity ) {
          $MATCH .= "MATCH $trapLogSeverity_MATCH: ($trapLogSeverity)\n";
          $AND++;
        }

        if ( defined $trapLogMessage_MATCH and defined $trapLogMessage and $trapLogMessage_MATCH and $trapLogMessage ) {
          $MATCH .= "MATCH $trapLogMessage_MATCH: ($trapLogMessage)\n";
          $AND++;
        }

        if ( defined $MATCH ) {
          $EVENTBLOK .= "MATCH MODE=and\n" if ( $AND );
          $EVENTBLOK .= $MATCH;
        }

        $EVENTBLOK .= "FORMAT $format_string\n" if ( defined $format_string and $format_string );
        $EVENTBLOK .= "EXEC $command_string\n" if ( defined $command_string and $command_string );
        $EVENTBLOK .= "REGEX $regular_expression\n" if ( defined $regular_expression and $regular_expression );
        $EVENTBLOK .= "NODES $configPathSNMPTT/$sources_list\nNODES MODE=$mode\n" if ( defined $sources_list and defined $mode and $sources_list and $mode);
        $EVENTBLOK .= "SDESC\n$description\nEDESC\n" if ( defined $description and $description );
        $EVENTBLOK .= "#\n";

        $prev_event_name = $event_name;
      }

      $sth->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins,  'Cannot sth->finish: '. $sqlSTRING );
    }

    $EVENTBLOK .= "# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #\n";
    print $EVENTBLOK if ( $debug );
    print SNMPTT $EVENTBLOK;
    close(SNMPTT);
  } else {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => 'SNMPTT config file', error => 'Cannot create: ' . $filename }, $TYPE{APPEND} );
  }

  $dbh->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValues ( { stateValue => $ERRORS{OK}, alert => 'Database: OK' }, $TYPE{APPEND} );
$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _ErrorTrapDBI {
  my ($asnmtapInherited, $error_message) = @_;

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $error_message, error => "$DBI::err ($DBI::errstr)" }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

