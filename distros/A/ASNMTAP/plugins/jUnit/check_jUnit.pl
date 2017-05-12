#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_jUnit.pl
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

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

use ASNMTAP::Asnmtap::Plugins::XML v3.002.003;
use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_jUnit.pl',
  _programDescription => 'Check jUnit Server',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '--uKey|-K=<uKey> --jUnitServer=<jUnitServer> --jUnitPort=<jUnitPort> --svParam=<svParam> [--maxtime=<maxtime>] [--config=<config>] [--result=<result>]',
  _programHelpPrefix  => '-K, --uKey=<uKey>
--jUnitServer=<jUnitServer>
   <jUnitServer>=jUnit server hostname
--jUnitPort=<jUnitPort>
   <jUnitPort>=jUnit server port number
--svParam=<svParam>
--maxtime=<maxtime>
--config=<config>
   <config>=config database
--result=<result>
   <result>=result database',
  _programGetOptions  => ['uKey|K=s', 'jUnitServer=s', 'jUnitPort=s', 'svParam=s', 'maxtime:i', 'config:s', 'result:s', 'interval|i=i', 'port|P:i', 'username|u|loginname:s', 'password|passwd|p:s', 'environment|e:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $environment = $objectPlugins->getOptionsArgv ('environment');

my $uniqueKey   = $objectPlugins->getOptionsArgv ('uKey');
$objectPlugins->printUsage ( 'Missing uKey' ) unless ( defined $uniqueKey );

my $jUnitServer = $objectPlugins->getOptionsArgv ('jUnitServer');
$objectPlugins->printUsage ( 'Missing jUnitServer' ) unless ( defined $jUnitServer );

my $jUnitPort   = $objectPlugins->getOptionsArgv ('jUnitPort');
$objectPlugins->printUsage ( 'Missing jUnitPort' ) unless ( defined $jUnitPort );

my $svParam     = $objectPlugins->getOptionsArgv ('svParam');
$objectPlugins->printUsage ( 'Missing svParams' ) unless ( defined $svParam );

my $interval    = $objectPlugins->getOptionsArgv ('interval');
my $maxtime     = $objectPlugins->getOptionsArgv ('maxtime');
my $config      = $objectPlugins->getOptionsArgv ('config');
my $result      = $objectPlugins->getOptionsArgv ('result');
my $port        = $objectPlugins->getOptionsArgv ('port');
my $username    = $objectPlugins->getOptionsArgv ('username');
my $password    = $objectPlugins->getOptionsArgv ('password');

my $debug       = $objectPlugins->getOptionsValue ('debug');
my $onDemand    = $objectPlugins->getOptionsValue ('onDemand');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $XMLHEADER           = '<\?xml\s+version="1.0"\s+encoding="UTF-8"\?>';
use constant HEADER    => '<?xml version="1.0" encoding="UTF-8"?>';
use constant FOOTER    => '</testresult>';

# crinaea MySQL connection parameters
my $asnmtapServerName   = "<server>";
my $asnmtapServerPort   = "3306";
my $asnmtapServerUser   = "asnmtap";
my $asnmtapServerPass   = "<password>";
my $asnmtapServerDb     = "odbc";
my $asnmtapServerTabl   = "jUnit";

# jUnit Server MySQL connection parameters
my $jUnitServerName     = (defined $jUnitServer) ? $jUnitServer : '<server>';
my $jUnitServerPort     = (defined $port)        ? $port        : '3306';
my $jUnitServerUser     = (defined $username)    ? $username    : 'jUnit';
my $jUnitServerPass     = (defined $password)    ? $password    : '<password>';
my $jUnitServerDbC      = (defined $config)      ? $config      : 'jUnitConfig';
my $jUnitServerDbDR     = (defined $result)      ? $result      : 'jUnitData';
my $jUnitServerTablS    = 'SERVER';
my $jUnitServerTablBS   = 'BASE_SERVICES';
my $jUnitServerTablDR   = 'DATA_RESULTS';
my $jUnitServerTablDRA  = 'DATA_RESULTS_ARCHIVE';

# jUnit Server parameters
   $jUnitServer         = $jUnitServerName;
my $jUnitService        = 'jUnit';
my $jUnitUsername       = 'junitmanager';
my $jUnitPassword       = 'tdvmim';
my $jUnitRequest        = 'junitserver signal SENT_OK';
my $jUnitUkey           = $uniqueKey;
my $jUnitType           = ($onDemand) ? '0' : '1';
my $jUnitSvparam        = (defined $svParam) ? $svParam : '';
my $jUnitMaxtime        = (defined $maxtime) ? $maxtime : 30;

my ($testcaseTimewait, $testcaseServer, $testcaseWlsusername, $testcaseWlspassword, $testcaseAppname, $testcaseEejbname, $testcaseVersion, $testcaseParameters, $testcaseTestclass);

my $resultOutOfDate     = $interval;

my $xmlCleanUpSpaces    = 1;
my $xmlCleanUpLineFeeds = 1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# $testcaseServer     : <protocol>://<servername>:<port number>
# $testcaseServer     : - missing protocol  => <error message="javax.naming.ConfigurationException [Root exception is java.net.MalformedURLException: no protocol
# $testcaseServer     : - wrong protocol    => <error message="javax.naming.CommunicationException [Root exception is java.net.UnknownHostException: Unknown protocol: '<protocol>']
# $testcaseServer     : - wrong servername  => <error message="javax.naming.CommunicationException [Root exception is java.net.ConnectException: <protocol>://<servername>:<port number>: Destination unreachable; nested exception is:
# $testcaseServer     : - wrong port number => <error message="javax.naming.CommunicationException [Root exception is java.net.ConnectException: <protocol>://<servername>:<port number>: Destination unreachable; nested exception is:

# $testcaseWlsusername: - wrong username => <error message="javax.naming.AuthenticationException [Root exception is java.lang.SecurityException: User: username00, failed to be authenticated.]" type="java.util.MissingResourceException">
# $testcaseWlspassword: - wrong password => <error message="javax.naming.AuthenticationException [Root exception is java.lang.SecurityException: User: username00, failed to be authenticated.]" type="java.util.MissingResourceException">

# $testcaseAppname    : - don't exist => be.citap.common.systemservices.junitserver.core.exception.TestCaseFinderException: no file found in application directory
# $testcaseAppname    : - wrong name  => be.citap.common.systemservices.junitserver.core.exception.TestCaseFinderException: no file found in application directory

# $testcaseEejbname   : - don't exist => <error message="javax.naming.CommunicationException [Root exception is java.net.ConnectException: <protocol>://<servername>:<port number>: Destination unreachable; nested exception is:
# $testcaseEejbname   : - wrong name  => <error message="javax.naming.CommunicationException [Root exception is java.net.ConnectException: <protocol>://<servername>:<port number>: Destination unreachable; nested exception is:

# $testcaseVersion    : = '';

# $testcaseParameters : - 'null'          => <error message="javax.naming.CommunicationException [Root exception is java.net.ConnectException: <protocol>://<servername>:<port number>: Destination unreachable; nested exception is:
# $testcaseParameters : - don(t exist     => <error message="javax.naming.CommunicationException [Root exception is java.net.ConnectException: <protocol>://<servername>:<port number>: Destination unreachable; nested exception is:
# $testcaseParameters : - wrong parameter => <error message="javax.naming.CommunicationException [Root exception is java.net.ConnectException: <protocol>://<servername>:<port number>: Destination unreachable; nested exception is:
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($rv, $dbh, $sth, $sql, $xml, $stateXML, $numberRecordsSameUkey, $returnCode);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Evaluate previous test

$rv  = 1;
$dbh = DBI->connect("DBI:mysql:$jUnitServerDbC:$jUnitServerName:$jUnitServerPort", "$jUnitServerUser", "$jUnitServerPass") or $rv = errorTrapDBI (\$objectPlugins, "Sorry, cannot connect to the database: $jUnitServerDbC:$jUnitServerName:$jUnitServerPort");

if ($dbh and $rv) {
  $sql = "select count(UKEY) from $jUnitServerTablBS, $jUnitServerTablS where UKEY = '$jUnitUkey' and $jUnitServerTablBS.SERV_ID = $jUnitServerTablS.SERV_ID and ACTIVATED = '1' and STATUS = 'ASNMTAP'";
  $sth = $dbh->prepare($sql) or $rv = errorTrapDBI (\$objectPlugins, "dbh->prepare: $sql");
  $rv  = $sth->execute() or $rv = errorTrapDBI (\$objectPlugins, "sth->execute: $sql") if $rv;
  $numberRecordsSameUkey = ($rv) ? $sth->fetchrow_array() : 0;
  $sth->finish() or $rv = errorTrapDBI (\$objectPlugins, "sth->finish");
  print "$sql < $numberRecordsSameUkey >\n" if ( $debug );
  $dbh->disconnect() or $rv = errorTrapDBI (\$objectPlugins, "Sorry, $jUnitServerDbC:$jUnitServerName:$jUnitServerPort was unable to disconnect."); 
}

$dbh = DBI->connect("DBI:mysql:$jUnitServerDbDR:$jUnitServerName:$jUnitServerPort", "$jUnitServerUser", "$jUnitServerPass") or $rv = errorTrapDBI (\$objectPlugins, "Sorry, cannot connect to the database: $jUnitServerDbDR:$jUnitServerName:$jUnitServerPort") if $rv;

if ($dbh and $rv) {
  my $jUnitSvparamSql = ($jUnitSvparam eq '') ? '' : " and SVPARAM = '$jUnitSvparam'";
  $sql = "select RESULT_ID, SERV_ID, UKEY, TESTTYPE, SVPARAM, STATUS, ERROR_CODE, EXCEPTION, INPUT_XML, OUTPUT_XML, STARTED_DT, ENDED_DT, REQUESTED_DT, FINISHED_DT, TIMESLOT from $jUnitServerTablDR where UKEY = '$jUnitUkey'". $jUnitSvparamSql ." order by RESULT_ID desc";
  print "$sql\n" if ( $debug );
  $sth = $dbh->prepare($sql) or $rv = errorTrapDBI (\$objectPlugins, "dbh->prepare: $sql");
  $rv  = $sth->execute() or $rv = errorTrapDBI (\$objectPlugins, "sth->execute: $sql") if $rv;

  if ( $rv ) {
    my $currentTimeslot = timelocal (0, (localtime)[1,2,3,4,5]);

    my $httpdumpMessage;
    my ($RESULT_ID, $SERV_ID, $UKEY, $TESTTYPE, $SVPARAM, $STATUS, $ERROR_CODE, $EXCEPTION, $INPUT_XML, $OUTPUT_XML, $STARTED_DT, $ENDED_DT, $REQUESTED_DT, $FINISHED_DT, $TIMESLOT);
    my ($recordCount, $performanceDataTests, $performanceDataFailures, $performanceDataErrors, $performanceDataTime);
    $recordCount = $performanceDataTests = $performanceDataFailures = $performanceDataErrors = $performanceDataTime = 0;
    my $alertError = '+';

    while ( my $ref = $sth->fetchrow_hashref() ) {
      $recordCount++;
      $RESULT_ID    = (defined $ref->{RESULT_ID})    ? $ref->{RESULT_ID}    : '';
      $SERV_ID      = (defined $ref->{SERV_ID})      ? $ref->{SERV_ID}      : '';
      $UKEY         = (defined $ref->{UKEY})         ? $ref->{UKEY}         : '';
      $TESTTYPE     = (defined $ref->{TESTTYPE})     ? $ref->{TESTTYPE}     : '';
      $SVPARAM      = (defined $ref->{SVPARAM})      ? $ref->{SVPARAM}      : '';
      $STATUS       = (defined $ref->{STATUS})       ? $ref->{STATUS}       : '';
      $ERROR_CODE   = (defined $ref->{ERROR_CODE})   ? $ref->{ERROR_CODE}   : '';
      $EXCEPTION    = (defined $ref->{EXCEPTION})    ? $ref->{EXCEPTION}    : '';
      $INPUT_XML    = (defined $ref->{INPUT_XML})    ? $ref->{INPUT_XML}    : '';
      $OUTPUT_XML   = (defined $ref->{OUTPUT_XML})   ? $ref->{OUTPUT_XML}   : '';
      $STARTED_DT   = (defined $ref->{STARTED_DT})   ? $ref->{STARTED_DT}   : '';
      $ENDED_DT     = (defined $ref->{ENDED_DT})     ? $ref->{ENDED_DT}     : '';
      $REQUESTED_DT = (defined $ref->{REQUESTED_DT}) ? $ref->{REQUESTED_DT} : '';
      $FINISHED_DT  = (defined $ref->{FINISHED_DT})  ? $ref->{FINISHED_DT}  : '';
      $TIMESLOT     = (defined $ref->{TIMESLOT})     ? $ref->{TIMESLOT}     : '';
      print "$RESULT_ID\n$SERV_ID\n$UKEY\n$TESTTYPE\n$SVPARAM\n$STATUS\n$ERROR_CODE\n$EXCEPTION\n$INPUT_XML\n$OUTPUT_XML\n$STARTED_DT\n$ENDED_DT\n$REQUESTED_DT\n$FINISHED_DT\n$TIMESLOT\n" if ( $debug );
      print "$STATUS\n$ERROR_CODE\n" if ($debug == 2);

      if ( $currentTimeslot - $TIMESLOT > $resultOutOfDate ) {
        my $alert = "Result into database is out of date";
        $alert = "Run ondemand test again PLEASE, $alert" if ( $SVPARAM =~ /ONDEMAND/ );
        $objectPlugins->pluginValues ( { stateValue => $ERRORS{WARNING}, alert => $alert }, $TYPE{APPEND} );
      } elsif ($STATUS eq 'OK') {
        ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, resultXML => $OUTPUT_XML, headerXML => HEADER, footerXML => FOOTER, validateDTD => 0 );

        unless ($returnCode) {
          my (undef, $testresultSuffix) = split ( /\@/, $xml->{name} );
          my $testresultName = (defined $testresultSuffix) ? '_' .$testresultSuffix : '';

          if ( $debug ) {
            print "xml->{version}<->\n",      $xml->{version},      "\n";
            print "xml->{name}<->\n",         $xml->{name},         "\n";
            print "xml->{server}<->\n",       $xml->{server},       "\n";
            print "xml->{Test_success}<->\n", $xml->{Test_success}, "\n";

            if ( defined $xml->{testClass}->{name} ) {
              print "xml->{testClass}->{name}<->\n",     $xml->{testClass}->{name},     "\n";
              print "xml->{testClass}->{package}<->\n",  $xml->{testClass}->{package},  "\n";
              print "xml->{testClass}->{tests}<->\n",    $xml->{testClass}->{tests},    "\n";
              print "xml->{testClass}->{failures}<->\n", $xml->{testClass}->{failures}, "\n";
              print "xml->{testClass}->{errors}<->\n",   $xml->{testClass}->{errors},   "\n";
              print "xml->{testClass}->{time}<->\n",     $xml->{testClass}->{time},     "\n";

              if (defined $xml->{testClass}->{testcase}->{name}) {
                print "xml->{testClass}->{testcase}->{name}<->\n", $xml->{testClass}->{testcase}->{name}, "\n";
                print "xml->{testClass}->{testcase}->{time}<->\n", $xml->{testClass}->{testcase}->{time}, "\n";
              } else {
                foreach my $testcase_name (keys %{$xml->{testClass}->{testcase}}) {
                  print "xml->{testClass}->{testcase}->{$testcase_name}->{time}<->\n", $xml->{testClass}->{testcase}->{$testcase_name}->{time}, "\n";
                }
              }
            }
          }
		  
          if ( defined $xml->{Test_success} and $xml->{Test_success} =~ /^True$/i ) {
            if ( defined $xml->{testClass}->{name} ) {
              $performanceDataTests    += $xml->{testClass}->{tests};
              $performanceDataFailures += $xml->{testClass}->{failures};
              $performanceDataErrors   += $xml->{testClass}->{errors};
              $performanceDataTime     += $xml->{testClass}->{time};

              if (defined $xml->{testClass}->{testcase}->{name}) {
                $objectPlugins->appendPerformanceData ( "'" .$xml->{testClass}->{testcase}->{name}.$testresultName. "'=". $xml->{testClass}->{testcase}->{time} .'s;;;;' );
              } else {
                foreach my $testcase_name (keys %{$xml->{testClass}->{testcase}}) {
                  print "xml->{testClass}->{testcase}->{$testcase_name}->{time}<->\n", $xml->{testClass}->{testcase}->{$testcase_name}->{time}, "\n" if ($debug == 2);
                  $objectPlugins->appendPerformanceData ( "'".$testcase_name.$testresultName."'=". $xml->{testClass}->{testcase}->{$testcase_name}->{time} .'s;;;;' );
                }
              }
            }
          } else {
            $objectPlugins->pluginValue ( stateValue => $ERRORS{UNKNOWN} );
          }
        }
      } elsif ($STATUS =~ /(NOTOK|TIMEOUT)/) {
        if ($EXCEPTION eq '') {
          print "EXCEPTION ...\n" if ( $debug );
        } elsif ( $EXCEPTION =~ m/^$XMLHEADER/i ) {
          ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, resultXML => $EXCEPTION, headerXML => HEADER, footerXML => FOOTER, validateDTD => 0 );

          unless ($returnCode) {
            my (undef, $testresultSuffix) = split ( /\@/, $xml->{name} );
            my $testresultName = (defined $testresultSuffix) ? '_' .$testresultSuffix : '';

            if ( $debug ) {
              print "xml->{version}<->\n",               $xml->{version},               "\n";
              print "xml->{name}<->\n",                  $xml->{name},                  "\n";
              print "xml->{server}<->\n",                $xml->{server},                "\n";
              print "xml->{Test_success}<->\n",          $xml->{Test_success},          "\n";
              print "xml->{testClass}->{tests}<->\n",    $xml->{testClass}->{tests},    "\n";
              print "xml->{testClass}->{failures}<->\n", $xml->{testClass}->{failures}, "\n";
              print "xml->{testClass}->{errors}<->\n",   $xml->{testClass}->{errors},   "\n";
              print "xml->{testClass}->{name}<->\n",     $xml->{testClass}->{name},     "\n";
              print "xml->{testClass}->{package}<->\n",  $xml->{testClass}->{package},  "\n";

              if (defined $xml->{testClass}->{testcase}->{name}) {
                print "xml->{testClass}->{testcase}->{name}<->\n", $xml->{testClass}->{testcase}->{name}, "\n";
                print "xml->{testClass}->{testcase}->{time}<->\n", $xml->{testClass}->{testcase}->{time}, "\n";

                if ( defined $xml->{testClass}->{testcase}->{error} ) {
                  print "xml->{testClass}->{testcase}->{error}->{content}<->\n", $xml->{testClass}->{testcase}->{error}->{content}, "\n";
                  print "xml->{testClass}->{testcase}->{error}->{type}<->\n",    $xml->{testClass}->{testcase}->{error}->{type},    "\n";
                  print "xml->{testClass}->{testcase}->{error}->{message}<->\n", $xml->{testClass}->{testcase}->{error}->{message}, "\n";
                }

                if ( defined $xml->{testClass}->{testcase}->{failure} ) {
                  print "xml->{testClass}->{testcase}->{failure}->{content}<->\n", $xml->{testClass}->{testcase}->{failure}->{content}, "\n";
                  print "xml->{testClass}->{testcase}->{failure}->{type}<->\n",    $xml->{testClass}->{testcase}->{failure}->{type},    "\n";
                  print "xml->{testClass}->{testcase}->{failure}->{message}<->\n", $xml->{testClass}->{testcase}->{failure}->{message}, "\n";
                }
              } else {
                foreach my $testcase_name (keys %{$xml->{testClass}->{testcase}}) {
                  print "xml->{testClass}->{testcase}->{$testcase_name}->{time}<->\n", $xml->{testClass}->{testcase}->{$testcase_name}->{time}, "\n";

                  if ( defined $xml->{testClass}->{testcase}->{$testcase_name}->{error} ) {
                    print "xml->{testClass}->{testcase}->{$testcase_name}->{error}->{content}<->\n", $xml->{testClass}->{testcase}->{$testcase_name}->{error}->{content}, "\n";
                    print "xml->{testClass}->{testcase}->{$testcase_name}->{error}->{type}<->\n",    $xml->{testClass}->{testcase}->{$testcase_name}->{error}->{type},    "\n";
                    print "xml->{testClass}->{testcase}->{$testcase_name}->{error}->{message}<->\n", $xml->{testClass}->{testcase}->{$testcase_name}->{error}->{message}, "\n";
                  }

                  if ( defined $xml->{testClass}->{testcase}->{$testcase_name}->{failure} ) {
                    print "xml->{testClass}->{testcase}->{$testcase_name}->{failure}->{content}<->\n", $xml->{testClass}->{testcase}->{$testcase_name}->{failure}->{content}, "\n";
                    print "xml->{testClass}->{testcase}->{$testcase_name}->{failure}->{type}<->\n",    $xml->{testClass}->{testcase}->{$testcase_name}->{failure}->{type},    "\n";
                    print "xml->{testClass}->{testcase}->{$testcase_name}->{failure}->{message}<->\n", $xml->{testClass}->{testcase}->{$testcase_name}->{failure}->{message}, "\n";
                  }
                }
              }
            }

            if ( defined $xml->{Test_success} and $xml->{Test_success} !~ /^True$/i ) {
              $performanceDataTests    += $xml->{testClass}->{tests};
              $performanceDataFailures += $xml->{testClass}->{failures};
              $performanceDataErrors   += $xml->{testClass}->{errors};
              $performanceDataTime     += $xml->{testClass}->{time};

              if (defined $xml->{testClass}->{testcase}->{name}) {
                $objectPlugins->appendPerformanceData ( "'" .$xml->{testClass}->{testcase}->{name}.$testresultName. "'=". $xml->{testClass}->{testcase}->{time} .'s;;;;' );
              } else {
                foreach my $testcase_name (keys %{$xml->{testClass}->{testcase}}) {
                  print "xml->{testClass}->{testcase}->{$testcase_name}->{time}<->\n", $xml->{testClass}->{testcase}->{$testcase_name}->{time}, "\n" if ($debug == 2);
                  $objectPlugins->appendPerformanceData ( "'".$testcase_name.$testresultName."'=". $xml->{testClass}->{testcase}->{$testcase_name}->{time} .'s;;;;' );
                }
              }

              $objectPlugins->pluginValue ( stateValue => $ERRORS{CRITICAL} );

              unless (defined $httpdumpMessage) {
                $httpdumpMessage  = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n<HTML><HEAD><TITLE>jUnit XML::Parser \@ $APPLICATION</TITLE></HEAD><BODY><HR><H1 style=\"margin: 0px 0px 5px; font: 125% verdana,arial,helvetica\">jUnit @ $APPLICATION</H1><HR>\n";
              } else {
                $httpdumpMessage .= "<BR>";
              }

              $httpdumpMessage .= "<H2 style=\"margin-top: 1em; margin-bottom: 0.5em; font: bold 100% verdana,arial,helvetica\">Server : $xml->{server}</H2>";
              $httpdumpMessage .= "<H2 style=\"margin-top: 1em; margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">Summary: $xml->{name} ($xml->{version}) - $xml->{Test_success}</H2>";

              $httpdumpMessage .= "<TABLE WIDTH=\"100%\"><TR style=\"font: normal 68% bold verdana,arial,helvetica; text-align:left; background:#a6caf0;\"><TH>Tests</TH><TH>Failures</TH><TH>Errors</TH><TH>Time</TH></TR>";
              $httpdumpMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:purple;\"><TD>$xml->{testClass}->{tests}</TD><TD>$xml->{testClass}->{failures}</TD><TD>$xml->{testClass}->{errors}</TD><TD>$xml->{testClass}->{time}";
              $httpdumpMessage .= "</TD></TR></TABLE>\n";
              $httpdumpMessage .= "<table width=\"100%\" border=\"0\"><tr><td style=\"font: verdana,arial,helvetica; text-align: justify;\">Note: <i>failures</i> are anticipated and checked for with assertions while <i>errors</i> are unanticipated.</td></tr></table>\n";

              $httpdumpMessage .= "<H3 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">Testcase: $xml->{testClass}->{name} ($xml->{testClass}->{package})</H3>\n";
              $httpdumpMessage .= "<TABLE WIDTH=\"100%\"><TR style=\"font: normal 68% bold verdana,arial,helvetica; text-align:left; background:#a6caf0;\"><TH>Name</TH><TH>Status</TH><TH>Type</TH><TH>Time</TH></TR>\n";

              if (defined $xml->{testClass}->{testcase}->{name}) {
                my ($status, $type, $message, $content);

                if (defined $xml->{testClass}->{testcase}->{error}) {
                  $status  = 'ERROR';
                  $type    = $xml->{testClass}->{testcase}->{error}->{type};
                  $message = $xml->{testClass}->{testcase}->{error}->{message};
                  $content = $xml->{testClass}->{testcase}->{error}->{content};
                } elsif (defined $xml->{testClass}->{testcase}->{failure}) {
                  $status  = 'FAILURE';
                  $type    = $xml->{testClass}->{testcase}->{failure}->{type};
                  $message = $xml->{testClass}->{testcase}->{failure}->{message};
                } else {
                  $status  = 'OK';
                  $type    = $message = '';
                }

                $httpdumpMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD>$xml->{testClass}->{testcase}->{name}</TD><TD>$status</TD><TD>$type</TD><TD>$xml->{testClass}->{testcase}->{time}</TD></TR>";

                if ($status ne 'OK') {
                  $httpdumpMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD></TD><TD colspan=\"3\"><PRE>$message</PRE></TD></TR>\n";
                  $httpdumpMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD></TD><TD colspan=\"3\"><PRE>$content</PRE></TD></TR>\n" if (defined $content);
                }
              } else {
                foreach my $testcase_name (keys %{$xml->{testClass}->{testcase}}) {
                  my ($status, $type, $message, $content);

                  if (defined $xml->{testClass}->{testcase}->{$testcase_name}->{error}) {
                    $status  = 'ERROR';
                    $type    = $xml->{testClass}->{testcase}->{$testcase_name}->{error}->{type};
                    $message = $xml->{testClass}->{testcase}->{$testcase_name}->{error}->{message};
                    $content = $xml->{testClass}->{testcase}->{$testcase_name}->{error}->{content};
                  } elsif (defined $xml->{testClass}->{testcase}->{$testcase_name}->{failure}) {
                    $status  = 'FAILURE';
                    $type    = $xml->{testClass}->{testcase}->{$testcase_name}->{failure}->{type};
                    $message = $xml->{testClass}->{testcase}->{$testcase_name}->{failure}->{message};
                  } else {
                    $status  = 'OK';
                    $type    = $message = '';
                  }

                  $httpdumpMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD>$testcase_name</TD><TD>$status</TD><TD>$type</TD><TD>$xml->{testClass}->{testcase}->{$testcase_name}->{time}</TD></TR>";

                  if ($status ne 'OK') {
                    $httpdumpMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD></TD><TD colspan=\"3\"><PRE>$message</PRE></TD></TR>\n";
                    $httpdumpMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD></TD><TD colspan=\"3\"><PRE>$content</PRE></TD></TR>\n" if (defined $content);
                  }
                }
              }

              $httpdumpMessage .= "</TABLE>\n";
            }

            $alertError .= (defined $testresultSuffix) ? $testresultSuffix : $xml->{name};
            $alertError .= '+';
          }
        } else {
          print "$EXCEPTION\n" if ($debug == 2);
        }

        print "$INPUT_XML\n" if ($debug == 2);
      } elsif ($STATUS eq 'LAUNCH_FAILED') {
        $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => $EXCEPTION }, $TYPE{APPEND} );
      } elsif ($STATUS eq 'XML_WRONG_FORMAT') {
        $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => 'Under construction: '. $STATUS }, $TYPE{APPEND} );
      } else {
        $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "Undefined error: '$STATUS'" }, $TYPE{APPEND} );
      }

      my $sqlMOVE = 'REPLACE INTO `' .$jUnitServerTablDRA. '` SELECT * FROM `' .$jUnitServerTablDR. '` WHERE RESULT_ID = "' .$RESULT_ID. '"';
      $dbh->do( $sqlMOVE ) or $rv = errorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlMOVE");

      if ( $rv ) {
        $sqlMOVE = 'DELETE FROM `' .$jUnitServerTablDR. '` WHERE RESULT_ID = "' .$RESULT_ID. '"';
        $dbh->do( $sqlMOVE ) or $rv = errorTrapDBI (\$objectPlugins, "Cannot dbh->do: $sqlMOVE");
      }
    }

    $httpdumpMessage .= "</BODY>\n</HTML>" if (defined $httpdumpMessage);

    $objectPlugins->appendPerformanceData ( 'tests='. $performanceDataTests .';;;;' );
    $objectPlugins->appendPerformanceData ( 'failures='. $performanceDataFailures .';1;;0;'. $performanceDataTests );
    $objectPlugins->appendPerformanceData ( 'errors='. $performanceDataErrors .';;1;0;'. $performanceDataTests );
    $objectPlugins->appendPerformanceData ( 'time='. $performanceDataTime .'s;;;;' );

    if ( $recordCount ) {
      if ( $numberRecordsSameUkey != $recordCount ) {
        $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "Only $recordCount from the wanted $numberRecordsSameUkey results into the table $jUnitServerTablDR from database $jUnitServerDbDR" }, $TYPE{APPEND} );
      }

      if ($alertError eq '+') {
        $objectPlugins->pluginValues ( { alert => 'All test succeed' }, $TYPE{APPEND} );
      } else {
        $objectPlugins->pluginValues ( { alert => $alertError }, $TYPE{APPEND} );
      }

      if (defined $httpdumpMessage) {
        print "$httpdumpMessage\n" if ($debug == 4);
        $objectPlugins->write_debugfile ( \$httpdumpMessage, 0 );
      }
    } else {
      $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => "No results into the table $jUnitServerTablDR from database $jUnitServerDbDR" }, $TYPE{APPEND} );
    }

    $sth->finish() or $rv = errorTrapDBI (\$objectPlugins, "sth->finish: $sql");
  }

  $dbh->disconnect() or $rv = errorTrapDBI (\$objectPlugins, "Sorry, $jUnitServerDbDR:$jUnitServerName:$jUnitServerPort was unable to disconnect."); 
}

