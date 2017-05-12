#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-WebTransact-XML-Cactus-parser.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_template-WebTransact-XML-Cactus-parser.pl',
  _programDescription => "WebTransact XML Cactus parser HTTP/HTTPS plugin template for testing the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programGetOptions  => ['filename|f:s', 'environment|e:s', 'proxy:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 300,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);

my $filename = $objectPlugins->getOptionsArgv ('filename') ? $objectPlugins->getOptionsArgv ('filename') : undef;

my $httpNotByFile = ( defined $filename ) ? 0 : 1;

# Modify Cactus XML testcontainer data  - - - - - - - - - - - - - - - - -

use constant HEADER       => '<?xml version="1.0" encoding="UTF-8" ?>';
use constant FOOTER       => '</testsuites>';

use constant TESTSUITE    => 'be.asnmtap.common.businessservices.service.TestAsnmtapServiceRemote';
use constant URL          => 'http://asnmtap:7205/ripservice.1.4.2.cactus/ServletTestRunner';
use constant EXP          => '.';
use constant EXP_FAULT    => '>>>NIHIL<<<';
use constant MSG          => '.';
use constant MSG_FAULT    => '.';

# Parameters for the example: ServletTestRunner.xml, modify them!!!

my $timeTestsuiteWarning  = 30;
my $timeTestsuiteCritical = 45;

# - - - - - - - - - - - - -  [TESTCASE, WARNING, CRITICAL],
my @testcase              = (['testHeavyLoad1', 10, 20],
                             ['testHeavyLoad2', 10, 20]);
						
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use constant TESTCASE => 0;
use constant WARNING  => 1;
use constant CRITICAL => 2;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($returnCode, $result, $xml);

my $debug = $objectPlugins->getOptionsValue ('debug');

if ($httpNotByFile) {
  use ASNMTAP::Asnmtap::Plugins::WebTransact;

  my @URLS = (
    { Method => 'GET',  Url => URL, Qs_var => [], Qs_fixed => [suite => TESTSUITE], Exp => EXP, Exp_Fault => EXP_FAULT, Msg => MSG, Msg_Fault => MSG_FAULT },
  );

  my $objectWebTransact = ASNMTAP::Asnmtap::Plugins::WebTransact->new ( \$objectPlugins, \@URLS );

  $returnCode = $objectWebTransact->check ( { } );
  undef $objectWebTransact;
  $objectPlugins->exit (7) if ( $returnCode );

  $result = $objectPlugins->pluginValue ('result');
  $filename = undef;
} else { # for testing, you can use the file 'ServletTestRunner.xml' instead of using HTTP/HTTPS access
  $result = undef;
}

if ( $debug >= 2 ) {
  print "\n<header>\n" . HEADER . "\n</header>\n";
  print "<in>\n$result\n</in>\n" if (defined $result);
}

if ( defined $result )  {
  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, resultXML => $result, headerXML => HEADER, footerXML => FOOTER );
} elsif ( defined $filename ) {
  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => $filename, headerXML => HEADER, footerXML => FOOTER );
} else {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => "No resultXML and filenameXML defined.", result => undef }, $TYPE{APPEND} );
}

$objectPlugins->exit (7) if ( $returnCode );

if ( $debug ) {
  print "xml->{testsuite}->{name}<->\n", $xml->{testsuite}->{name}, "\n";
  print "xml->{testsuite}->{tests}<->\n", $xml->{testsuite}->{tests}, "\n";
  print "xml->{testsuite}->{failures}<->\n", $xml->{testsuite}->{failures}, "\n";
  print "xml->{testsuite}->{errors}<->\n", $xml->{testsuite}->{errors}, "\n";
  print "xml->{testsuite}->{time}<->\n", $xml->{testsuite}->{time}, "\n";

  foreach my $testcase (@testcase) {
    my $nameTestcase = $testcase->[TESTCASE];
    print "nameTestcase<->\n  $nameTestcase\n";
				
    if (defined $xml->{testsuite}->{testcase}->{$nameTestcase}) {
      print "  ", $xml->{testsuite}->{testcase}->{$nameTestcase}->{time}, "\n";

      if (defined $xml->{testsuite}->{testcase}->{$nameTestcase}->{failure}) {
        print "  ", $xml->{testsuite}->{testcase}->{$nameTestcase}->{failure}->{message}, "\n";
        print "  ", $xml->{testsuite}->{testcase}->{$nameTestcase}->{failure}->{content}, "\n";
        print "  ", $xml->{testsuite}->{testcase}->{$nameTestcase}->{failure}->{type}, "\n";
      }
    }
  }
}

