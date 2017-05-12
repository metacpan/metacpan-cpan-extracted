#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_xml-monitoring-1.2.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Date::Calc qw(check_date check_time);
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.002.003;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $schema = "1.2";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins::Nagios->new (
  _programName        => 'check_xml-monitoring-1.2.pl',
  _programDescription => 'Check Nagios by XML Monitoring 1.2',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '-H|--hostname <hostname> -s|--service <service> [-P|--plugin <plugin>] [-p|--parameters <parameters>] [--validation <validation>]',
  _programHelpPrefix  => "-H, --hostname=<Nagios Hostname>
-s, --service=<Nagios service name>
-P, --plugin=<plugin to execute>
-p, --parameters=<parameters for the plugin to execute>
--validation=F|T
   F(alse)       : dtd validation off (default)
   T(true)       : dtd validation on",
  _programGetOptions  => ['filename|F=s', 'hostname|H=s', 'service|s=s', 'plugin|P:s', 'parameters|p:s', 'validation:s', 'interval|i=i', 'environment|e=s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $filename = $objectNagios->getOptionsArgv ('filename');

my $hostname = $objectNagios->getOptionsArgv ('hostname') ? $objectNagios->getOptionsArgv ('hostname') : undef;
$objectNagios->printUsage ('Missing command line argument hostname') unless (defined $hostname);

my $service = $objectNagios->getOptionsArgv ('service') ? $objectNagios->getOptionsArgv ('service') : undef;
$objectNagios->printUsage ('Missing command line argument service') unless ( defined $service);

my $plugin      = $objectNagios->getOptionsArgv ('plugin')     ? $objectNagios->getOptionsArgv ('plugin')     : undef;
my $parameters  = $objectNagios->getOptionsArgv ('parameters') ? $objectNagios->getOptionsArgv ('parameters') : '';
my $validateDTD = $objectNagios->getOptionsArgv ('validation') ? $objectNagios->getOptionsArgv ('validation') : 'F';

if (defined $validateDTD) {
  $objectNagios->printUsage ('Invalid validation option: '. $validateDTD) unless ($validateDTD =~ /^[FT]$/);
  $validateDTD = ($validateDTD eq 'T') ? 1 : 0;
}

my $resultOutOfDate = $objectNagios->getOptionsArgv ('interval');

my $environment = $objectNagios->getOptionsArgv ('environment') ? $objectNagios->getOptionsArgv ('environment') : 'P';
my $environmentText = $objectNagios->getOptionsValue ('environment');

my $debug = $objectNagios->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);

use constant HEADER => '<?xml version="1.0" encoding="UTF-8"?>';
use constant FOOTER => '</mon:MonitoringXML>'; # use constant FOOTER => '</MonitoringXML>';

my ($reverse, $message, $result, $debugfileMessage) = ( 0, 'Check Nagios by XML Monitoring 1.2' );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ( defined $plugin ) {
  if (-s $plugin ) {
    $objectNagios->exit (3) if ( $objectNagios->call_system ( $plugin .' '. $parameters, 1 ) );
  } else {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "The Plugin '$plugin' doesn't exist" }, $TYPE{APPEND} );
    $objectNagios->exit (3);
  }
}

my ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectNagios, filenameXML => $filename, headerXML => HEADER, footerXML => FOOTER, validateDTD => $validateDTD, filenameDTD => "dtd/Monitoring-$schema.dtd" );
$objectNagios->exit (3) if ( $returnCode );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $currentTimeslot = timelocal ((localtime)[0,1,2,3,4,5]);
my %environment = ( P => 'PROD', S => 'SIM', A => 'ACC', T => 'TEST', D => 'DEV', L => 'LOCAL' );

if ($xml->{Monitoring}{Schema}{Value} eq $schema) {
  $debugfileMessage  = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n<HTML><HEAD><TITLE>$message \@ $APPLICATION</TITLE><style type=\"text/css\">\n.statusOdd { font-family: arial,serif; font-size: 10pt; background-color: #DBDBDB; }\n.statusEven { font-family: arial,serif; font-size: 10pt; background-color: #C4C2C2; }\ntd.statusOK { font-family: arial,serif; font-size: 10pt; background-color: #33FF00; }\ntd.statusWARNING { font-family: arial,serif; font-size: 10pt; background-color: #FFFF00; }\ntd.statusCRITICAL { font-family: arial,serif; font-size: 10pt; background-color: #F83838; }\ntd.statusUNKNOWN { font-family: arial,serif; font-size: 10pt; background-color: #FFFFFF; }\n</style>\n</HEAD><BODY><HR><H1 style=\"margin: 0px 0px 5px; font: 125% verdana,arial,helvetica\">$message @ $APPLICATION</H1><HR>\n";
  my $firstResults = 1;

  if ( ref $xml->{Monitoring}{Results} eq 'ARRAY' ) {
    foreach my $results (@{$xml->{Monitoring}{Results}}) {
      processAllResult ( \$debugfileMessage, $firstResults, \$results, $reverse, $debug );
      $firstResults = 0;
    }
  } else {
    processAllResult ( \$debugfileMessage, $firstResults, \$xml->{Monitoring}{Results}, $reverse, $debug );
  }

  $objectNagios->write_debugfile ( \$debugfileMessage, 0 );
} else {
  my $tError = 'Content Error: - Schema: '. $xml->{Monitoring}{Schema}{Value} ." ne $schema";
  $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $tError, result => undef }, $TYPE{APPEND} );
}