# Launch new test - - - - - - - - - - - - - - - - - - - - - - - - - - - -
my ($_ACTIVATED, $_STATUS);

$rv  = 1;
$dbh = DBI->connect("DBI:mysql:$jUnitServerDbC:$jUnitServerName:$jUnitServerPort", "$jUnitServerUser", "$jUnitServerPass") or $rv = errorTrapDBI (\$objectPlugins, "Sorry, cannot connect to the database: $jUnitServerDbC:$jUnitServerName:$jUnitServerPort");

if ($dbh and $rv) {
  $sql = "select ACTIVATED, STATUS, NAME, WLSUSERNAME, WLSPASSWORD, APPNAME, EJBNAME, VERSION, PARAMETERS, TESTCLASS, TIMEWAIT, MAXTIME from $jUnitServerTablBS, $jUnitServerTablS where UKEY = '$jUnitUkey' and $jUnitServerTablBS.SERV_ID = $jUnitServerTablS.SERV_ID";
  print "$sql\n" if ( $debug );

  $sth = $dbh->prepare($sql) or $rv = errorTrapDBI (\$objectPlugins, "dbh->prepare: $sql");
  $rv  = $sth->execute() or $rv = errorTrapDBI (\$objectPlugins, "sth->execute: $sql") if $rv;

  if ( $rv ) {
    my $testcases;

    while (my $ref = $sth->fetchrow_hashref()) {
      $_ACTIVATED = (defined $ref->{ACTIVATED}) ? $ref->{ACTIVATED} : 0;
      $_STATUS = (defined $ref->{STATUS}) ? $ref->{STATUS} : undef;

      if ( $_ACTIVATED and $_STATUS eq 'ASNMTAP' ) {
        $testcaseServer      = (defined $ref->{NAME})        ? $ref->{NAME}        : '';
        $testcaseWlsusername = (defined $ref->{WLSUSERNAME}) ? $ref->{WLSUSERNAME} : '';
        $testcaseWlspassword = (defined $ref->{WLSPASSWORD}) ? $ref->{WLSPASSWORD} : '';
        $testcaseAppname     = (defined $ref->{APPNAME})     ? $ref->{APPNAME}     : '';
        $testcaseEejbname    = (defined $ref->{EJBNAME})     ? $ref->{EJBNAME}     : '';
        $testcaseVersion     = (defined $ref->{VERSION})     ? $ref->{VERSION}     : '';
        $testcaseParameters  = (defined $ref->{PARAMETERS})  ? $ref->{PARAMETERS}  : '';

        $testcaseTestclass   = (defined $ref->{TESTCLASS})   ? '<testclass>'. $ref->{TESTCLASS} .'</testclass>' : '';

        $testcaseTimewait    = (defined $ref->{TIMEWAIT} and $ref->{TIMEWAIT} > 0) ? '<timewait>'. $ref->{TIMEWAIT} .'</timewait>' : '';

        $jUnitMaxtime        = $ref->{MAXTIME} if (defined $ref->{MAXTIME} and $ref->{MAXTIME} > 0 and ! defined $maxtime);

        $testcases .= "
  <testcase>
    <server>$testcaseServer</server>
    <wlsusername>$testcaseWlsusername</wlsusername>
    <wlspassword>$testcaseWlspassword</wlspassword>
    <appname>$testcaseAppname</appname>
    <ejbname>$testcaseEejbname</ejbname>
    <version>$testcaseVersion</version>
    <parameters><![CDATA[$testcaseParameters]]></parameters>
    $testcaseTestclass
    $testcaseTimewait
  </testcase>";
      }
    }

    if ($_ACTIVATED and defined $testcases) {
      $xml = "<?xml version=\"1.0\" ?>
<junit>
  <username>$jUnitUsername</username>
  <password>$jUnitPassword</password>
  <ukey>$jUnitUkey</ukey>
  <type>$jUnitType</type>
  <svparam>$jUnitSvparam</svparam>
  <maxtime>$jUnitMaxtime</maxtime>
  $testcases
</junit>";
    }

    $sth->finish() or $rv = errorTrapDBI (\$objectPlugins, "sth->finish: $sql");
  }

  $dbh->disconnect() or $rv = errorTrapDBI (\$objectPlugins, "Sorry, $jUnitServerDbDR:$jUnitServerName:$jUnitServerPort was unable to disconnect."); 
}

