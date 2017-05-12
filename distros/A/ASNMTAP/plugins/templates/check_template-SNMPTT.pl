#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-SNMPTT.pl
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
  _programName        => 'check_template-SNMPTT.pl',
  _programDescription => "SNMPTT plugin template for testing the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[--uKey|-K=<uKey>]',
  _programHelpPrefix  => '-K, --uKey=<uKey>',
  _programGetOptions  => ['uKey|K:s', 'community|C=s', 'host|H:s', 'environment|e=s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $uKey        = $objectPlugins->getOptionsArgv ('uKey');

my $community   = $objectPlugins->getOptionsArgv ('community');
my $hostname    = $objectPlugins->getOptionsArgv ('host');
my $category    = 'ASNMTAP';

my $environment = $objectPlugins->getOptionsArgv ('environment');

my $debug       = $objectPlugins->getOptionsValue ('debug');
my $onDemand    = $objectPlugins->getOptionsValue ('onDemand');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $environmentText = $objectPlugins->getOptionsValue ('environment');

my ($prefix, $suffix) = split ( /(snmp|v10)_/, $community );
my $domainname = ( defined $suffix ) ? $suffix : $prefix;

if ( defined $uKey ) {
  my $message = $objectPlugins->pluginValue ('message') .' for uKey '. $uKey;
  $objectPlugins->pluginValue ( message => $message );
}

my $tMessage  = 'SNMP Trap Translator Database';

my $tHostname = ( defined $hostname ? "and hostname='$hostname'" : '' );
$hostname = 'undef' unless ( defined $hostname ) ;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $serverHost = "dtbs.citap.be";
my $serverPort = "3306";
my $serverUser = "asnmtap";
my $serverPass = "<password>";
my $serverDb   = "snmptt";
my $serverTact = "<password>";
my $serverTarc = "snmptt_archive";

my $outOffDate = 1800; # seconds

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
  $sth = $dbh->prepare($query) or $rv = errorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $query ) if ( $rv );
  $rv  = $sth->execute() or $rv = errorTrapDBI ( \$objectPlugins, 'Cannot sth->execute: '. $query ) if ( $rv );
  $sth->bind_columns( \$id, \$eventname, \$eventid, \$trapoid, \$enterprise, \$agentip, \$severity, \$uptime, \$traptime, \$formatline, \$system_running_SNMPTT, \$trapread ) or $rv = errorTrapDBI ( \$objectPlugins, 'Cannot sth->bind_columns: '. $query ) if ( $rv );

  if ( $rv ) {
    my ($debugfileMessage, %tableVirtualServers, %tableVirtualServersDetail, %tableVirtualServersUniqueProblemSeverity);

    if ( $sth->rows() ) {
      my ( $uniqueProblem, $codeBefore, $codeAfter );
      $debugfileMessage  = "\n<HTML><HEAD><TITLE>$tMessage \@ $APPLICATION</TITLE><style type=\"text/css\">\n.statusOdd { font-family: arial,serif; font-size: 10pt; background-color: #DBDBDB; }\n.statusEven { font-family: arial,serif; font-size: 10pt; background-color: #C4C2C2; }\ntd.statusOK { font-family: arial,serif; font-size: 10pt; background-color: #33FF00; }\ntd.statusWARNING { font-family: arial,serif; font-size: 10pt; background-color: #FFFF00; }\ntd.statusCRITICAL { font-family: arial,serif; font-size: 10pt; background-color: #F83838; }\n</style>\n</HEAD><BODY><HR><H1 style=\"margin: 0px 0px 5px; font: 125% verdana,arial,helvetica\">$tMessage \@ $APPLICATION</H1><HR>\n";
      $debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR><TD>\n<H2 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">Domain: $domainname ($environmentText), BOLD: are the new traps</H2></TD></TR></TABLE>";

      while( $sth->fetch() ) {
        my ($_eventname, $detailLine, $uniqueTrap, $trapServerName, $trapMonitorType, $trapMBeanName, $trapMBeanType, $trapAttributeName) = ($eventname, $formatline, 'NULL', $tEpochtime);

        for ( $eventname ) {
          /^wlsLogNotification$/ && do {
            $uniqueTrap = 'wlsLogNotification';
		    last; };
          /^wlsServerStart$/ && do {
            $_eventname = 'wlsServerShutDown or wlsServerStart';
            $formatline =~ /^This trap is generated when the server (\w+) was started on /;
            $trapServerName = $1 if ( defined $1 );
            $uniqueTrap = 'wlsServerRestart';
		    last; };
          /^wlsServerShutDown$/ && do {
            $_eventname = 'wlsServerShutDown or wlsServerStart';
            $formatline =~ /^This trap is generated when the server (\w+) has been shut down /;
            $trapServerName = $1 if ( defined $1 );
            $uniqueTrap = 'wlsServerRestart';
		    last; };
          /^wlsMonitorNotification$/ && do {
            my (undef, $variables, ) = split ( /: /, $formatline );
            ($trapServerName, $trapMonitorType, $trapMBeanName, $trapMBeanType, $trapAttributeName) = split ( /, /, $variables );

            if ( $trapMonitorType =~ /^(jmx.monitor)\.(\w+)\.(\w+)$/ ) {
              $uniqueTrap = "$trapMBeanName|$trapAttributeName|$trapMBeanType|$1.$2";
              $detailLine = "$trapMBeanName, $trapAttributeName, $trapMBeanType, $1.$2.$3";
            }

		    last; };
          /^wlsAttributeChange$/ && do {
            $uniqueTrap = 'wlsAttributeChange';
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
            $dbh->do ($sqlUPDATE) or $rv = errorTrapDBI ( \$objectPlugins, 'Cannot dbh->do: '. $sqlUPDATE );

            if ( $rv ) {
              my $sqlSTRING = "SELECT count(*) FROM `$serverTarc` WHERE id='$id'";
              print "             ? $sqlSTRING\n" if ( $debug );
              $sthDO = $dbh->prepare( $sqlSTRING ) or $rv = errorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
              $sthDO->execute() or $rv = errorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;

              if ( $rv ) {
                my $updateRecord = $sthDO->fetchrow_array();
                $sthDO->finish() or $rv = errorTrapDBI ( \$objectPlugins, 'Cannot dbh->finish: '. $sqlSTRING );

                unless ( $updateRecord ) {
                  my $sqlINSERT = "INSERT INTO `$serverTarc` SELECT * FROM `$serverTact` WHERE id='$id'";
                  print "             + $sqlINSERT\n" if ( $debug );
                  $dbh->do ( $sqlINSERT ) or $rv = errorTrapDBI ( \$objectPlugins, 'Cannot dbh->do: '. $sqlINSERT );
                }

                if ( $rv ) {
                  my $sqlUPDATE = "UPDATE `$serverTact` SET trapread='2' WHERE id='$id'";
                  print "             = $sqlUPDATE\n" if ( $debug );
                  $dbh->do ($sqlUPDATE) or $rv = errorTrapDBI ( \$objectPlugins, 'Cannot dbh->do: '. $sqlUPDATE );
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
          my $sqlDELETE = "DELETE FROM `$serverTact` WHERE uniqueProblem='$uniqueProblem' and trapread='2'";

          if ( $debug >= 2 ) {
            print "             - $sqlDELETE\n";
            $debugfileMessage .= "<TABLE WIDTH=\"100%\" cellspacing=\"1\" cellpadding=\"1\"><TR style=\"font: normal 68% verdana,arial,helvetica; background:$backgroundColor;\"><TD colspan=\"2\">$sqlDELETE</TD></TR></TABLE>"; 
          } else {
            $dbh->do( $sqlDELETE ) or $rv = errorTrapDBI ( \$objectPlugins, 'Cannot dbh->do: '. $sqlDELETE );
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

    $debugfileMessage .= "<P style=\"font: normal 68% verdana,arial,helvetica;\" ALIGN=\"left\">Generated on: " .scalar(localtime()). "</P>\n</BODY>\n</HTML>";
    $objectPlugins->write_debugfile ( \$debugfileMessage, 0 );

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

    $sth->finish() or $rv = errorTrapDBI ( \$objectPlugins, 'Cannot sth->finish: '. $query );
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
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-SNMPTT.pl

SNMPTT plugin template for testing the 'Application Monitor'

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

