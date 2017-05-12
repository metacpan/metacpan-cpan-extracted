#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, create_ASNMTAP_jUnit_configuration_for_jUnit.pl
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
  _programName        => 'create_ASNMTAP_jUnit_configuration_for_jUnit.pl',
  _programDescription => 'Create ASNMTAP jUnit configuration for jUnit',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[--force] [--update] [-s|--server=<hostname>] [--database=<database>] [--_server=<hostname>] [--_database=<database>] [--_port=<port>] [--_username=<username>] [--_password=<password>]',
  _programHelpPrefix  => "--force
--update
-s, --server=<hostname> (default: localhost)
--database=<database> (default: jUnitConfig)
--_server=<hostname> (default: localhost)
--_database=<database> (default: asnmtap)
--_port=<port>
--_username=<username>
--_password=<password>",
  _programGetOptions  => ['force', 'update', '_server:s', '_port:i', '_database:s', '_username|_loginname:s', '_password|_passwd:s', 'server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e:s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $force      = $objectPlugins->getOptionsArgv ('force')     ? $objectPlugins->getOptionsArgv ('force')     : undef;
my $update     = $objectPlugins->getOptionsArgv ('update')    ? $objectPlugins->getOptionsArgv ('update')    : undef;

my $serverDB   = $objectPlugins->getOptionsArgv ('server')    ? $objectPlugins->getOptionsArgv ('server')    : 'localhost';
my $port       = $objectPlugins->getOptionsArgv ('port')      ? $objectPlugins->getOptionsArgv ('port')      : 3306;
my $database   = $objectPlugins->getOptionsArgv ('database')  ? $objectPlugins->getOptionsArgv ('database')  : 'jUnitConfig';
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

# jUnitServer: statically
my ( %jUnitServer, %jUnitPort );
$jUnitServer{P}{8}           = 'modi';
$jUnitPort  {P}{8}           = '4444';

$jUnitServer{S}{8}           = $jUnitServer{P}{8};
$jUnitPort  {S}{8}           = $jUnitPort  {P}{8};

$jUnitServer{A}{8}           = 'magni';
$jUnitPort  {A}{8}           = '4443';

$jUnitServer{T}{8}           = $jUnitServer{A}{8};
$jUnitPort  {T}{8}           = $jUnitPort{A}{8};

$jUnitServer{P}{10}          = $jUnitServer{A}{8};
$jUnitPort  {P}{10}          = '10200';

$jUnitServer{S}{10}          = $jUnitServer{P}{10};
$jUnitPort  {S}{10}          = $jUnitPort{P}{10};

$jUnitServer{A}{10}          = $jUnitServer{P}{8};
$jUnitPort  {A}{10}          = '10100';

$jUnitServer{T}{10}          = $jUnitServer{A}{10};
$jUnitPort  {T}{10}          = $jUnitPort{A}{10};

# plugins: statically
my $pluginTest               = 'check_jUnit.pl';
my $pluginArgumentsOndemand  = '--svParam=ONDEMAND --interval=900';
my $pluginOndemand           = 1;
my $pluginProduction         = 0;
my $pluginPagedir            = '/jUnit/index/';           # pagedirs: 'jUnit' and 'index' must exist

# plugins: template
my $pluginTemplate = "test='$pluginTest', argumentsOndemand='$pluginArgumentsOndemand', ondemand='$pluginOndemand', pagedir='$pluginPagedir'";

# displayDaemons: dynamically
my @displayDaemon            = ( 'index', 'jUnit' );     # 'index' and 'jUnit' must be created

# collectorDaemons: dynamically
my %hour;
$hour{P}                     = '*';
$hour{S}                     = $hour{P};
$hour{A}                     = '8-16';
$hour{T}                     = $hour{A};

my %dayOfTheWeek;
$dayOfTheWeek{P}             = '*';
$dayOfTheWeek{S}             = $dayOfTheWeek{P};
$dayOfTheWeek{A}             = '1-5';
$dayOfTheWeek{T}             = $dayOfTheWeek{A};

# crontabs: statically
my $dayOfTheMonth            = '*';
my $monthOfTheYear           = '*';
my $noOffline                = '';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ( $dbhJUNIT, $sthJUNIT, $dbhASNMTAP, $sthASNMTAP, $prepareString, $actions );

$dbhJUNIT = DBI->connect ("DBI:mysql:$database:$serverDB:$port", "$username", "$password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );
$dbhASNMTAP = DBI->connect ("DBI:mysql:$_database:$_serverDB:$_port", "$_username", "$_password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $_serverDB, "$DBI::err ($DBI::errstr)" );

if ( $dbhJUNIT and $dbhASNMTAP ) {
  my $returnChar = ( $debug ) ? '' : "\n";

  my %ENVIRONMENT = ('P'=>'Production', 'S'=>'Simulation', 'A'=>'Acceptation', 'T'=>'Test');

  my ($errorCode, $rv, $sqlSTRING, $BASE_ID, $uKey, $TITLE, $APPNAME, $VERSION, $MAXTIME, $activated, $STATUS, $CLUSTERNAME, $ENV, $WEBLOGIC_VERSION, $TYPE_NAME, $displayGroupID, $groupTitlePos, $collectorDaemons, $minutes ) = (0, 1);

  # displayGroups: jUnit
  my ($_TYPE_NAME, $_CLUSTERNAME, $_displayGroupID, $_groupTitle, $_groupTitlePos, $_activated, %displayGroups, @groupTitles);

  $sqlSTRING = 'SELECT TYPE_NAME, displayGroupID, groupTitlePos FROM TYPE WHERE displayGroupID > 0 and groupTitlePos = 0 ORDER BY TYPE_NAME';
  $actions .= "\nJUNIT: displayGroups: $sqlSTRING\n" if ( $debug );
  $sthJUNIT = $dbhJUNIT->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
  $sthJUNIT->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
  $sthJUNIT->bind_columns( \$_TYPE_NAME, \$_displayGroupID, \$_groupTitlePos ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

  if ( $rv ) {
    while( $sthJUNIT->fetch() ) {
      $_groupTitle = "$_groupTitlePos $_TYPE_NAME (jUnit)";
      $displayGroups{$_groupTitle} = $_displayGroupID;
      $actions .= "- $_groupTitle, ". $displayGroups{$_groupTitle} ."\n" if ( $debug );
    }

    $sthJUNIT->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
  }

  $sqlSTRING = 'SELECT DISTINCT TYPE.TYPE_NAME, SERVER.CLUSTERNAME, TYPE.groupTitlePos FROM BASE_SERVICES, SERVER, TYPE WHERE BASE_SERVICES.SERV_ID = SERVER.SERV_ID AND BASE_SERVICES.TYPE_ID = TYPE.TYPE_ID AND TYPE.displayGroupID = 0 AND TYPE.groupTitlePos > 0 ORDER BY TYPE.TYPE_NAME, SERVER.CLUSTERNAME';
  $actions .= "\nJUNIT: displayGroups: $sqlSTRING\n" if ( $debug );
  $sthJUNIT = $dbhJUNIT->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
  $sthJUNIT->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
  $sthJUNIT->bind_columns( \$_TYPE_NAME, \$_CLUSTERNAME, \$_groupTitlePos ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

  if ( $rv ) {
    while( $sthJUNIT->fetch() ) {
      $_groupTitle = "$_groupTitlePos $_TYPE_NAME (jUnit) - $_CLUSTERNAME";
      push ( @groupTitles, $_groupTitle );
      $actions .= "- $_groupTitle\n" if ( $debug );
    }

    $sthJUNIT->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
  }

  # displayGroups: ASNMTAP
  foreach $_groupTitle ( @groupTitles ) {
    $sqlSTRING = "SELECT displayGroupID FROM `displayGroups` WHERE catalogID='$CATALOGID' and groupTitle='$_groupTitle'";
    $actions .= "\nASNMTAP: displayGroups: $sqlSTRING\n" if ( $debug );
    $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
    $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
    $sthASNMTAP->bind_columns( \$_displayGroupID ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

    if ( $rv ) {
      if ( $sthASNMTAP->fetch() ) {
        $displayGroups{$_groupTitle} = $_displayGroupID;
        $actions .= "+ $_groupTitle: ". $displayGroups{$_groupTitle} ." exists\n" if ( $debug );
      } else {
        $errorCode = 1;
        $actions .= "- $_groupTitle: $_displayGroupID doesn't exists\n";
        $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $actions }, $TYPE{APPEND} );

        unless ( sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, 'ASNMTAP ~ jUnit: UNKNOWN, '. get_datetimeSignal(), $actions, $debug ) ) {
          $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Problem sending email to the System Administrators" }, $TYPE{APPEND} );
        }
      }

      $sthASNMTAP->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
    }
  }

  $objectPlugins->exit (7) if ( $errorCode );

  # displayGroups: ALL
  if ( $debug ) {
    $actions .= "\ndisplayGroups: ALL\n";

    foreach $_groupTitle ( keys %displayGroups ) {
      $actions .= "= $_groupTitle: ". $displayGroups{$_groupTitle} ."\n";
    }
  }

  # crontabs: ALL
  my ($collectorDaemon, $_collectorDaemon, $_count, %collectorDaemonCount);
  $sqlSTRING = "SELECT collectorDaemon, count(collectorDaemon) FROM crontabs where catalogID='$CATALOGID' and uKey regexp '^JUNIT-' GROUP BY collectorDaemon";
  $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
  $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
  $sthASNMTAP->bind_columns( \$_collectorDaemon, \$_count ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

  if ( $rv ) {
    while( $sthASNMTAP->fetch() ) {
      $collectorDaemonCount {$_collectorDaemon} = ( defined $update ) ? 0 : $_count;
    }

    $sthJUNIT->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
  }

  if ( $debug ) {
    $actions .= "\ncrontabs: $sqlSTRING\ncrontabs: ALL\n";

    foreach $collectorDaemon ( keys %collectorDaemonCount ) {
      $actions .= "= $collectorDaemon: ". $collectorDaemonCount {$collectorDaemon} ."\n";
    }
  }

  # jUnit -> ASNMTAP
  $sqlSTRING = 'SELECT BASE_SERVICES.BASE_ID, BASE_SERVICES.UKEY, BASE_SERVICES.TITLE, BASE_SERVICES.APPNAME, BASE_SERVICES.VERSION, BASE_SERVICES.MAXTIME, BASE_SERVICES.ACTIVATED, BASE_SERVICES.STATUS, SERVER.CLUSTERNAME, SERVER.ENV, SERVER.WEBLOGIC_VERSION, TYPE.TYPE_NAME, TYPE.displayGroupID, TYPE.groupTitlePos, TYPE.collectorDaemons, TYPE.minutes FROM `BASE_SERVICES`, `SERVER`, `TYPE` WHERE BASE_SERVICES.SERV_ID = SERVER.SERV_ID AND BASE_SERVICES.TYPE_ID = TYPE.TYPE_ID ORDER BY UKEY, BASE_ID';
  $actions .= "\nJUNIT: $sqlSTRING\n" if ( $debug );

  $sthJUNIT = $dbhJUNIT->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
  $sthJUNIT->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
  $sthJUNIT->bind_columns( \$BASE_ID, \$uKey, \$TITLE, \$APPNAME, \$VERSION, \$MAXTIME, \$activated, \$STATUS, \$CLUSTERNAME, \$ENV, \$WEBLOGIC_VERSION, \$TYPE_NAME, \$displayGroupID, \$groupTitlePos, \$collectorDaemons, \$minutes ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

  if ( $rv ) {
    while( $sthJUNIT->fetch() ) {
      unless ( defined $uKey and $uKey ne '') {
        $actions .= "\n+ $BASE_ID, uKey not defined into 'jUnit' database\n";
        next;
      }

      my $environment = substr($ENV, 0, 1);

      my $arguments = '-K '. $uKey .' --jUnitServer='. $jUnitServer{$environment}{$WEBLOGIC_VERSION} .' --jUnitPort=' .$jUnitPort{$environment}{$WEBLOGIC_VERSION};
      $arguments .= ' --maxtime=' .$MAXTIME if ( defined $MAXTIME and $MAXTIME );

      my ($appname, undef) = ( defined $TITLE and $TITLE ) ? $TITLE : split (/\@/, ( ( $APPNAME =~ /^test/ ) ? substr($APPNAME, 4) : $APPNAME ), 2);
      my $version = (defined $VERSION and $VERSION ne '') ? ' v'. $VERSION : '';

      my $resultsdir = $appname;
      my $groupName  = ucfirst ( $appname );

      my $title = $TYPE_NAME .' '. $groupName . $version .' - '. $CLUSTERNAME;

      my $holidayBundleID = ( $environment eq 'P' ) ? '1' : '4';

      my $groupTitle = $groupTitlePos .' '. $TYPE_NAME .' (jUnit) - '. $CLUSTERNAME;
      $displayGroupID = $displayGroups {$groupTitle} if ( $displayGroupID == 0 and $groupTitlePos > 0 );

      (my @minutes, undef) = split ( /\|/, $minutes, 2 );
      my (undef, $step) = split ( /\//, $minutes[0] );

      $actions .= "\n+ $BASE_ID, $uKey, $APPNAME, $version, $activated, $STATUS, $CLUSTERNAME, $ENV, $WEBLOGIC_VERSION, $TYPE_NAME, $displayGroupID, $groupTitlePos, $groupTitle, $collectorDaemons, $minutes\n" if ( $debug );

      # plugins
      my ($_arguments, $_title, $_environment, $_holidayBundleID, $_resultsdir, $_activated);
      $sqlSTRING = "SELECT arguments, title, environment, holidayBundleID, resultsdir, activated FROM `plugins` WHERE catalogID='$CATALOGID' and uKey='$uKey'";
      $actions .= "  ASNMTAP: $sqlSTRING\n" if ( $debug );

      $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
      $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
      $sthASNMTAP->bind_columns( \$_arguments, \$_title, \$_environment, \$_holidayBundleID, \$_resultsdir, \$_activated ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

      if ( $rv ) {
      # APE: hack voor wanneer er meerdere lijnen zijn met dezelfde key, waarvan er sommige de status 'ASNMTAP' en andere 'EOL' hebben!
      # my $_Activated = ( $activated and $STATUS eq 'ASNMTAP' ) ? 1 : 0;
        my $_Activated = ( $activated ) ? 1 : 0;

        if ( $sthASNMTAP->fetch() ) {
          my $sqlUPDATE = ( defined $update ) ? 1 : 0;
          $actions .= "  + $uKey, $_arguments, $_title, $_environment, $_holidayBundleID, $_resultsdir, $_activated\n" if ( $debug );

          if ( $arguments ne $_arguments ) {
            $sqlUPDATE++;
            $actions .= "  - arguments changed from '$_arguments' to '$arguments'\n" if ( $debug );
          }

          if ( $title ne $_title ) {
            $sqlUPDATE++;
            $actions .= "  - title changed from '$_title' to '$title'\n" if ( $debug );
          }

          if ( $environment ne $_environment ) {
            $sqlUPDATE++;
            $actions .= "  - environment changed from '". $ENVIRONMENT{$_environment} ."' to '". $ENVIRONMENT{$environment} ."'\n" if ( $debug );
          }

          if ( $holidayBundleID ne $_holidayBundleID ) {
            if ( defined $force ) {
              $sqlUPDATE++;
              $actions .= "  - holidayBundleID changed from '$_holidayBundleID' to '$holidayBundleID'\n" if ( $debug );
            } else {
              $holidayBundleID = $_holidayBundleID;
            }
          }

          if ( $resultsdir ne $_resultsdir ) {
            if ( defined $force ) {
              $sqlUPDATE++;
              $actions .= "  - resultsdir changed from '$_resultsdir' to '$resultsdir'\n" if ( $debug );

              resultsdir ( $dbhASNMTAP, $sthASNMTAP, $resultsdir, $groupName, $rv, \$actions );
            } else {
              $resultsdir = $_resultsdir;
            }
          }

          if ( $_Activated ne $_activated ) {
            $sqlUPDATE++;
            $actions .= "  - plugin ". ($_Activated ? '' : 'de') ."activated\n" if ( $debug );
          }

          if ( $sqlUPDATE ) {
            $sqlUPDATE = "UPDATE `plugins` SET title='$title', arguments='$arguments', environment='$environment', resultsdir='$resultsdir', holidayBundleID='$holidayBundleID', activated='$_Activated', $pluginTemplate WHERE catalogID='$CATALOGID' and uKey='$uKey'";
            $actions .= "$returnChar  ASNMTAP: ukey '$uKey' exists\n  ASNMTAP: $sqlUPDATE\n";

            if ( defined $force ) {
              $actions .= "--force, is informational, doesn't UPDATE the database\n";
            } else {
              unless ( $debug ) { $dbhASNMTAP->do( $sqlUPDATE ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlUPDATE") };
            }
          } else {
            $actions .= "$returnChar  ASNMTAP: ukey '$uKey' exists and up-to-date\n";
          }
        } else {
          resultsdir ( $dbhASNMTAP, $sthASNMTAP, $resultsdir, $groupName, $rv, \$actions );

          my $sqlINSERT = "INSERT INTO `plugins` SET catalogID='$CATALOGID', uKey='$uKey', title='$title', arguments='$arguments', environment='$environment', resultsdir='$resultsdir', holidayBundleID='$holidayBundleID', step='$step', activated='$_Activated', production='$pluginProduction', $pluginTemplate";
          $actions .= "$returnChar  ASNMTAP: ukey '$uKey' doesn't exist\n  ASNMTAP: $sqlINSERT\n";
          unless ( $debug ) { $dbhASNMTAP->do( $sqlINSERT ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlINSERT") };
        }

        $sthASNMTAP->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
      }

      # views
      foreach my $displayDaemon ( @displayDaemon ) {
        $sqlSTRING = "SELECT displayGroupID FROM `views` WHERE catalogID='$CATALOGID' and uKey='$uKey' and displayDaemon='$displayDaemon'";
        $actions .= "  views: $sqlSTRING\n" if ( $debug );
        $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
        $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
        $sthASNMTAP->bind_columns( \$_displayGroupID ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

        if ( $rv ) {
          if ( $sthASNMTAP->fetch() ) {
            $actions .= "  + views: $uKey, $displayDaemon, $_displayGroupID\n" if ( $debug );

            if ( $displayGroupID ne $_displayGroupID ) {
              $actions .= "  + views: displayGroupID changed from '$_displayGroupID' to '$displayGroupID'\n" if ( $debug );

              my $sqlUPDATE = "UPDATE `views` SET displayDaemon='$displayDaemon', displayGroupID='$displayGroupID', activated='$activated' WHERE catalogID='$CATALOGID' and uKey='$uKey' and displayDaemon='$displayDaemon'";
     
              $actions .= "  + views: uKey='$uKey' and displayDaemon='$displayDaemon' exist\n  + views: $sqlUPDATE\n";

              if ( defined $force ) {
                $actions .= "    --force, is informational, doesn't UPDATE the database\n";
              } else {
                unless ( $debug ) { $dbhASNMTAP->do( $sqlUPDATE ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlUPDATE") };
              }
            } else {
              $actions .= "  = views: uKey='$uKey' and displayDaemon='$displayDaemon' exist and up-to-date\n";
            }
          } else {
            my $sqlINSERT = "INSERT INTO `views` SET catalogID='$CATALOGID', uKey='$uKey', displayDaemon='$displayDaemon', displayGroupID='$displayGroupID', activated=1";
            $actions .= "  - views: uKey='$uKey' and displayDaemon='$displayDaemon' doesn't exist\n  - views: $sqlINSERT\n";
            unless ( $debug ) { $dbhASNMTAP->do( $sqlINSERT ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlINSERT") };
          }

          $sthASNMTAP->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
        }
      }

      # crontabs
      my ($collectorDaemon, $_collectorDaemon, $_minute, $selectedElement);
      $sqlSTRING = "SELECT collectorDaemon, minute FROM `crontabs` WHERE catalogID='$CATALOGID' and uKey='$uKey' and lineNumber='00'";
      $actions .= "  crontabs: $sqlSTRING\n" if ( $debug );
      $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
      $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
      $sthASNMTAP->bind_columns( \$_collectorDaemon, \$_minute ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

      (my @collectorDaemon) = split ( /\|/, $collectorDaemons );

      if ( $environment eq 'A' ) {
        for ( my $element = 0; $element <= $#collectorDaemon; $element++ ) { $collectorDaemon[$element] .= '-ACC' };
      }

      push (@collectorDaemon, 'End-Of-Life');

      if ( $debug ) {
        foreach ( @collectorDaemon) { $actions .= "  * crontabs: $_\n"; };
      }

      if ( $#collectorDaemon < 2 ) {
        $selectedElement = 0;
        $collectorDaemon = $collectorDaemon[0];
      } else {
        my ($previousCount, $previousElement, $currentCount, $currentElement) = ( 0 );

        for ( my $element = 0; $element < $#collectorDaemon; $element++ ) { 
          $currentCount    = $collectorDaemonCount { $collectorDaemon[$element] };
          $currentElement  = $element;

          $selectedElement = ( $previousCount < $currentCount ) ? $previousElement : $currentElement if ( defined $previousCount );

          $previousCount   = $currentCount;
          $previousElement = $currentElement;
        }

        $collectorDaemon = $collectorDaemon[$selectedElement];
      }

      if ( $rv ) {
        if ( $sthASNMTAP->fetch() ) {
          my $sqlUPDATE = 0;
          $actions .= "  + crontabs: $uKey, $_collectorDaemon\n" if ( $debug );

          if ( defined $update ) {
            $sqlUPDATE++ if ( $_collectorDaemon ne 'End-Of-Life' and $collectorDaemon ne $_collectorDaemon );
          } else {
            $sqlUPDATE++;

            foreach (@collectorDaemon) {
              if ( $_ eq $_collectorDaemon ) {
                $collectorDaemon = $_;
                $sqlUPDATE = 0;
                last;
              }
            }
          }

          if ( $sqlUPDATE ) {
            $actions .= "  - crontabs: collectorDaemon changed from '$_collectorDaemon' to '$collectorDaemon'\n" if ( $debug );

            (undef, my $Step) = split (/\//, $_minute, 2);
            (my $Minute, undef) = split (/\//, $minutes[$selectedElement], 2);
            my $sqlUPDATE = "UPDATE `crontabs` SET collectorDaemon='$collectorDaemon', minute='$Minute/$Step' WHERE catalogID='$CATALOGID' and uKey='$uKey' and lineNumber='00'";

            $actions .= "  + crontabs: ukey '$uKey', lineNumber='00' exist\n  + crontabs: $sqlUPDATE\n";

            $collectorDaemonCount {$collectorDaemon}++ if ( defined $update );

            if ( defined $force ) {
              $actions .= "    --force, is informational, doesn't UPDATE the database\n";
            } else {
              unless ( $debug ) { $dbhASNMTAP->do( $sqlUPDATE ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlUPDATE") };
            }
          } else {
            $actions .= "  = crontabs: ukey '$uKey', lineNumber='00' exist and up-to-date\n";
          }
        } else {
          my $sqlINSERT = "INSERT INTO `crontabs` SET catalogID='$CATALOGID', uKey='$uKey', lineNumber='00', collectorDaemon='$collectorDaemon', arguments='--svParam=ASNMTAP -i ". ($step * 90) ."', minute='". $minutes[$selectedElement] ."', hour='". $hour{$environment} ."', dayOfTheMonth='$dayOfTheMonth', monthOfTheYear='$monthOfTheYear', dayOfTheWeek='". $dayOfTheWeek{$environment} ."', noOffline='$noOffline', activated=1";

          $actions .= "  - crontabs: ukey '$uKey', lineNumber='00' doesn't exist\n  - crontabs: $sqlINSERT\n";
          unless ( $debug ) { $dbhASNMTAP->do( $sqlINSERT ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlINSERT") };
          $collectorDaemonCount {$collectorDaemon}++;
        }

        $sthASNMTAP->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
      }
    }

    $sthJUNIT->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $sqlSTRING );
  }
}

$dbhASNMTAP->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $_serverDB, "$DBI::err ($DBI::errstr)" ) if ( $dbhASNMTAP );
$dbhJUNIT->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" ) if ( $dbhJUNIT );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValues ( { stateValue => $returnCode, alert => $alert }, $TYPE{APPEND} );

if ( defined $actions ) {
  unless ( sending_mail ( $SERVERLISTSMTP, $SENDEMAILTO, $SENDMAILFROM, 'ASNMTAP ~ jUnit: OK, '. get_datetimeSignal(), $actions, $debug ) ) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Problem sending email to the System Administrators" }, $TYPE{APPEND} );
  }
}

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub resultsdir {
  my ($dbhASNMTAP, $sthASNMTAP, $resultsdir, $groupName, $rv, $actions) = @_;

  my $sqlSTRING = "SELECT resultsdir FROM `resultsdir` WHERE catalogID='$CATALOGID' and resultsdir='$resultsdir'";
  $$actions .= "    - $sqlSTRING\n" if ( $debug );

  $sthASNMTAP = $dbhASNMTAP->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
  $sthASNMTAP->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
  $sthASNMTAP->bind_columns( \$resultsdir ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

  if ( $rv ) {
    unless ( $sthASNMTAP->fetch() ) {
      my $sqlINSERT = "INSERT INTO `resultsdir` SET catalogID='$CATALOGID', resultsdir='$resultsdir', groupName='$groupName', activated='1'";
      $$actions .= "    - resultsdir '$resultsdir' doesn't exist\n    - $sqlINSERT\n";
      unless ( $debug ) { $dbhASNMTAP->do( $sqlINSERT ) or $rv = _ErrorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlINSERT") };
    } elsif ( $debug ) {
      $$actions .= "    - resultsdir '$resultsdir' exists and up-to-date\n";
    }
  }

  return $rv;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _ErrorTrapDBI {
  my ($asnmtapInherited, $error_message) = @_;

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $error_message, error => "$DBI::err ($DBI::errstr)" }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