if (defined $xml) {
  print "$xml\n" if ($debug == 4);
  ($returnCode) = scan_socket_info_jUnit (\$objectPlugins, 'tcp', $jUnitServer, $jUnitPort, $jUnitService, $jUnitRequest, 10, $xml, $debug);
} elsif ( defined $_ACTIVATED and ! $_ACTIVATED ) {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => "Test has been deactivated with status '$_STATUS' onto the jUnit server. PLEASE contact Monitoring Office" }, $TYPE{REPLACE} );
} elsif ( defined $_ACTIVATED and $_STATUS ne 'ASNMTAP' ) {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => "Test has been activated with status '$_STATUS' onto the jUnit server. PLEASE contact Monitoring Office" }, $TYPE{REPLACE} );
} else {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => "No base service defined into the table $jUnitServerTablDR from database $jUnitServerDbDR" }, $TYPE{APPEND} );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub scan_socket_info_jUnit {
  my ($asnmtapInherited, $protocol, $host, $port, $service, $request, $socketTimeout, $xml, $debug) = @_;

  my ($exit, $result, $action, $socketProtocol);
  $exit   = 0;
  $action = '<NIHIL>';

  print "\nscan_socket_info : <$protocol><$host><$port><$service><$request>\n$xml\n\n" if ($debug >= 2);

  if ($protocol eq 'tcp' || $protocol eq 'udp') { $socketProtocol = $protocol; } else { $socketProtocol = 'tcp'; }

  $SIG{ALRM} = sub { alarm (0); $exit = 1 };
  alarm ( 10 ); $exit = 0;

  use IO::Socket;

  if (defined $socketTimeout) {
    $result = new IO::Socket::INET ('Proto' => $socketProtocol, 'PeerAddr' => $host, 'PeerPort' => $port, 'Timeout' => $socketTimeout);
  } else {
    $result = new IO::Socket::INET ('Proto' => $socketProtocol, 'PeerAddr' => $host, 'PeerPort' => $port);
  }

  if ($result) {
    print "IO::Socket::INET : $result\n" if ($debug >= 2);
  } else {
    print "IO::Socket::INET : <NIHIL>\n" if ($debug >= 2);
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => "Cannot connect to $host:$port" }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  $result->autoflush(1);

  if ($socketProtocol eq 'tcp') {
    print "jUnit($port): wait for answer\n" if ($debug >= 2);

    while (<$result>) {
      chomp;
      print "jUnit($port): <$_>\n" if ($debug >= 2);
      if ($exit) { $action = '<TIMEOUT>'; last; }

      SWITCH: {
        if ($_ =~ /^junitserver signal INIT$/)                 {
		  $action = 'junitserver signal INIT'; 
		  $xml =~ s/\n//g if ($xmlCleanUpLineFeeds); 
		  $xml =~ s/> +</></g if ($xmlCleanUpSpaces); 
		  print $result "$xml\n";
		  print "$xml\n" if ( $debug );
        }

        if ($_ =~ /^junitserver signal XML_NOTOK$/)            { $action = 'junitserver signal XML_NOTOK'; last; }
        if ($_ =~ /^junitserver signal WRONG USER\/PASSWORD$/) { $action = 'junitserver signal WRONG USER/PASSWORD'; last; }
        if ($_ =~ /^junitserver signal SENT_OK$/)              { $action = 'junitserver signal SENT_OK'; last; }
      }
    }
  } elsif ($socketProtocol eq 'udp') {
    print "udp : $service($port), no RFC implementation\n" if ($debug >= 2);
  }

  alarm (0); $SIG{ALRM} = 'DEFAULT';
  close ( $result );

  unless (defined $request) { $request = "$service($port)"; }

  if ($request eq $action) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{OK}, alert => $action }, $TYPE{APPEND} );
    return ( $ERRORS{OK} );
  } else {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => "Wrong answer from $host $service: $action" }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub errorTrapDBI {
  my ($asnmtapInherited, $error_message) = @_;

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $error_message, error => "$DBI::err ($DBI::errstr)" }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

