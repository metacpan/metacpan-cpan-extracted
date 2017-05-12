#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-WebTransact-XML-Monitoring-1.1.pl
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

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $schema = "1.1";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_template-WebTransact-XML-Monitoring-1.1.pl',
  _programDescription => "WebTransact XML Monitoring plugin template for testing the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programUsagePrefix => '--message=<message> [-H|--hostname <hostname> -s|--service <service>]|[--uKey <uKey>] [--validation <validation>]',
  _programHelpPrefix  => "--message=<message>
   --message=message
-H, --hostname=<Nagios Hostname>
-s, --service=<Nagios service name>
--uKey=<uKey>
--validation=F|T
   F(alse)       : dtd validation off (default)
   T(true)       : dtd validation on",
  _programGetOptions  => ['message=s', 'url|U=s', 'hostname|H:s', 'service|s:s', 'uKey:s', 'validation:s', 'interval|i=i', 'proxy:s', 'environment|e=s', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $url = $objectPlugins->getOptionsArgv ('url');

my $message = $objectPlugins->getOptionsArgv ('message');
$objectPlugins->printUsage ('Missing command line argument message') unless (defined $message);
$objectPlugins->pluginValue ( message => $message );

my ($uKey, $hostname, $service);
$uKey = $objectPlugins->getOptionsArgv ('uKey') ? $objectPlugins->getOptionsArgv ('uKey') : undef;

unless ( defined $uKey ) {
  $hostname = $objectPlugins->getOptionsArgv ('hostname') ? $objectPlugins->getOptionsArgv ('hostname') : undef;
  $objectPlugins->printUsage ('Missing command line argument uKey or hostname') unless (defined $hostname);

  $service = $objectPlugins->getOptionsArgv ('service') ? $objectPlugins->getOptionsArgv ('service') : undef;
  $objectPlugins->printUsage ('Missing command line argument service') unless ( defined $service);
}

my $validateDTD = $objectPlugins->getOptionsArgv ('validation') ? $objectPlugins->getOptionsArgv ('validation') : 'F';

if (defined $validateDTD) {
  $objectPlugins->printUsage ('Invalid validation option: '. $validateDTD) unless ($validateDTD =~ /^[FT]$/);
  $validateDTD = ($validateDTD eq 'T') ? 1 : 0;
}

my $resultOutOfDate = $objectPlugins->getOptionsArgv ('interval');

my $environment = $objectPlugins->getOptionsArgv ('environment') ? $objectPlugins->getOptionsArgv ('environment') : 'P';
my $environmentText = $objectPlugins->getOptionsValue ('environment');

my $debug = $objectPlugins->getOptionsValue ('debug');

my $reverse = 0;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::WebTransact;
use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);

use constant HEADER => '<?xml version="1.0" encoding="UTF-8"?>';
use constant FOOTER => '</MonitoringXML>';

my @URLS = ();
my $objectWebTransact = ASNMTAP::Asnmtap::Plugins::WebTransact->new ( \$objectPlugins, \@URLS );

my ($returnCode, $result, $xml, $debugfileMessage);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@URLS = (
  { Method => 'GET',  Url => $url, Qs_var => [], Qs_fixed => [], Exp => "\Q<MonitoringXML>\E", Exp_Fault => ">>>NIHIL<<<", Msg => "XML", Msg_Fault => "XML" },
);

$returnCode = $objectWebTransact->check ( { } );
undef $objectWebTransact;
$objectPlugins->exit (7) if ( $returnCode );

$result = $objectPlugins->pluginValue ('result');
($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, resultXML => $result, headerXML => HEADER, footerXML => FOOTER, validateDTD => $validateDTD, filenameDTD => "dtd/Monitoring-$schema.dtd" );
$objectPlugins->exit (3) if ( $returnCode );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $currentTimeslot = timelocal ((localtime)[0,1,2,3,4,5]);
my %environment = ( P => 'PROD', S => 'SIM', A => 'ACC', T => 'TEST', D => 'DEV', L => 'LOCAL' );

my $match = 0;

if ( defined $xml->{Monitoring}{Results}{Extension}{Element}{eName} and $xml->{Monitoring}{Results}{Extension}{Element}{eName} eq 'uKey') {
  $match = 1 if ( defined $xml->{Monitoring}{Results}{Extension}{Element}{eValue} and $xml->{Monitoring}{Results}{Extension}{Element}{eValue} eq $uKey );
} else {
  $match = 1 if ( $xml->{Monitoring}{Results}{Details}{Host} eq $hostname and $xml->{Monitoring}{Results}{Details}{Service} eq $service );
}