$objectNagios->exit (3);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub processAllResult {
  my ($debugfileMessage, $firstResults, $result, $reverse, $debug) = @_;

  my $match = ( $$result->{Details}{Host} eq $hostname and $$result->{Details}{Service} eq $service ) ? 1 : 0;

  if (! $firstResults or ($match and $$result->{Details}{Environment} =~ /^$environment{$environment}$/i)) {
    $$debugfileMessage .= "\n<TABLE WIDTH=\"100%\"><TR><TD>\n<H3 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">Environment: $environmentText</H3></TD></TR></TABLE>\n";
    $$debugfileMessage .= "\n<TABLE WIDTH=\"100%\">";

    validateResultOrSubResult ( $firstResults, \$$result, 0, $reverse, $debug );

    if ( defined $$result->{SubResults} ) {
      if ( ref $$result->{SubResults} eq 'ARRAY' ) {
        foreach my $subResults (@{$$result->{SubResults}}) {
          validateResultOrSubResult ( $firstResults, \$subResults, 1, $reverse, $debug );
        }
      } else {
        validateResultOrSubResult ( $firstResults, \$$result->{SubResults}, 1, $reverse, $debug );
      }
    }

    $debugfileMessage .= "</TABLE>\n";
    $debugfileMessage .= "<P style=\"font: normal 68% verdana,arial,helvetica;\" ALIGN=\"left\">Generated on: " .scalar(localtime()). "</P>\n</BODY>\n</HTML>";
  } else {
    my $tError = 'Content Error:';
    $tError .= ' - Host: '. $$result->{Details}{Host} ." ne $hostname" if ($$result->{Details}{Host} ne $hostname);
    $tError .= ' - Service: '. $$result->{Details}{Service} ." ne $service" if ($$result->{Details}{Service} ne $service);
    $tError .= ' - Environment: ' .$$result->{Details}{Environment} ." ne ". $environment{$environment} if ($$result->{Details}{Environment} !~ /^$environment{$environment}$/i);
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $tError, result => undef }, $TYPE{APPEND} );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub validateResultOrSubResult {
  my ($firstResults, $result, $subResult, $reverse, $debug) = @_;

  my $label = ( $subResult == 0 ? 'Details' : 'SubDetails');

  if ( $debug ) {
    print $$result->{$label}{Host}, "\n", $$result->{$label}{Service}, "\n", $$result->{$label}{Environment}, "\n", $$result->{$label}{Date}, "\n", $$result->{$label}{Time}, "\n", $$result->{$label}{Epochtime}, "\n", $$result->{$label}{Status}, "\n", $$result->{$label}{StatusMessage}, "\n";
    print $$result->{$label}{PerfData}, "\n" if (defined $$result->{$label}{PerfData});
    print "\n";
  }

  my ($checkEpochtime, $checkDate, $checkTime) = ($$result->{$label}{Epochtime}, $$result->{$label}{Date}, $$result->{$label}{Time});

  # yyyy[-/]mm[-/]dd[Z|[+-]hh:mm]
  $checkDate = reverse ( $checkDate ) if ($reverse);
  ($checkDate, my $offsetDate) = split (/(Z|[+-]\d+:\d+)/, $checkDate, 2);

  if ($reverse) {
    $checkDate = reverse ( $checkDate );
    $offsetDate = reverse ( $offsetDate ) if ( defined $offsetDate );
  }

  # yyyy[-/]mm[-/]dd
  my ($checkYear, $checkMonth, $checkDay) = split (/[\/-]/, $checkDate);
  print "$checkDate, $checkYear, $checkMonth, $checkDay\n" if ( $debug );

  # hh:mm:ss[Z|[+-]hh:mm]
  ($checkTime, my $offsetTime) = split (/[Z+-]/, $checkTime, 2);
  my ($checkHour, $checkMin, $checkSec) = split (/:/, $checkTime);
  print "$checkTime, $checkHour, $checkMin, $checkSec\n" if ( $debug );

  my $xmlEpochtime = timelocal ( $checkSec, $checkMin, $checkHour, $checkDay, ($checkMonth-1), ($checkYear-1900) );
  print "$checkEpochtime, $xmlEpochtime ($checkDate, $checkTime), $currentTimeslot - $checkEpochtime = ". ($currentTimeslot - $checkEpochtime) ." > $resultOutOfDate\n"  if ( $objectNagios->getOptionsValue ('debug') );

  unless ( check_date ( $checkYear, $checkMonth, $checkDay) or check_time($checkHour, $checkMin, $checkSec ) ) {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Date or Time into XML from filename '$filename' are wrong: $checkDate $checkTime", result => undef }, $TYPE{APPEND} );
  } elsif ( $checkEpochtime != $xmlEpochtime ) {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Epochtime difference from Date and Time into XML from filename '$filename' are wrong: $checkEpochtime != $xmlEpochtime ($checkDate $checkTime)", result => undef }, $TYPE{APPEND} );
  } elsif ( $currentTimeslot - $checkEpochtime > $resultOutOfDate ) {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Result into XML from filename '$filename' are out of date: $checkDate $checkTime", result => undef }, $TYPE{APPEND} );
  } else {
    my ($errorDetail, $errorStack);
    $debugfileMessage .= "<TR><TD COLSPAN=\"7\">&nbsp;</TD></TR>\n";

    if ( $subResult == 0 ) {
      $debugfileMessage .= "\n<TR style=\"font: normal verdana,arial,helvetica; background:#c9c9c9;\"><TD colspan=\"7\" ALIGN=\"CENTER\" CLASS=\"status". $STATE{$$result->{$label}{Status}}. "\"><B>". $STATE{$$result->{$label}{Status}}. "</B></TD></TR>";
      $debugfileMessage .= "<TR><TD COLSPAN=\"7\">&nbsp;</TD></TR>\n";
      $debugfileMessage .= "\n<TR style=\"font: normal bold verdana,arial,helvetica; background:#0eeeee;\"><TD colspan=\"7\">Result: " .$$result->{$label}{Service}. "</TD></TR>";

      if ( $firstResults ) {
        $objectNagios->pluginValues ( { stateError => $STATE{$$result->{$label}{Status}}, alert => $$result->{$label}{StatusMessage}, result => $$result->{$label}{content} }, $TYPE{APPEND} );
      } else {
        $objectNagios->pluginValues ( { alert => $$result->{$label}{StatusMessage}, result => $$result->{$label}{content} }, $TYPE{APPEND} );
      }

      $errorDetail = $$result->{ErrorDetail} if ( $$result->{ErrorDetail} );
	    $errorStack  = $$result->{ErrorStack} if ( $$result->{ErrorStack} );
    } else {
      $debugfileMessage .= "\n<TR style=\"font: normal bold verdana,arial,helvetica; background:#0eeeee;\"><TD colspan=\"7\">Sub Result: " .$$result->{$label}{Service}. "</TD></TR>";
      $objectNagios->pluginValues( { alert => $$result->{$label}{Service} ." " . $STATE{$$result->{$label}{Status}} }, $TYPE{APPEND} );
      $errorDetail = $$result->{SubErrorDetail} if ( $$result->{SubErrorDetail} );
	    $errorStack  = $$result->{SubErrorStack} if ( $$result->{SubErrorStack} );
    }

    $debugfileMessage .= "<TR style=\"font: normal bold 68% verdana,arial,helvetica; text-align:left; background:#a6a6a6;\"><TH>Host</TH><TH>Service</TH><TH>Environment</TH><TH>Date</TH><TH>Time</TH><TH>StatusMessage</TH><TH>Status</TH></TR>\n";
    $debugfileMessage .= "<TR style=\"font: normal 68% verdana,arial,helvetica; background:#e1e1ef;\"><TD>" .$$result->{$label}{Host}. "</TD><TD>" .$$result->{$label}{Service}. "</TD><TD>" .$$result->{$label}{Environment} ."</TD><TD>" .$$result->{$label}{Date} ."</TD><TD>" .$$result->{$label}{Time} ."</TD><TD>" .$$result->{$label}{StatusMessage}. "</TD><TD ALIGN=\"center\" ALIGN=\"CENTER\" CLASS=\"status" .$STATE{$$result->{$label}{Status}}. "\"><B>" .$STATE{$$result->{$label}{Status}}."</B></TD></TR>\n";
    $debugfileMessage .= "<TR style=\"font: normal 68% verdana,arial,helvetica; background:#eeeee0;\"><TD valign=\"top\">Error Detail</TD><TD colspan=\"6\"><PRE>$errorDetail</PRE></TD></TR>\n" if ( $errorDetail );
    $debugfileMessage .= "<TR style=\"font: normal 68% verdana,arial,helvetica; background:#e1e1ef;\"><TD valign=\"top\">Error Stack</TD><TD colspan=\"6\"><PRE>$errorStack</PRE></TD></TR>\n" if ( $errorStack );
    $debugfileMessage .= "<TR><TD COLSPAN=\"7\">&nbsp;</TD></TR>\n" if ( $subResult == 0 );

    $objectNagios->appendPerformanceData( "'" . $$result->{$label}{Service} ."'=" . $$result->{$label}{Status} . ';1;2;0;2' );
    $objectNagios->appendPerformanceData( $$result->{$label}{PerfData} ) if ( $$result->{$label}{PerfData} );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Nagios

check_xml-monitoring-1.2.pl

Check Nagios by XML Monitoring

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
