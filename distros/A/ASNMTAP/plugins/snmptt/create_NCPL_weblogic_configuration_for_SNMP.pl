#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, create_NCPL_weblogic_configuration_for_SNMP.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Data::Dumper;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.002.003;
use ASNMTAP::Time qw(&get_datetimeSignal);

use ASNMTAP::Asnmtap::Applications v3.002.003;
use ASNMTAP::Asnmtap::Applications qw(&sending_mail $SERVERLISTSMTP $SENDMAILFROM);

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS $SENDEMAILTO);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'create_NCPL_weblogic_configuration_for_SNMP.pl',
  _programDescription => 'Create NCPL weblogic configuration for SNMP',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[-s|--server=<hostname>] [--database=<database>] [--_server=<hostname>] [--_database=<database>] [--_port=<port>] [--_username=<username>] [--_password=<password>]',
  _programHelpPrefix  => "-s, --server=<hostname> (default: localhost)
--database=<database> (default: weblogicConfig)
--_server=<hostname> (default: localhost)
--_database=<database> (default: NCPL)
--_port=<port>
--_username=<username>
--_password=<password>",
  _programGetOptions  => ['_server:s', '_port:i', '_database:s', '_username|_loginname:s', '_password|_passwd:s', 'server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e:s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $serverDB  = $objectPlugins->getOptionsArgv ('server')    ? $objectPlugins->getOptionsArgv ('server')    : 'localhost';
my $port      = $objectPlugins->getOptionsArgv ('port')      ? $objectPlugins->getOptionsArgv ('port')      : 3306;
my $database  = $objectPlugins->getOptionsArgv ('database')  ? $objectPlugins->getOptionsArgv ('database')  : 'weblogicConfig';
my $username  = $objectPlugins->getOptionsArgv ('username')  ? $objectPlugins->getOptionsArgv ('username')  : 'jUnit';
my $password  = $objectPlugins->getOptionsArgv ('password')  ? $objectPlugins->getOptionsArgv ('password')  : '<PASSWORD>';

my $_serverDB = $objectPlugins->getOptionsArgv ('_server')   ? $objectPlugins->getOptionsArgv ('_server')   : 'localhost';
my $_port     = $objectPlugins->getOptionsArgv ('_port')     ? $objectPlugins->getOptionsArgv ('_port')     : 3306;
my $_database = $objectPlugins->getOptionsArgv ('_database') ? $objectPlugins->getOptionsArgv ('_database') : 'ncpl';
my $_username = $objectPlugins->getOptionsArgv ('_username') ? $objectPlugins->getOptionsArgv ('_username') : 'ncpl';
my $_password = $objectPlugins->getOptionsArgv ('_password') ? $objectPlugins->getOptionsArgv ('_password') : '<PASSWORD>';

my $debug    = $objectPlugins->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $returnCode   = $ERRORS{OK};
my $alert        = 'OK';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $server_name         = 'snmpProbe01,snmpProbe02,distributedServer01,distributedServer02';
my $contact_groups      = 'middleware,supervision';
my $category            = '_SNMPTT_WEBLOGIC';
my $host_Description    = 'wls';
my $service_Description = 'check snmp traps';
my $use_hosts           = 'generic-host';
my $use_services        = 'snmptt-service';
my $check_command       = 'check_host_null_14x';
my $timeperiod_acc      = 'tp_acceptation';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ( $dbhWEBLOGIC, $sthWEBLOGIC, $dbhNCPL, $sthNCPL, $prepareString, $nagiosCommands );

$dbhWEBLOGIC = DBI->connect ("DBI:mysql:$database:$serverDB:$port", "$username", "$password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );
$dbhNCPL = DBI->connect ("DBI:mysql:$_database:$_serverDB:$_port", "$_username", "$_password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $_serverDB, "$DBI::err ($DBI::errstr)" );

if ( $dbhWEBLOGIC and $dbhNCPL ) {
  my ($rv, $sqlDELETE);

  $rv = 1; $sqlDELETE = "DELETE FROM nagios_hosts WHERE category = '_SNMPTT_WEBLOGIC'";
  print "    $sqlDELETE\n" if ( $debug );
  $dbhNCPL->do( $sqlDELETE ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->do: '. $sqlDELETE ) if $rv;

  $rv = 1; $sqlDELETE = "DELETE FROM nagios_services WHERE category = '_SNMPTT_WEBLOGIC'";
  print "    $sqlDELETE\n" if ( $debug );
  $dbhNCPL->do( $sqlDELETE ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->do: '. $sqlDELETE ) if $rv;

  my ( $domainname, $virtual_servername, $hosts, $community, $environment, $activated );

  my $sqlSTRING = "SELECT distinct ADMIN_CONFIG.ADMIN_NAME AS domainname, SERVERS.SERVER_NAME AS virtual_servername, ADMIN_CONFIG.HOSTS AS hosts, ADMIN_CONFIG.community AS community, ADMIN_CONFIG.ENV AS environment, ADMIN_CONFIG.activated FROM `ADMIN_CONFIG`, `SERVERS`, `CLUSTERS` WHERE ( SERVERS.DOMAIN_NAME = concat('Domain\:', ADMIN_CONFIG.ADMIN_NAME) or SERVERS.DOMAIN_NAME = concat('DOMAIN\:', ADMIN_CONFIG.ADMIN_NAME) ) AND ADMIN_CONFIG.ENV = SERVERS.ENV AND SERVERS.ENV = CLUSTERS.ENV ORDER BY domainname, virtual_servername, hosts";
  print "    $sqlSTRING\n" if ( $debug );

  $sthWEBLOGIC = $dbhWEBLOGIC->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
  $sthWEBLOGIC->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
  $sthWEBLOGIC->bind_columns( \$domainname, \$virtual_servername, \$hosts, \$community, \$environment, \$activated ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

  if ( $rv ) {
    while( $sthWEBLOGIC->fetch() ) {
      if ( $activated ) {
        if ( $community eq $domainname or $community =~ /snmp_${domainname}/ or $community =~ /v10_${domainname}/ ) {
          my $host_name  = $host_Description .'_'. $domainname;
          my $service_description = "$service_Description [$virtual_servername]";
          my $timeperiod = ( $environment =~ /PROD/ ? '' : $timeperiod_acc );

          my $sqlCOUNT = "SELECT count(host_name) FROM nagios_hosts WHERE host_name = '$host_name'";
          print "    $sqlCOUNT\n" if ( $debug );
          $sthNCPL = $dbhNCPL->prepare($sqlCOUNT) or $rv = _ErrorTrapDBI ( 'dbh->prepare '. $sqlCOUNT, "$DBI::err ($DBI::errstr)" );
          $sthNCPL->execute or $rv = _ErrorTrapDBI ( 'sth->execute '. $sqlCOUNT, "$DBI::err ($DBI::errstr)" );
          my $existingHost = $sthNCPL->fetchrow_array();
          $sthNCPL->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlCOUNT );

          unless ( $existingHost ) {
            my $sqlINSERT = "INSERT INTO nagios_hosts SET server_name='$server_name', category='$category', environments='$environment', nslookup=0, synchronize=0, virtual=1, host_name='$host_name', alias='$domainname - $environment', `use`='$use_hosts', address='$hosts', check_command='$check_command', contact_groups='$contact_groups', check_period = '$timeperiod', notification_period = '$timeperiod', register=1, enabled=1";
            print "    $sqlINSERT\n" if ( $debug );
            $dbhNCPL->do( $sqlINSERT ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->do: '. $sqlINSERT ) if $rv;
            $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => "'$host_name' doesn't EXIST" }, $TYPE{APPEND} ) unless $rv;
          }

          $nagiosCommands .= '['. time() .'] PROCESS_SERVICE_CHECK_RESULT;' .$host_name. ';' .$service_description. ';0;Manual reset' ."\n";

          my $sqlINSERT = "INSERT INTO nagios_services SET server_name = '$server_name', category = '$category', host_name = '$host_name', service_description = '$service_description', `use` = '$use_services', contact_groups = '$contact_groups', check_period = '$timeperiod', notification_period = '$timeperiod', register = 1, enabled = $activated";
          print "    $sqlINSERT\n" if ( $debug );
          $dbhNCPL->do( $sqlINSERT ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->do: '. $sqlINSERT ) if $rv;
        } else {
          $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => "$community <> snmp_${domainname} and $community <> v10_${domainname}" }, $TYPE{APPEND} );
        }
      }
    }

    $sthWEBLOGIC->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
  }
}

$dbhNCPL->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $_serverDB, "$DBI::err ($DBI::errstr)" ) if ( $dbhNCPL );
$dbhWEBLOGIC->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" ) if ( $dbhWEBLOGIC );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValues ( { stateValue => $returnCode, alert => $alert }, $TYPE{APPEND} );

if ( defined $nagiosCommands ) {
  unless ( sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, 'Nagios Commands Manual Reset: '. get_datetimeSignal(), $nagiosCommands, $debug ) ) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Problem sending email to the System Administrators" }, $TYPE{APPEND} );
  }
}

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _ErrorTrapDBI {
  my ($asnmtapInherited, $error_message) = @_;

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $error_message, error => "$DBI::err ($DBI::errstr)" }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
