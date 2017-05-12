#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_SNMPTT_weblogic.pl
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
  _programName        => 'check_SNMPTT_weblogic.pl',
  _programDescription => 'Check SNMP Trap Translator Database for Weblogic SNMP traps',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[--weblogicConfig=<weblogicConfig>] [--adminConsole=<adminConsole>] [--uKey|-K=<uKey>] [-s|--server=<hostname>] [--database=<database>]',
  _programHelpPrefix  => '--weblogicConfig=<weblogicConfig>
--adminConsole=<adminConsole>
-K, --uKey=<uKey>
-s, --server=<hostname> (default: localhost)',
  _programGetOptions  => ['weblogicConfig:s', 'adminConsole:s', 'uKey|K:s', 'community|C=s', 'host|H:s', 'server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e=s', 'proxy:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $weblogicConfig = $objectPlugins->getOptionsArgv ('weblogicConfig');
my $adminConsole   = $objectPlugins->getOptionsArgv ('adminConsole');
my $uKey           = $objectPlugins->getOptionsArgv ('uKey');

my $community      = $objectPlugins->getOptionsArgv ('community');
my $hostname       = $objectPlugins->getOptionsArgv ('host');
my $category       = 'ASNMTAP';

my $environment    = $objectPlugins->getOptionsArgv ('environment');

my $debug          = $objectPlugins->getOptionsValue ('debug');
my $onDemand       = $objectPlugins->getOptionsValue ('onDemand');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $serverHost   = $objectPlugins->getOptionsArgv ('server')   ? $objectPlugins->getOptionsArgv ('server')   : 'localhost';
my $serverPort   = $objectPlugins->getOptionsArgv ('port')     ? $objectPlugins->getOptionsArgv ('port')     : 3306;
my $serverUser   = $objectPlugins->getOptionsArgv ('username') ? $objectPlugins->getOptionsArgv ('username') : 'asnmtap';
my $serverPass   = $objectPlugins->getOptionsArgv ('password') ? $objectPlugins->getOptionsArgv ('password') : '<PASSWORD>';
my $serverDb     = $objectPlugins->getOptionsArgv ('database') ? $objectPlugins->getOptionsArgv ('database') : 'snmptt';

my $serverTact   = 'snmptt';
my $serverTarc   = 'snmptt_archive';
my $outOffDate   = 1800;                                        # seconds

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $environmentText = $objectPlugins->getOptionsValue ('environment');

my ($prefix, $suffix) = split ( /(snmp|v10)_/, $community );
my $domainname = ( defined $suffix ) ? $suffix : $prefix;
my $versionWeblogic = ( $prefix eq 'v10_' ? '>= v10.x' : '< v10.x');
my ($agentLocation, $hosts) = split ( /\@/, $weblogicConfig ) if ( defined $weblogicConfig );

if ( defined $uKey ) {
  my $message = $objectPlugins->pluginValue ('message') .' for uKey '. $uKey;
  $objectPlugins->pluginValue ( message => $message );
}

my $tMessage  = 'SNMP Trap Translator Database';

my $tHostname = ( defined $hostname ? "and hostname='$hostname'" : '' );
$hostname = 'undef' unless ( defined $hostname ) ;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $debugfileMessage = "\n<HTML><HEAD><TITLE>$tMessage \@ $APPLICATION</TITLE><style type=\"text/css\">\n.statusOdd { font-family: arial,serif; font-size: 10pt; background-color: #DBDBDB; }\n.statusEven { font-family: arial,serif; font-size: 10pt; background-color: #C4C2C2; }\ntd.statusOK { font-family: arial,serif; font-size: 10pt; background-color: #33FF00; }\ntd.statusWARNING { font-family: arial,serif; font-size: 10pt; background-color: #FFFF00; }\ntd.statusCRITICAL { font-family: arial,serif; font-size: 10pt; background-color: #F83838; }\ntd.statusUNKNOWN { font-family: arial,serif; font-size: 10pt; background-color: #FFFFFF; }\n</style>\n</HEAD><BODY><HR><H1 style=\"margin: 0px 0px 5px; font: 125% verdana,arial,helvetica\">$tMessage \@ $APPLICATION</H1><HR>\n<TABLE><TR style=\"font: normal 100% verdana,arial,helvetica\">\n<TD>Weblogic Version:</TD><TD><B>$versionWeblogic</B></TD><TD>,&nbsp;&nbsp;Environment:</TD><TD><B>$environmentText</B></TD>";

if ( defined $agentLocation and defined $hosts ) {
  $debugfileMessage .= "<TD>,&nbsp;&nbsp;Agent Location:</TD><TD><B>$agentLocation</B></TD><TD>,&nbsp;&nbsp;Hosts:</TD><TD><B>$hosts</B></TD>";
}

$debugfileMessage .= "</TR></TABLE><BR>";

if ( defined $adminConsole ) {
  my (undef, undef, $tAdminConsole, undef) = split ( /\//, $adminConsole, 4 );

  use ASNMTAP::Asnmtap::Plugins::WebTransact;

  my @URLS = ();
  my $objectWebTransact = ASNMTAP::Asnmtap::Plugins::WebTransact->new ( \$objectPlugins, \@URLS );

  @URLS = (
    { Method => 'GET',  Url => $adminConsole, Qs_var => [], Qs_fixed => [], Exp => ["WebLogic Server Administration Console", "(?:Sign in to work with the WebLogic Server|Log in to work with the WebLogic Server domain)"], Exp_Fault => ">>>NIHIL<<<", Msg => "Admin Console: $adminConsole", Msg_Fault => "Admin Console: $adminConsole", Perfdata_Label => "Admin Console: $tAdminConsole" },
  );

  my $returnCode = $objectWebTransact->check ( { } );
  $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR><TD>\n<H2 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">Admin Console: $adminConsole</H2></TD></TR></TABLE>";
  $debugfileMessage .= "<TABLE WIDTH=\"100%\" BORDER=\"1\"><TR style=\"font: normal verdana,arial,helvetica;\"><TD ALIGN=\"CENTER\" CLASS=\"status". $STATE{$returnCode}. "\"><B>". $STATE{$returnCode}. "</B></TD></TR></TABLE><BR>";
  $objectPlugins->appendPerformanceData ( "'Admin Console: Status'=$returnCode;1;2;0;2" );
  undef $objectWebTransact;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($dbh, $sth, $sthDO, $rv, $query);
$rv = 1;

$dbh = DBI->connect ( "dbi:mysql:$serverDb:$serverHost:$serverPort", "$serverUser", "$serverPass" ) or $rv = errorTrapDBI ( \$objectPlugins,  'Sorry, cannot connect to the database' );

if ( $dbh and $rv ) {
  my ($id, $eventname, $eventid, $trapoid, $enterprise, $agentip, $severity, $uptime, $traptime, $formatline, $system_running_SNMPTT, $trapread);

  # check the depending problems from the 'SNMP Trap Translator'
  my $currentTimeslot = timelocal ( 0, (localtime)[1,2,3,4,5] );
  my $tEpochtime = $currentTimeslot;
  my $tSeverity  = $ERRORS{OK};

  $query = "SELECT SQL_NO_CACHE id, eventname, eventid, trapoid, enterprise, agentip, severity, uptime, traptime, formatline, system_running_SNMPTT, trapread FROM `$serverTact` WHERE community='$community' $tHostname and category='$category' order by id desc";
  $sth = $dbh->prepare($query) or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot dbh->prepare: '. $query ) if ( $rv );
  $rv  = $sth->execute() or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot sth->execute: '. $query ) if ( $rv );
  $sth->bind_columns( \$id, \$eventname, \$eventid, \$trapoid, \$enterprise, \$agentip, \$severity, \$uptime, \$traptime, \$formatline, \$system_running_SNMPTT, \$trapread ) or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot sth->bind_columns: '. $query ) if ( $rv );

  if ( $rv ) {
    my (%tableVirtualServers, %tableVirtualServersDetail, %tableVirtualServersUniqueProblemSeverity);
    $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR><TD>\n<H2 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">Domain: $domainname, BOLD: are the new traps</H2></TD></TR></TABLE>";

    if ( $sth->rows() ) {
      my ( $uniqueProblem, $codeBefore, $codeAfter );

      while( $sth->fetch() ) {
        my ($_eventname, $detailLine, $uniqueTrap, $trapServerName, $trapMonitorType, $trapMBeanName, $trapMBeanType, $trapAttributeName, $trapMachineName, $trapLogThreadId, $trapLogTransactionId, $trapLogUserId, $trapLogSubsystem, $trapLogMsgId, $trapLogSeverity, $trapLogMessage) = ($eventname, $formatline, '(NULL)', $tEpochtime);

        for ( $eventname ) {
          /^wlsLogNotification$/ && do {     # Server Log Notification: $2, $3, $4, $5, $6, $7, $8, $9, $10
            my (undef, $variables, ) = split ( /: /, $formatline, 2 );
            ($trapServerName, $trapMachineName, $trapLogThreadId, $trapLogTransactionId, $trapLogUserId, $trapLogSubsystem, $trapLogMsgId, $trapLogSeverity, $trapLogMessage) = split ( /, /, $variables, 9 );

            if ( $trapLogMessage =~ /Exception: Too many open files/ ) {
              $_eventname = 'wlsLogNotification: Too many open files';
            } elsif ( ( $trapLogSeverity eq 'Error' and $trapLogMessage =~ /which is more than the configured time \(StuckThreadMaxTime\) of/ ) 
			  or ( $trapLogSeverity eq 'Info'  and $trapLogMessage =~ /^ExecuteThread: \\*'\d+\\*' for queue: \\*'[\w.]+\\*' has become \\*\"unstuck\\*\".$/ ) ) {
              $_eventname = 'wlsLogNotification: StuckThreadMaxTime';
              ( $uniqueTrap ) = ( $trapLogMessage =~ /^(ExecuteThread: \\'\d+\\' for queue: \\'[\w.]+\\') has / );
              print "\n\n$trapLogSeverity\n$trapLogMessage\n\n" if ( $debug > 2);
            }

		    last; };
          /^wlsServerStart$/ && do {         # This trap is generated when the server $2 was started on $1
            $_eventname = 'wlsServerShutDown or wlsServerStart';
            ( $trapServerName ) = ( $formatline =~ /^This trap is generated when the server (\w+) was started on / );
            $uniqueTrap = 'wlsServerStart';
		    last; };
          /^wlsServerShutDown$/ && do {      # This trap is generated when the server $2 has been shut down $1
            $_eventname = 'wlsServerShutDown or wlsServerStart';
            ( $trapServerName ) = ( $formatline =~ /^This trap is generated when the server (\w+) has been shut down / );
            $uniqueTrap = 'wlsServerStart';
		    last; };
          /^wlsMonitorNotification$/ && do { # JMX Monitor Notification: $2, $3, $6, $7, $8
            my (undef, $variables, ) = split ( /: /, $formatline, 2 );
            ($trapServerName, $trapMonitorType, $trapMBeanName, $trapMBeanType, $trapAttributeName) = split ( /, /, $variables, 5 );

            if ( $trapMonitorType =~ /^(jmx.monitor)\.(\w+)\.(\w+)$/ ) {
              $uniqueTrap = "$trapMBeanName|$trapAttributeName|$trapMBeanType|$1.$2";
              $detailLine = "$trapMBeanName, $trapAttributeName, $trapMBeanType, $1.$2.$3";
            }

		    last; };
          /^wlsAttributeChange$/ && do {     # Observed Attribute Change: $2, $3, $4, $5, $6, $7, $8, $9
            $uniqueTrap = 'wlsAttributeChange';
            # TODO ...
		    last; };
        }

        $uniqueProblem = "$trapServerName|$_eventname|$uniqueTrap";
        $tableVirtualServersUniqueProblemSeverity { $uniqueProblem } = $severity unless ( defined $tableVirtualServersUniqueProblemSeverity { $uniqueProblem } );

        if ( $debug ) {
          if ( $debug >= 2 ) {
            print "\nid           : $id\neventname    : $eventname\neventid      : $eventid\ntrapoid      : $trapoid\nenterprise   : $enterprise\ncommunity    : $community\nhostname     : $hostname\nagentip      : $agentip\ncategory     : $category\nseverity     : $severity (". $tableVirtualServersUniqueProblemSeverity { $uniqueProblem } .")\nuptime       : $uptime\ntraptime     : $traptime\nformatline   : $formatline\nsystem SNMPTT: $system_running_SNMPTT\ntrapread     : $trapread\n";
          } else {
            print "\n$id, $eventname, $eventid, $trapoid, $enterprise, $community, $hostname, $agentip, $category, $severity (". $tableVirtualServersUniqueProblemSeverity { $uniqueProblem } ."), $uptime, $traptime, $formatline, $system_running_SNMPTT, $trapread\n";
          }
        }

        if ( $severity ne 'OK' ) {
          if ( defined $tableVirtualServers { $trapServerName } ) {
            $tableVirtualServers { $trapServerName }++;
          } else {
            $tableVirtualServers { $trapServerName } = 1;
          }
        }

		# update records from to SNMPTT where trapread = 0
        unless ( $trapread == 2 ) {
          unless ( $onDemand ) {
            my $sqlUPDATE = "UPDATE `$serverTact` SET uniqueProblem='$uniqueProblem' WHERE id='$id'";
            print "             = $sqlUPDATE\n" if ( $debug );
            $dbh->do ($sqlUPDATE) or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot dbh->do: '. $sqlUPDATE );

            if ( $rv ) {
              my $sqlSTRING = "SELECT count(*) FROM `$serverTarc` WHERE id='$id'";
              print "             ? $sqlSTRING\n" if ( $debug );
              $sthDO = $dbh->prepare( $sqlSTRING ) or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot dbh->prepare: '. $sqlSTRING );
              $sthDO->execute() or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot dbh->execute: '. $sqlSTRING ) if $rv;

              if ( $rv ) {
                my $updateRecord = $sthDO->fetchrow_array();
                $sthDO->finish() or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot dbh->finish: '. $sqlSTRING );

                unless ( $updateRecord ) {
                  my $sqlINSERT = "INSERT INTO `$serverTarc` SELECT * FROM `$serverTact` WHERE id='$id'";
                  print "             + $sqlINSERT\n" if ( $debug );
                  $dbh->do ( $sqlINSERT ) or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot dbh->do: '. $sqlINSERT );
                }

                if ( $rv ) {
                  my $sqlUPDATE = "UPDATE `$serverTact` SET trapread='2' WHERE id='$id'";
                  print "             = $sqlUPDATE\n" if ( $debug );
                  $dbh->do ($sqlUPDATE) or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot dbh->do: '. $sqlUPDATE );
                }
              }
            }
          }

          $codeBefore = '<b>'; $codeAfter = '</b>';
        } else {
          $codeBefore = $codeAfter = '';
        }

        $tableVirtualServersDetail{$trapServerName}{$_eventname}{$uniqueTrap}{$id} = "<TD>$codeBefore$detailLine$codeAfter</TD><TD WIDTH=\"180\">$codeBefore$traptime$codeAfter</TD><TD WIDTH=\"80\" ALIGN=\"CENTER\" CLASS=\"status$severity\">$codeBefore$severity$codeAfter</TD>\n";
      }
    }

    # delete records regarding the solved problems
    my $backgroundColor = '#eeeee0';

    if ( $debug >= 2 ) {
      $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR><TD>\n<H3 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">List regarding the records to delete for the solved problems</H3></TD></TR></TABLE>\n";
      $debugfileMessage .= "<TABLE WIDTH=\"100%\" cellspacing=\"1\" cellpadding=\"1\"><TR style=\"font: normal bold 68% verdana,arial,helvetica; text-align:left; background:#a6a6a6;\"><TH>Unique Trap Key</TH><TH WIDTH=\"80\" ALIGN=\"CENTER\">Severity</TH></TR></TABLE>\n";
    }

    foreach my $uniqueProblem (sort keys %tableVirtualServersUniqueProblemSeverity) {
      $backgroundColor = ($backgroundColor eq '#eeeee0') ? '#e1e1ef' : '#eeeee0';
      my $severity = $tableVirtualServersUniqueProblemSeverity{$uniqueProblem};

      if ( $debug >= 2 ) {
        print "\n             + $uniqueProblem => $severity\n";
        $debugfileMessage .= "<TABLE WIDTH=\"100%\" cellspacing=\"1\" cellpadding=\"1\"><TR style=\"font: normal 68% verdana,arial,helvetica; background:$backgroundColor;\"><TD>$uniqueProblem</TD><TD WIDTH=\"80\" ALIGN=\"CENTER\" CLASS=\"status$severity\">$severity</TD></TR></TABLE>"; 
      }

      if ( $ERRORS{$severity} == 0 ) {
        if ( ! $onDemand ) {
          my ( $trapServerName, $eventname, $uniqueTrap, $sqlDELETE ) = split ( /\|/, $uniqueProblem, 3 );

          if ( $uniqueTrap eq 'wlsServerStart' ) {
            $sqlDELETE = "DELETE FROM `$serverTact` WHERE uniqueProblem regexp '^$trapServerName\\\\|' and trapread='2'";
          } else {
            $sqlDELETE = "DELETE FROM `$serverTact` WHERE uniqueProblem='$uniqueProblem' and trapread='2'";
          }

          if ( $debug >= 2 ) {
            print "             - $sqlDELETE\n";
            $debugfileMessage .= "<TABLE WIDTH=\"100%\" cellspacing=\"1\" cellpadding=\"1\"><TR style=\"font: normal 68% verdana,arial,helvetica; background:$backgroundColor;\"><TD colspan=\"2\">$sqlDELETE</TD></TR></TABLE>"; 
          } else {
            $dbh->do( $sqlDELETE ) or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot dbh->do: '. $sqlDELETE );
          }
        }
      } else {
        $tSeverity  = ( $tSeverity > $ERRORS{$severity} ) ? $tSeverity : $ERRORS{$severity};
      }
    }

    $debugfileMessage .= "<BR>" if ( $debug >= 2 );

    # print Domain Status
    $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR style=\"font: normal verdana,arial,helvetica;\"><TD ALIGN=\"CENTER\" CLASS=\"status". $STATE{$tSeverity}. "\"><B>". $STATE{$tSeverity}. "</B></TD></TR></TABLE><BR>";

    # print table Virtual Servers Summary
    $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR><TD>\n<H3 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">Virtual Servers Summary</H3></TD></TR></TABLE>";
    my $prev_trapServerName;
    my $_severity = $ERRORS{OK};

    foreach my $_trapServerName (sort keys %tableVirtualServersDetail) {
      if ( defined $prev_trapServerName and $prev_trapServerName ne $_trapServerName ) {
        $debugfileMessage .= "<TABLE WIDTH=\"100%\" cellspacing=\"1\" cellpadding=\"1\"><TR style=\"font: normal 68% verdana,arial,helvetica; background:#c9c9c9;\"><TH>&nbsp;</TH><TD WIDTH=\"80\" ALIGN=\"CENTER\" CLASS=\"status". $STATE{$_severity}. "\">". $STATE{$_severity}. "</TD></TR></TABLE><P style=\"font: normal 10% verdana,arial,helvetica;\">&nbsp;</P>";
        $_severity = $ERRORS{OK};
      }

      $prev_trapServerName = $_trapServerName;

      $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR style=\"font: normal bold 79% verdana,arial,helvetica; text-align:left; background:#a6caf0;\"><TH>Virtual Server: $_trapServerName</TH></TR></TABLE>\n";
      my $eventname = $tableVirtualServersDetail{$_trapServerName};

      foreach my $_eventname (sort { $b cmp $a } keys %$eventname) {
         $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR style=\"font: normal bold 68% verdana,arial,helvetica; text-align:left; background:#a6a6a6;\"><TH>Eventname: $_eventname</TH><TH WIDTH=\"180\">Traptime</TH><TH WIDTH=\"80\" ALIGN=\"CENTER\">Severity</TH></TR>\n";
         my $uniqueTrap = $eventname->{$_eventname};
         my $backgroundColor = '#eeeee0';

         foreach my $_uniqueTrap (sort { $b cmp $a } keys %$uniqueTrap) {
           my $detail = $uniqueTrap->{$_uniqueTrap};
           $backgroundColor = ($backgroundColor eq '#eeeee0') ? '#e1e1ef' : '#eeeee0';

           foreach my $line (sort { $b cmp $a } keys %$detail) {
             my $uniqueProblem = "$_trapServerName|$_eventname|$_uniqueTrap";
             my $severity = $tableVirtualServersUniqueProblemSeverity { $uniqueProblem };
             $_severity = ( $_severity > $ERRORS{$severity} ) ? $_severity : $ERRORS{$severity};
             $debugfileMessage .= "<TR style=\"font: normal 68% verdana,arial,helvetica; background:$backgroundColor;\">". $detail->{$line} ."</TR>" if ( $severity ne 'OK' or $debug >= 2 );
             $debugfileMessage .= "<TR style=\"font: normal 68% verdana,arial,helvetica; background:$backgroundColor;\"><TD colspan=\"2\">$uniqueProblem</TD><TD WIDTH=\"80\" ALIGN=\"CENTER\" CLASS=\"status$severity\">$severity</TD></TR>" if ( $debug >= 2 );
             last;
           }
         }

        $debugfileMessage .= "</TABLE>\n";
      }
    }

    $debugfileMessage .= "<TABLE WIDTH=\"100%\" cellspacing=\"1\" cellpadding=\"1\"><TR style=\"font: normal 68% verdana,arial,helvetica; background:#c9c9c9;\"><TH>&nbsp;</TH><TD WIDTH=\"80\" ALIGN=\"CENTER\" CLASS=\"status". $STATE{$_severity}. "\">". $STATE{$_severity}. "</TD></TR></TABLE>" if ( defined $prev_trapServerName );
    $debugfileMessage .= "<BR><HR><BR>";

    # print table Virtual Servers Detail
    $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR><TD>\n<H3 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">Virtual Servers Detail</H3></TD></TR></TABLE>";

    foreach my $trapServerName (sort keys %tableVirtualServersDetail) {
      $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR style=\"font: normal bold 79% verdana,arial,helvetica; text-align:left; background:#a6caf0;\"><TH>Virtual Server: $trapServerName</TH></TR></TABLE>\n";
      my $eventname = $tableVirtualServersDetail{$trapServerName};

      foreach my $key (sort { $b cmp $a } keys %$eventname) {
        $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR style=\"font: normal bold 68% verdana,arial,helvetica; text-align:left; background:#a6a6a6;\"><TH>Eventname: $key</TH><TH WIDTH=\"180\">Traptime</TH><TH WIDTH=\"80\" ALIGN=\"CENTER\">Severity</TH></TR>\n";
        my $uniqueTrap = $eventname->{$key};
        my $backgroundColor = '#eeeee0';

        foreach my $key (sort { $b cmp $a } keys %$uniqueTrap) {
          my $detail = $uniqueTrap->{$key};
          $backgroundColor = ($backgroundColor eq '#eeeee0') ? '#e1e1ef' : '#eeeee0';

          foreach my $key (sort { $b cmp $a } keys %$detail) {
            $debugfileMessage .= "<TR style=\"font: normal 68% verdana,arial,helvetica; background:$backgroundColor;\">". $detail->{$key} ."</TR>";
          }
        }

        $debugfileMessage .= "</TABLE>\n";
      }

      $debugfileMessage .= "<BR>\n";
    }

    my ($number, $tAlertFixed, $tAlertVariable);
    $tAlertFixed = $tAlertVariable = '';
    $number = 0;
    while ( my ($key, $value) = each(%tableVirtualServers) ) { $tAlertFixed .= "+$key"; $tAlertVariable .= "+$key $value"; $number++; }

    if ($number) {
      my $alert = "$tAlertVariable+, $tAlertFixed+" ;

      if ($currentTimeslot - $tEpochtime > $outOffDate) {
        $alert .= ' - Data is out of date!';
        $alert .= ' - From: ' .scalar(localtime($tEpochtime)). ' - Now: ' .scalar(localtime($currentTimeslot)) if ( $debug >= 2 );
        $objectPlugins->pluginValues ( { stateValue => ($tSeverity == 0 ? $ERRORS{UNKNOWN} : $tSeverity), alert => $alert }, $TYPE{APPEND} );
      } else {
        $objectPlugins->pluginValues ( { stateError => $STATE{$tSeverity}, alert => $alert }, $TYPE{APPEND} );
      }
    } else {
      $objectPlugins->pluginValues ( { stateError => $STATE{$tSeverity}, alert => 'No new problems available.' }, $TYPE{APPEND} );
    }

    $sth->finish() or $rv = errorTrapDBI ( \$objectPlugins,  'Cannot sth->finish: '. $query );
  } 

  $dbh->disconnect() or $rv = errorTrapDBI ( \$objectPlugins,  'The database $serverDb was unable to read your entry.' );
}

$debugfileMessage .= "<P style=\"font: normal 68% verdana,arial,helvetica;\" ALIGN=\"left\">Generated on: " .scalar(localtime()). "</P>\n</BODY>\n</HTML>";
$objectPlugins->write_debugfile ( \$debugfileMessage, 0 );

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