if ( TESTSUITE ne $xml->{testsuite}->{name} ) {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Wrong testsuite: '. $xml->{testsuite}->{name}, result => undef }, $TYPE{APPEND} );
  $objectPlugins->exit (7);
}

if ( (my $numberTests = @testcase) ne $xml->{testsuite}->{tests} ) {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Wrong # of tests, Known: $numberTests, Returned: '. $xml->{testsuite}->{tests}, result => undef }, $TYPE{APPEND} );
  $objectPlugins->exit (7);
}

if ($xml->{testsuite}->{failures} + $xml->{testsuite}->{errors}) {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "Tests $xml->{testsuite}->{tests} - Failures $xml->{testsuite}->{failures} - Errors $xml->{testsuite}->{errors}", result => undef }, $TYPE{APPEND} );
  $returnCode = $ERRORS{CRITICAL};
}

my ($alertHeader, $alertMessage, $debugfileMessage);
$debugfileMessage  = "\n<HTML><HEAD><TITLE>Cactus XML::Parser \@ $APPLICATION: Unit Test Results</TITLE></HEAD><BODY><HR><H1 style=\"margin: 0px 0px 5px; font: 125% verdana,arial,helvetica\">WebTransact XML Cactus parser @ $APPLICATION: Unit Test Results</H1>\n";
$debugfileMessage .= "<HR><H2 style=\"margin-top: 1em; margin-bottom: 0.5em; font: bold 100% verdana,arial,helvetica\">Summary</H2>";
$debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR style=\"font: normal 68% bold verdana,arial,helvetica; text-align:left; background:#a6caf0;\"><TH>Tests</TH><TH>Failures</TH><TH>Errors</TH><TH>Time</TH><TR>";
$debugfileMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:purple;\"><TD>$xml->{testsuite}->{tests}</TD><TD>$xml->{testsuite}->{failures}</TD><TD>$xml->{testsuite}->{errors}</TD><TD>$xml->{testsuite}->{time}";

if ($xml->{testsuite}->{time} >= $timeTestsuiteCritical) {
  $returnCode  = $ERRORS{CRITICAL};
  $alertHeader = "Time $xml->{testsuite}->{time} > $timeTestsuiteCritical";
  $debugfileMessage .= " > $timeTestsuiteCritical";
} elsif ($xml->{testsuite}->{time} >= $timeTestsuiteWarning) {
  $returnCode  = $ERRORS{WARNING};
  $alertHeader = "Time $xml->{testsuite}->{time} > $timeTestsuiteWarning";
  $debugfileMessage .= " > $timeTestsuiteWarning";
} else {
  $alertHeader = "Time $xml->{testsuite}->{time}";
}

$debugfileMessage .= "</TD></TR></TABLE>\n";
$debugfileMessage .= "<table width=\"100%\" border=\"0\"><tr><td style=\"font: verdana,arial,helvetica; text-align: justify;\">Note: <i>failures</i> are anticipated and checked for with assertions while <i>errors</i> are unanticipated.</td></tr></table>\n";
$debugfileMessage .= "<H3 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">Testcase $xml->{testsuite}->{name}</H3><TABLE WIDTH=\"100%\"><TR style=\"font: normal 68% bold verdana,arial,helvetica; text-align:left; background:#a6caf0;\"><TH>Name</TH><TH>Status</TH><TH>Type</TH><TH>Time(s)</TH></TR>\n";
					
