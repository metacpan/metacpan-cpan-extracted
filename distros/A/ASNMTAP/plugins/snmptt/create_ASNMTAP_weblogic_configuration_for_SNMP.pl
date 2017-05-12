#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, create_ASNMTAP_weblogic_configuration_for_SNMP.pl
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
use ASNMTAP::Asnmtap::Applications qw($CATALOGID &sending_mail $SERVERLISTSMTP $SENDMAILFROM);

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS $SENDEMAILTO);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'create_ASNMTAP_weblogic_configuration_for_SNMP.pl',
  _programDescription => 'Create ASNMTAP weblogic configuration for SNMP',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[--update] [--hostname] [--domain=<domain>] [-s|--server=<hostname>] [--database=<database>] [--_server=<hostname>] [--_database=<database>] [--_port=<port>] [--_username=<username>] [--_password=<password>]',
  _programHelpPrefix  => "--update
--hostname
--domain=<domain> (default: citap.be)
-s, --server=<hostname> (default: localhost)
--database=<database> (default: weblogicConfig)
--_server=<hostname> (default: localhost)
--_database=<database> (default: asnmtap)
--_port=<port>
--_username=<username>
--_password=<password>",
  _programGetOptions  => ['update', 'hostname', 'domain:s', '_server:s', '_port:i', '_database:s', '_username|_loginname:s', '_password|_passwd:s', 'server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e:s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $update     = $objectPlugins->getOptionsArgv ('update')    ? $objectPlugins->getOptionsArgv ('update')    : undef;

my $hostname   = $objectPlugins->getOptionsArgv ('hostname')  ? $objectPlugins->getOptionsArgv ('hostname')  : undef;
my $domain     = $objectPlugins->getOptionsArgv ('domain')    ? $objectPlugins->getOptionsArgv ('domain')    : 'citap.be';

my $serverDB   = $objectPlugins->getOptionsArgv ('server')    ? $objectPlugins->getOptionsArgv ('server')    : 'localhost';
my $port       = $objectPlugins->getOptionsArgv ('port')      ? $objectPlugins->getOptionsArgv ('port')      : 3306;
my $database   = $objectPlugins->getOptionsArgv ('database')  ? $objectPlugins->getOptionsArgv ('database')  : 'weblogicConfig';
my $username   = $objectPlugins->getOptionsArgv ('username')  ? $objectPlugins->getOptionsArgv ('username')  : 'jUnit';
my $password   = $objectPlugins->getOptionsArgv ('password')  ? $objectPlugins->getOptionsArgv ('password')  : '<PASSWORD>';

my $_serverDB  = $objectPlugins->getOptionsArgv ('_server')   ? $objectPlugins->getOptionsArgv ('_server')   : 'localhost';
my $_port      = $objectPlugins->getOptionsArgv ('_port')     ? $objectPlugins->getOptionsArgv ('_port')     : 3306;
my $_database  = $objectPlugins->getOptionsArgv ('_database') ? $objectPlugins->getOptionsArgv ('_database') : 'asnmtap';
my $_username  = $objectPlugins->getOptionsArgv ('_username') ? $objectPlugins->getOptionsArgv ('_username') : 'asnmtap';
my $_password  = $objectPlugins->getOptionsArgv ('_password') ? $objectPlugins->getOptionsArgv ('_password') : '<PASSWORD>';

my $debug      = $objectPlugins->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $returnCode = $ERRORS{OK};
my $alert      = 'OK';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# plugins: dynamically
my $pluginTitle              = 'Weblogic - ';
my $pluginHelpPluginFilename = 'Supervision File SNMP Monitoring Weblogic.pdf'; # default '<NIHIL>'

# plugins: statically
my $pluginTest               = 'check_SNMPTT_weblogic.pl';
my $pluginDatabaseArguments  = "--server=$_serverDB --port=$_port --database=snmptt --username=$_username --passwd=$_password";
my $pluginOndemand           = 1;
my $pluginProduction         = 1;
my $pluginPagedir            = '/index/';               # pagedirs: 'index' must exist
my $pluginResultsdir         = 'SNMPTT';                # resultsdir: 'SNMPTT' must exist

# plugins: template
my $pluginTemplate = "ondemand='$pluginOndemand', production='$pluginProduction', pagedir='$pluginPagedir', resultsdir='$pluginResultsdir', helpPluginFilename='$pluginHelpPluginFilename'";

# displayDaemons: dynamically
my $displayDaemon            = 'index';                 # displayDaemon: 'index' must exist

# displayGroups: dynamically
my $displayGroupID           = '63';                    # displayGroupID: '63' must exist, displayGroupName: '73 CITAP (SNMPTT)'

# collectorDaemons: dynamically
my %collectorDaemon;
$collectorDaemon{PROD}       = 'snmptt-01';             # collectorDaemon: 'snmptt-01' must exist
$collectorDaemon{ACC}        = 'snmptt-01-ACC';         # collectorDaemon: 'snmptt-01-ACC' must exist
$collectorDaemon{SIM}        = $collectorDaemon{PROD};
$collectorDaemon{TEST}       = 'snmptt-01-TST';         # collectorDaemon: 'snmptt-01-TST' must exist if used

# crontabs: statically
my $arguments                = '';
my $noOffline                = '';

# admin console: statically
my $adminConsoleHTTP         = 'http://';
my $adminConsoleDomainURL    = $domain;
my $adminConsoleApplication  = '/console/';
my $adminConsolePortOffset   = -100;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ( $dbhWEBLOGIC, $sthWEBLOGIC, $dbhASNMTAP, $sthASNMTAP, $prepareString, $actions );

$dbhWEBLOGIC = DBI->connect ("DBI:mysql:$database:$serverDB:$port", "$username", "$password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );
$dbhASNMTAP = DBI->connect ("DBI:mysql:$_database:$_serverDB:$_port", "$_username", "$_password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $_serverDB, "$DBI::err ($DBI::errstr)" );

if ( $dbhWEBLOGIC and $dbhASNMTAP ) {
  my %ENVIRONMENT = ('PROD'=>'Production', 'SIM'=>'Simulation', 'ACC'=>'Acceptation');

  my ($rv, $sqlSTRING, $adminName, $hosts, $agent_location, $community, $version, $environment, $activated, $status, $uKey, $holidayBundleID, $step, $minute, $hour, $dayOfTheMonth, $monthOfTheYear, $dayOfTheWeek, $adminConsoleCheck ) = (1);
  $sqlSTRING = 'SELECT ADMIN_NAME, HOSTS, AGENT_LOCATION, COMMUNITY, VERSION, ENV, ACTIVATED, STATUS, uKey, holidayBundleID, step, minute, hour, dayOfTheMonth, monthOfTheYear, dayOfTheWeek, adminConsoleCheck FROM `ADMIN_CONFIG`';

  $actions .= "WEBLOGIC: $sqlSTRING\n" if ( $debug );
  $sthWEBLOGIC = $dbhWEBLOGIC->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
  $sthWEBLOGIC->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
  $sthWEBLOGIC->bind_columns( \$adminName, \$hosts, \$agent_location, \$community, \$version, \$environment, \$activated, \$status, \$uKey, \$holidayBundleID, \$step, \$minute, \$hour, \$dayOfTheMonth, \$monthOfTheYear, \$dayOfTheWeek, \$adminConsoleCheck ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

  if ( $rv ) {
    while( $sthWEBLOGIC->fetch() ) {
      my $_Environment = substr($environment, 0, 1);
      $actions .= "\n+ $adminName, $hosts, $agent_location, $community, $version, $environment, $activated, $status, $uKey, $holidayBundleID\n" if ( $debug );

      # plugins
      my ($_uKey, $_title, $_environment, $_step, $_helpPluginFilename, $_holidayBundleID, $_activated);
      $sqlSTRING = "SELECT uKey, title, environment, step, helpPluginFilename, holidayBundleID, activated FROM `plugins` WHERE catalogID='$CATALOGID' and uKey='$uKey' order by uKey";
      $actions .= "  ASNMTAP: $sqlSTRING\n" if ( $debug );
      $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
      $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
      $sthASNMTAP->bind_columns( \$_uKey, \$_title, \$_environment, \$_step, \$_helpPluginFilename, \$_holidayBundleID, \$_activated ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

      if ( $rv ) {
        my $weblogicVersionTitle = ( $community =~ /^v10_/ ? ' - v10' : '' );
        my $weblogicConfig = "${agent_location}\@${hosts}" if ( $community =~ /^v10_/ );

        my ($adminHostPortState, undef) = split ( ',', $hosts, 2 );
        my ($adminHost, $adminPort, $state) = split ( ':', $adminHostPortState );
        my $adminConsole = $adminConsoleHTTP . $adminHost .'.'. $adminConsoleDomainURL .':'. ( $adminPort + $adminConsolePortOffset ) . $adminConsoleApplication if ( $adminConsoleCheck and $agent_location ne 'virtual' );

        if ( $sthASNMTAP->fetch() ) {
          my $sqlUPDATE = ( defined $update ) ? 1 : 0;
          $actions .= "  + $_uKey, $_title, $_environment, $_step, $_helpPluginFilename, $_holidayBundleID, $_activated\n" if ( $debug );

          if ( "$pluginTitle$adminName$weblogicVersionTitle" ne $_title ) {
            $sqlUPDATE++;
            $actions .= "  - title changed to '$pluginTitle$adminName$weblogicVersionTitle'\n" if ( $debug );
          }

          if ( $_Environment ne $_environment ) {
            $sqlUPDATE++;
            $actions .= "  - environment changed to '". $ENVIRONMENT{$environment} ."'\n" if ( $debug );
          }

          if ( $step != $_step ) {
            $sqlUPDATE++;
            $actions .= "  - step changed to '$step' \n" if ( $debug );
          }

          if ( $pluginHelpPluginFilename ne $_helpPluginFilename ) {
            $sqlUPDATE++;
            $actions .= "  - helpPluginFilename changed to '$pluginHelpPluginFilename'\n" if ( $debug );
          }

          if ( $holidayBundleID ne $_holidayBundleID ) {
            $sqlUPDATE++;
            $actions .= "  - holidayBundleID changed to '$holidayBundleID'\n" if ( $debug );
          }

          if ( $activated ne $_activated ) {
            $sqlUPDATE++;
            $actions .= "  - plugin ". ($activated ? '' : 'de') ."activated\n" if ( $debug );
          }

          if ( $sqlUPDATE ) {
            $sqlUPDATE = "UPDATE `plugins` SET title='$pluginTitle$adminName$weblogicVersionTitle', arguments=\"$pluginDatabaseArguments --uKey=$uKey --community=$community" . ( defined $hostname ? " --host=$adminHost" : '' ) . ( defined $weblogicConfig ? " --weblogicConfig='$weblogicConfig'" : '' ) . ( defined $adminConsole ? " --adminConsole=$adminConsole" : '' ) . "\", environment='$_Environment', test='$pluginTest', $pluginTemplate, holidayBundleID='$holidayBundleID', step='$step', activated='$activated' WHERE catalogID='$CATALOGID' and uKey='$uKey'";
            $actions .= "  ASNMTAP: $sqlUPDATE\n";
            unless ( $debug ) { $dbhASNMTAP->do( $sqlUPDATE ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlUPDATE") };
          }
        } else {
          $actions .= "  ASNMTAP: ukey '$uKey' doesn't exist\n";
          my $sqlINSERT = "INSERT INTO `plugins` SET catalogID='$CATALOGID', uKey='$uKey', title='$pluginTitle$adminName$weblogicVersionTitle', arguments=\"$pluginDatabaseArguments --uKey=$uKey --community=$community" . ( defined $hostname ? " --host=$adminHost" : '' ) . ( defined $weblogicConfig ? " --weblogicConfig='$weblogicConfig'" : '' ) . ( defined $adminConsole ? " --adminConsole=$adminConsole" : '' ) . "\", environment='$_Environment', test='$pluginTest', $pluginTemplate, holidayBundleID='$holidayBundleID', step='$step', activated='$activated'";
          $actions .= "  ASNMTAP: $sqlINSERT\n";
          unless ( $debug ) { $dbhASNMTAP->do( $sqlINSERT ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlINSERT") };
        }

        $sthASNMTAP->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
      }

      # views
      my ($_displayDaemon, $_displayGroupID);
      $sqlSTRING = "SELECT uKey, displayDaemon, displayGroupID, activated FROM `views` WHERE catalogID='$CATALOGID' and uKey='$uKey' order by uKey";
      $actions .= "  ASNMTAP: $sqlSTRING\n" if ( $debug );
      $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
      $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
      $sthASNMTAP->bind_columns( \$_uKey, \$_displayDaemon, \$_displayGroupID, \$_activated ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

      if ( $rv ) {
        if ( $sthASNMTAP->fetch() ) {
          my $sqlUPDATE = ( defined $update ) ? 1 : 0;
          $actions .= "  + $_uKey, $_displayDaemon, $_displayGroupID, $_activated\n" if ( $debug );

          if ( $displayDaemon ne $_displayDaemon ) {
            $sqlUPDATE++;
            $actions .= "  - displayDaemon changed to '$displayDaemon'\n" if ( $debug );
          }

          if ( $displayGroupID ne $_displayGroupID ) {
            $sqlUPDATE++;
            $actions .= "  - displayGroupID changed to '$displayGroupID'\n" if ( $debug );
          }

          if ( $activated ne $_activated ) {
            $sqlUPDATE++;
            $actions .= "  - view ". ($activated ? '' : 'de') ."activated\n" if ( $debug );
          }

          if ( $sqlUPDATE ) {
            $sqlUPDATE = "UPDATE `views` SET displayDaemon='$displayDaemon', displayGroupID='$displayGroupID', activated='$activated' WHERE catalogID='$CATALOGID' and uKey='$uKey' and displayDaemon='$displayDaemon'";
            $actions .= "  ASNMTAP: $sqlUPDATE\n";
            unless ( $debug ) { $dbhASNMTAP->do( $sqlUPDATE ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlUPDATE") };
          }
        } else {
          $actions .= "  ASNMTAP: ukey '$uKey' doesn't exist\n";
          my $sqlINSERT = "INSERT INTO `views` SET catalogID='$CATALOGID', uKey='$uKey', displayDaemon='$displayDaemon', displayGroupID='$displayGroupID', activated='$activated'";
          $actions .= "  ASNMTAP: $sqlINSERT\n";
          unless ( $debug ) { $dbhASNMTAP->do( $sqlINSERT ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlINSERT") };
        }

        $sthASNMTAP->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
      }

      # crontabs
      my ($_lineNumber, $_collectorDaemon, $_arguments, $_minute, $_hour, $_dayOfTheMonth, $_monthOfTheYear, $_dayOfTheWeek, $_noOffline);
      $sqlSTRING = "SELECT uKey, lineNumber, collectorDaemon, arguments, minute, hour, dayOfTheMonth, monthOfTheYear, dayOfTheWeek, noOffline, activated FROM `crontabs` WHERE catalogID='$CATALOGID' and uKey='$uKey' and lineNumber='00' order by uKey";
      $actions .= "  ASNMTAP: $sqlSTRING\n" if ( $debug );
      $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
      $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
      $sthASNMTAP->bind_columns( \$_uKey, \$_lineNumber, \$_collectorDaemon, \$_arguments, \$_minute, \$_hour, \$_dayOfTheMonth, \$_monthOfTheYear, \$_dayOfTheWeek, \$_noOffline, \$_activated ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

      if ( $rv ) {
        if ( $sthASNMTAP->fetch() ) {
          my $sqlUPDATE = ( defined $update ) ? 1 : 0;
          $actions .= "  + $_uKey, $_lineNumber, $_collectorDaemon, $_arguments, $_minute, $_hour, $_dayOfTheMonth, $_monthOfTheYear, $_dayOfTheWeek, $_noOffline, $_activated\n" if ( $debug );

          if ( $collectorDaemon{$environment} ne $_collectorDaemon ) {
            $sqlUPDATE++;
            $actions .= "  - collectorDaemon changed to '". $collectorDaemon{$environment} ."'\n" if ( $debug );
          }

          if ( $minute ne $_minute ) {
            $sqlUPDATE++;
            $actions .= "  - minute changed to '$minute'\n" if ( $debug );
          }

          if ( $hour ne $_hour ) {
            $sqlUPDATE++;
            $actions .= "  - hour changed to '$hour'\n" if ( $debug );
          }

          if ( $dayOfTheWeek ne $_dayOfTheWeek ) {
            $sqlUPDATE++;
            $actions .= "  - dayOfTheWeek changed to '$dayOfTheWeek'\n" if ( $debug );
          }

          if ( $activated ne $_activated ) {
            $sqlUPDATE++;
            $actions .= "  - crontab ". ($activated ? '' : 'de') ."activated\n" if ( $debug );
          }

          if ( $sqlUPDATE ) {
            $sqlUPDATE = "UPDATE `crontabs` SET collectorDaemon='". $collectorDaemon{$environment} ."', arguments='$arguments', minute='$minute', hour='$hour', dayOfTheMonth='$dayOfTheMonth', monthOfTheYear='$monthOfTheYear', dayOfTheWeek='$dayOfTheWeek', noOffline='$noOffline', activated='$activated' WHERE catalogID='$CATALOGID' and uKey='$uKey' and lineNumber='00'";
            $actions .= "  ASNMTAP: $sqlUPDATE\n";
            unless ( $debug ) { $dbhASNMTAP->do( $sqlUPDATE ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlUPDATE") };
          }
        } else {
          $actions .= "  ASNMTAP: ukey '$uKey' doesn't exist\n";
          my $sqlINSERT = "INSERT INTO `crontabs` SET catalogID='$CATALOGID', uKey='$uKey', lineNumber='00', collectorDaemon='". $collectorDaemon{$environment} ."', arguments='$arguments', minute='$minute', hour='$hour', dayOfTheMonth='$dayOfTheMonth', monthOfTheYear='$monthOfTheYear', dayOfTheWeek='$dayOfTheWeek', noOffline='$noOffline', activated='$activated'";
          $actions .= "  ASNMTAP: $sqlINSERT\n";
          unless ( $debug ) { $dbhASNMTAP->do( $sqlINSERT ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlINSERT") };
        }

        $sthASNMTAP->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
      }
    }

    $sthWEBLOGIC->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
  }
}

$dbhASNMTAP->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $_serverDB, "$DBI::err ($DBI::errstr)" ) if ( $dbhASNMTAP );
$dbhWEBLOGIC->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" ) if ( $dbhWEBLOGIC );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValues ( { stateValue => $returnCode, alert => $alert }, $TYPE{APPEND} );

if ( defined $actions ) {
  unless ( sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, 'ASNMTAP ~ Weblogic: '. $STATE{$returnCode} .', '. get_datetimeSignal(), $actions, $debug ) ) {
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