if ($match and $xml->{Monitoring}{Schema}{Value} eq $schema and $xml->{Monitoring}{Results}{Details}{Environment} =~ /^$environment{$environment}$/i) {
  $debugfileMessage  = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n<HTML><HEAD><TITLE>$message \@ $APPLICATION</TITLE><style type=\"text/css\">\n.statusOdd { font-family: arial,serif; font-size: 10pt; background-color: #DBDBDB; }\n.statusEven { font-family: arial,serif; font-size: 10pt; background-color: #C4C2C2; }\ntd.statusOK { font-family: arial,serif; font-size: 10pt; background-color: #33FF00; }\ntd.statusWARNING { font-family: arial,serif; font-size: 10pt; background-color: #FFFF00; }\ntd.statusCRITICAL { font-family: arial,serif; font-size: 10pt; background-color: #F83838; }\ntd.statusUNKNOWN { font-family: arial,serif; font-size: 10pt; background-color: #FFFFFF; }\n</style>\n</HEAD><BODY><HR><H1 style=\"margin: 0px 0px 5px; font: 125% verdana,arial,helvetica\">$message @ $APPLICATION</H1><HR>\n";
  $debugfileMessage .= "\n<TABLE WIDTH=\"100%\"><TR><TD>\n<H3 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">Environment: $environmentText</H3></TD></TR></TABLE>\n";
  $debugfileMessage .= "\n<TABLE WIDTH=\"100%\">";
  validateResultOrSubResult ( \$xml->{Monitoring}{Results}, 0, $reverse, $debug );

  if ( defined $xml->{Monitoring}{Results}{SubResults} ) {
    if ( ref $xml->{Monitoring}{Results}{SubResults} eq 'ARRAY' ) {
      foreach my $subResults (@{$xml->{Monitoring}{Results}{SubResults}}) {
        validateResultOrSubResult ( \$subResults, 1, $reverse, $debug );
      }
    } else {
      validateResultOrSubResult ( \$xml->{Monitoring}{Results}{SubResults}, 1, $reverse, $debug );
    }
  }

  $debugfileMessage .= "</TABLE>\n";
  $debugfileMessage .= "<P style=\"font: normal 68% verdana,arial,helvetica;\" ALIGN=\"left\">Generated on: " .scalar(localtime()). "</P>\n</BODY>\n</HTML>";
  $objectPlugins->write_debugfile ( \$debugfileMessage, 0 );
} else {
  my $tError = 'Content Error:';
  $tError .= ' - Schema: '. $xml->{Monitoring}{Schema}{Value} ." ne $schema" if ($xml->{Monitoring}{Schema}{Value} ne $schema);

  if ( $xml->{Monitoring}{Results}{Extension}{Element}{eName} eq 'uKey') {
    $tError .= ' - uKey: '. $xml->{Monitoring}{Results}{Extension}{Element}{eValue} ." ne $uKey" if ($xml->{Monitoring}{Results}{Extension}{Element}{eValue} ne $uKey);
  } else {	
    $tError .= ' - Host: '. $xml->{Monitoring}{Results}{Details}{Host} ." ne $hostname" if ($xml->{Monitoring}{Results}{Details}{Host} ne $hostname);
    $tError .= ' - Service: '. $xml->{Monitoring}{Results}{Details}{Service} ." ne $service" if ($xml->{Monitoring}{Results}{Details}{Service} ne $service);
  }

  $tError .= ' - Environment: ' .$xml->{Monitoring}{Results}{Details}{Environment} ." ne ". $environment{$environment} if ($xml->{Monitoring}{Results}{Details}{Environment} !~ /^$environment{$environment}$/i);
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $tError, result => undef }, $TYPE{APPEND} );
}