foreach my $testcase (@testcase) {
  my $nameTestcase = $testcase->[TESTCASE];

  if (defined $xml->{testsuite}->{testcase}->{$nameTestcase}) {
    if (defined $xml->{testsuite}->{testcase}->{$nameTestcase}->{failure}) {
      $alertMessage .= "+$nameTestcase:F";
      $debugfileMessage .= "<TR valign=\"top\" style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:purple;\"><TD>$nameTestcase</TD><TD>Failure</TD><TD>$xml->{testsuite}->{testcase}->{$nameTestcase}->{failure}->{message}<BR>&nbsp;<BR>$xml->{testsuite}->{testcase}->{$nameTestcase}->{failure}->{content}</TD><TD>$xml->{testsuite}->{testcase}->{$nameTestcase}->{time}</TD></TR>";
    } elsif (defined $xml->{testsuite}->{testcase}->{$nameTestcase}->{error}) {
      $alertMessage .= "+$nameTestcase:E";
      $debugfileMessage .= "<TR valign=\"top\" style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD>$nameTestcase</TD><TD>Error</TD><TD>$xml->{testsuite}->{testcase}->{$nameTestcase}->{error}->{message}<BR>&nbsp;<BR>$xml->{testsuite}->{testcase}->{$nameTestcase}->{error}->{content}</TD><TD>$xml->{testsuite}->{testcase}->{$nameTestcase}->{time}</TD></TR>";
    } elsif ($xml->{testsuite}->{testcase}->{$nameTestcase}->{time} >= $testcase->[CRITICAL]) {
      $alertHeader  .= "+$nameTestcase:C $xml->{testsuite}->{testcase}->{$nameTestcase}->{time}";
      $alertMessage .= "+$nameTestcase:C";
      $debugfileMessage .= "<TR valign=\"top\" style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD>$nameTestcase</TD><TD>Critical</TD><TD>$xml->{testsuite}->{testcase}->{$nameTestcase}->{time} >= $testcase->[CRITICAL]</TD><TD>$xml->{testsuite}->{testcase}->{$nameTestcase}->{time}</TD></TR>";
    } elsif ($xml->{testsuite}->{testcase}->{$nameTestcase}->{time} >= $testcase->[WARNING]) {
      $alertHeader  .= "+$nameTestcase:W $xml->{testsuite}->{testcase}->{$nameTestcase}->{time}";
      $alertMessage .= "+$nameTestcase:W";
      $debugfileMessage .= "<TR valign=\"top\" style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:purple;\"><TD>$nameTestcase</TD><TD>Warning</TD><TD>$xml->{testsuite}->{testcase}->{$nameTestcase}->{time} >= $testcase->[WARNING]</TD><TD>$xml->{testsuite}->{testcase}->{$nameTestcase}->{time}</TD></TR>";
    }
  }
}

$debugfileMessage .= "\n</TABLE><P style=\"font: normal 68% verdana,arial,helvetica;\" ALIGN=\"left\">Generated on: ". scalar(localtime()) ."</P>\n</BODY>\n</HTML>";

if (defined $alertMessage) {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => $alertHeader .', '. $objectPlugins->pluginValue ('alert') .' '. $alertMessage .'+', result => undef }, $TYPE{REPLACE} );
  $objectPlugins->write_debugfile ( \$debugfileMessage, 0 );
} elsif ($returnCode == $ERRORS{DEPENDENT}) {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{OK}, alert => $xml->{testsuite}->{name}, result => undef }, $TYPE{APPEND} );
} else {
  my $alert = $objectPlugins->pluginValue ('alert');
  $objectPlugins->pluginValues ( { stateValue => $returnCode, alert => $alertHeader . (defined $alert ? ', '. $alert : ''), result => undef }, $TYPE{REPLACE} );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-WebTransact-XML-Cactus-parser.pl

WebTransact XML Cactus parser HTTP/HTTPS plugin template for testing the 'Application Monitor'

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