$objectPlugins->exit (3);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub validateResultOrSubResult {
  my ($result, $subResult, $reverse, $debug) = @_;

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
  print "$checkEpochtime, $xmlEpochtime ($checkDate, $checkTime), $currentTimeslot - $checkEpochtime = ". ($currentTimeslot - $checkEpochtime) ." > $resultOutOfDate\n"  if ( $objectPlugins->getOptionsValue ('debug') );

  unless ( check_date ( $checkYear, $checkMonth, $checkDay) or check_time($checkHour, $checkMin, $checkSec ) ) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Date or Time into XML from URL '$url' are wrong: $checkDate $checkTime", result => undef }, $TYPE{APPEND} );
  } elsif ( $checkEpochtime != $xmlEpochtime ) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Epochtime difference from Date and Time into XML from URL '$url' are wrong: $checkEpochtime != $xmlEpochtime ($checkDate $checkTime)", result => undef }, $TYPE{APPEND} );
  } elsif ( $currentTimeslot - $checkEpochtime > $resultOutOfDate ) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Result into XML from URL '$url' are out of date: $checkDate $checkTime", result => undef }, $TYPE{APPEND} );
  } else {
    my ($errorDetail, $errorStack);
    $debugfileMessage .= "<TR><TD COLSPAN=\"7\">&nbsp;</TD></TR>\n";

    if ( $subResult == 0 ) {
      $debugfileMessage .= "\n<TR style=\"font: normal verdana,arial,helvetica; background:#c9c9c9;\"><TD colspan=\"7\" ALIGN=\"CENTER\" CLASS=\"status". $STATE{$$result->{$label}{Status}}. "\"><B>". $STATE{$$result->{$label}{Status}}. "</B></TD></TR>";
      $debugfileMessage .= "<TR><TD COLSPAN=\"7\">&nbsp;</TD></TR>\n";
      $debugfileMessage .= "\n<TR style=\"font: normal bold verdana,arial,helvetica; background:#0eeeee;\"><TD colspan=\"7\">Result: " .$$result->{$label}{Service}. "</TD></TR>";
      $objectPlugins->pluginValues ( { stateError => $STATE{$$result->{$label}{Status}}, alert => $$result->{$label}{StatusMessage}, result => $$result->{$label}{content} }, $TYPE{APPEND} );
      $errorDetail = $$result->{ErrorDetail} if ( $$result->{ErrorDetail} );
	  $errorStack  = $$result->{ErrorStack} if ( $$result->{ErrorStack} );
    } else {
      $debugfileMessage .= "\n<TR style=\"font: normal bold verdana,arial,helvetica; background:#0eeeee;\"><TD colspan=\"7\">Sub Result: " .$$result->{$label}{Service}. "</TD></TR>";
      $objectPlugins->pluginValues( { alert => $$result->{$label}{Service} ." " . $STATE{$$result->{$label}{Status}} }, $TYPE{APPEND} );
      $errorDetail = $$result->{SubErrorDetail} if ( $$result->{SubErrorDetail} );
	  $errorStack  = $$result->{SubErrorStack} if ( $$result->{SubErrorStack} );
    }

    $debugfileMessage .= "<TR style=\"font: normal bold 68% verdana,arial,helvetica; text-align:left; background:#a6a6a6;\"><TH>Host</TH><TH>Service</TH><TH>Environment</TH><TH>Date</TH><TH>Time</TH><TH>StatusMessage</TH><TH>Status</TH></TR>\n";
    $debugfileMessage .= "<TR style=\"font: normal 68% verdana,arial,helvetica; background:#e1e1ef;\"><TD>" .$$result->{$label}{Host}. "</TD><TD>" .$$result->{$label}{Service}. "</TD><TD>" .$$result->{$label}{Environment} ."</TD><TD>" .$$result->{$label}{Date} ."</TD><TD>" .$$result->{$label}{Time} ."</TD><TD>" .$$result->{$label}{StatusMessage}. "</TD><TD ALIGN=\"center\" ALIGN=\"CENTER\" CLASS=\"status" .$STATE{$$result->{$label}{Status}}. "\"><B>" .$STATE{$$result->{$label}{Status}}."</B></TD></TR>\n";
    $debugfileMessage .= "<TR style=\"font: normal 68% verdana,arial,helvetica; background:#eeeee0;\"><TD valign=\"top\">Error Detail</TD><TD colspan=\"6\"><PRE>$errorDetail</PRE></TD></TR>\n" if ( $errorDetail );
    $debugfileMessage .= "<TR style=\"font: normal 68% verdana,arial,helvetica; background:#e1e1ef;\"><TD valign=\"top\">Error Stack</TD><TD colspan=\"6\"><PRE>$errorStack</PRE></TD></TR>\n" if ( $errorStack );
    $debugfileMessage .= "<TR><TD COLSPAN=\"7\">&nbsp;</TD></TR>\n" if ( $subResult == 0 );

    $objectPlugins->appendPerformanceData( "'" . $$result->{$label}{Service} ."'=" . $$result->{$label}{Status} . ';1;2;0;2' );
    $objectPlugins->appendPerformanceData( $$result->{$label}{PerfData} ) if ( $$result->{$label}{PerfData} );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-WebTransact-XML-Monitoring-1.1.pl

WebTransact XML Monitoring plugin template for testing the 'Application Monitor' for Monitoring-1.1.xml

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

