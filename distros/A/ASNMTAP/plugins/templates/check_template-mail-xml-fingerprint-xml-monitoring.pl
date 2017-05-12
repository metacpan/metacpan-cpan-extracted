#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-mail-xml-fingerprint-xml-monitoring.pl
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
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS %STATE);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use constant HEADER  => '<?xml version="1.0" encoding="UTF-8"?>';
use constant FOOTER  => '</MonitoringXML>';

my $schema = '1.0';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_template-mail-xml-fingerprint-xml-monitoring.pl',
  _programDescription => "XML fingerprint Mail XML monitoring plugin template for testing the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programUsagePrefix => '-H|--hostname <hostname> -s|--service <service> [--validation <validation>]',
  _programHelpPrefix  => "-H, --hostname=<Nagios Hostname>
-s, --service=<Nagios service name>
--validation=F|T
   F(alse)       : dtd validation off (default)
   T(true)       : dtd validation on",
  _programGetOptions  => ['hostname|H=s', 'service|s=s', 'validation:s', 'username|u|loginname=s', 'password|p|passwd=s', 'interval|i=i', 'environment|e=s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 10,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $hostname = $objectPlugins->getOptionsArgv ('hostname') ? $objectPlugins->getOptionsArgv ('hostname') : undef;
$objectPlugins->printUsage ('Missing command line argument hostname') unless (defined $hostname);

my $service  = $objectPlugins->getOptionsArgv ('service') ? $objectPlugins->getOptionsArgv ('service') : undef;
$objectPlugins->printUsage ('Missing command line argument service') unless ( defined $service);

my $validateDTD = $objectPlugins->getOptionsArgv ('validation') ? $objectPlugins->getOptionsArgv ('validation') : 'F';

if (defined $validateDTD) {
  $objectPlugins->printUsage ('Invalid validation option: '. $validateDTD) unless ($validateDTD =~ /^[FT]$/);
  $validateDTD = ($validateDTD eq 'T') ? 1 : 0;
}

my $username = $objectPlugins->getOptionsArgv ('username');
my $password = $objectPlugins->getOptionsArgv ('password');

my $resultOutOfDate = $objectPlugins->getOptionsArgv ('interval');
my $environment     = $objectPlugins->getOptionsArgv ('environment');
my $environmentText = $objectPlugins->getOptionsValue ('environment');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Mail v3.002.003;

my $body = '
<?xml version="1.0" encoding="UTF-8"?>

<MonitoringXML>
	<Monitoring>
		<Schema Value="1.0"/>
		<Results>
		    <Details Host="Host Name ..." Service="Service Name ..." Environment="LOCAL" Date="2005/11/04" Time="17:27:30" Epochtime="1131121650" Status="2" StatusMessage="StatusMessage ..."/>
			<ErrorDetail><![CDATA[ErrorDetail .1.]]></ErrorDetail>
			<ErrorStack><![CDATA[ErrorStack .1.]]></ErrorStack>
		</Results>
	</Monitoring>
</MonitoringXML>
';

my $objectMAIL = ASNMTAP::Asnmtap::Plugins::Mail->new (
  _asnmtapInherited => \$objectPlugins,
  _SMTP             => { smtp => [ qw(smtp.citap.be) ], mime => 0 },
  _POP3             => { pop3 => 'pop3.citap.be', username => $username, password => $password },
  _mailType         => 1,
  _text             => { SUBJECT => 'uKey=MAIL_'. $environment .'_0005' },
  _mail             => {
                         from   => 'alex.peeters@citap.com',
                         to     => 'asnmtap@citap.com',
                         status => $APPLICATION .' Status UP',
                         body   => $body
                       }
  );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($returnCode, $numberOfMatches, $debugfileMessage, @xml);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$debugfileMessage  = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n<HTML><HEAD><TITLE>Mail XML monitoring plugin template \@ $APPLICATION</TITLE><style type=\"text/css\">\n.statusOdd { font-family: arial,serif; font-size: 10pt; background-color: #DBDBDB; }\n.statusEven { font-family: arial,serif; font-size: 10pt; background-color: #C4C2C2; }\ntd.statusOK { font-family: arial,serif; font-size: 10pt; background-color: #33FF00; }\ntd.statusWARNING { font-family: arial,serif; font-size: 10pt; background-color: #FFFF00; }\ntd.statusCRITICAL { font-family: arial,serif; font-size: 10pt; background-color: #F83838; }\ntd.statusUNKNOWN { font-family: arial,serif; font-size: 10pt; background-color: #FFFFFF; }\n</style>\n</HEAD><BODY><HR><H1 style=\"margin: 0px 0px 5px; font: 125% verdana,arial,helvetica\">Mail XML monitoring plugin template @ $APPLICATION</H1><HR>\n";
$debugfileMessage .= "<TABLE WIDTH=\"100%\"><TR style=\"font: normal 68% bold verdana,arial,helvetica; text-align:left; background:#a6caf0;\"><TH>Server</TH><TH>Name</TH><TH>First Occurence Date</TH><TH>First Occurence Time</TH><TH>Status</TH><TH>Status Message</TH><TH>Errors</TH></TR>\n";
$debugfileMessage .= "<H3 style=\"margin-bottom: 0.5em; font: bold 90% verdana,arial,helvetica\">$environmentText</H3>";

($returnCode, $numberOfMatches) = $objectMAIL->receiving_fingerprint_mails( custom => \&actionOnMailBody, customArguments => \{ xml => \@xml, header => HEADER, footer => FOOTER, validateDTD => $validateDTD, filenameDTD => "Monitoring-$schema.dtd" }, receivedState => 1, outOfDate => $resultOutOfDate, perfdataLabel => 'email(s) received' );

if ( defined $numberOfMatches and $numberOfMatches ) {
  my $debug = $objectPlugins->getOptionsValue ('debug');
  my %hosts = ();
  my $fixedAlert = "+";

  foreach my $xml (@xml) {
    $debugfileMessage .= "<TR style=\"background:#0eeeee; font: normal 68% bold verdana,arial,helvetica; color:purple;\"><TD>$xml->{Monitoring}{Results}{Details}{Host}</TD><TD>$xml->{Monitoring}{Results}{Details}{Service}</TD><TD>$xml->{Monitoring}{Results}{Details}{Date}</TD><TD>$xml->{Monitoring}{Results}{Details}{Time}</TD><TD>$xml->{Monitoring}{Results}{Details}{Status}</TD><TD>$xml->{Monitoring}{Results}{Details}{StatusMessage}</TD><TD>$xml->{Monitoring}{Errors}</TD></TR>\n";
    $debugfileMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD valign=\"top\">Error Stack</TD><TD colspan=\"7\"><PRE>";

    my @ErrorDetails = split (/\|/, $xml->{Monitoring}{Results}{ErrorDetail});

    foreach ( @ErrorDetails ) {
      my ($key, $value) = split (/=>/ , $_);
      $debugfileMessage .= "<b>$key:</b> $value,  ";
    }

    if ( @ErrorDetails ) { chop($debugfileMessage); chop($debugfileMessage); chop($debugfileMessage); }

    $debugfileMessage .= "</PRE></TD></TR>\n";
    $debugfileMessage .= "<TR style=\"background:#eeeee0; font: normal 68% bold verdana,arial,helvetica; color:red;\"><TD valign=\"top\">Error Detail</TD><TD colspan=\"7\"><PRE>$xml->{Monitoring}{Results}{ErrorStack}</PRE></TD></TR>\n";

	unless ( defined $hosts { $xml->{Monitoring}{Results}{Details}{Host} } ) {
      $hosts { $xml->{Monitoring}{Results}{Details}{Host} } = 1;
      $fixedAlert .= $xml->{Monitoring}{Results}{Details}{Host} .'+';
    }
  }

  $objectPlugins->pluginValues ( { alert => $fixedAlert }, $TYPE{COMMA_APPEND} ) if ($fixedAlert ne "+");
}

$debugfileMessage .= "\n</TABLE><P style=\"font: normal 68% verdana,arial,helvetica;\" ALIGN=\"left\">Generated on: " .scalar(localtime()). "</P>\n</BODY>\n</HTML>";
$objectPlugins->write_debugfile ( \$debugfileMessage, 0 );

# Sending Fingerprint Mail  - - - - - - - - - - - - - - - - - - - - - - -

$returnCode = $objectMAIL->sending_fingerprint_mail( perfdataLabel => 'email send' );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Function needed by receiving_fingerprint_mail ! - - - - - - - - - - - -

sub actionOnMailBody {
  my ($self, $asnmtapInherited, $pop3, $msgnum, $arguments) = @_;

  my $debug = $$asnmtapInherited->getOptionsValue ('debug');

  no warnings 'deprecated';

  use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);
  my ($returnCode, $xml) = extract_XML ( asnmtapInherited => $asnmtapInherited, resultXML => $self->{defaultArguments}->{result}, headerXML => ${$$arguments}{header}, footerXML => ${$$arguments}{footer}, validateDTD => ${$$arguments}{validateDTD}, filenameDTD => ${$$arguments}{filenameDTD} );

  unless ( $returnCode ) {
    my $tXml = ${$$arguments}{xml};
    my $currentTimeslot = timelocal (0, (localtime)[1,2,3,4,5]);
    my $environment = $$asnmtapInherited->getOptionsArgv('environment');
    my %environment = ( P => 'PROD', S => 'SIM', A => 'ACC', T => 'TEST', D => 'DEV', L => 'LOCAL' );

    if ($xml->{Monitoring}{Schema}{Value} eq $schema and $xml->{Monitoring}{Results}{Details}{Host} eq $hostname and $xml->{Monitoring}{Results}{Details}{Service} eq $service and $xml->{Monitoring}{Results}{Details}{Environment} =~ /^$environment{$environment}$/i) {
      $objectPlugins->pluginValues ( { stateError => $STATE{$xml->{Monitoring}{Results}{Details}{Status}}, alert => $xml->{Monitoring}{Results}{Details}{StatusMessage}, result => $xml->{Monitoring}{Results}{Details}{content} }, $TYPE{APPEND} );
      $objectPlugins->appendPerformanceData( $xml->{Monitoring}{Results}{Details}{PerfData} ) if ( $xml->{Monitoring}{Results}{Details}{PerfData} );

      my $push = 0;

      foreach my $tmpXML (@{$tXml}) {
        $push = ($tmpXML->{Monitoring}{Results}{Details}{Host} eq $xml->{Monitoring}{Results}{Details}{Host}) &&
                ($tmpXML->{Monitoring}{Results}{Details}{Status} eq $xml->{Monitoring}{Results}{Details}{Status}) &&
                ($tmpXML->{Monitoring}{Results}{Details}{StatusMessage} eq $xml->{Monitoring}{Results}{Details}{StatusMessage}) &&
                ($tmpXML->{Monitoring}{Results}{Details}{Environment} eq $xml->{Monitoring}{Results}{Details}{Environment}) &&
                ($tmpXML->{Monitoring}{Results}{Details}{Service} eq $xml->{Monitoring}{Results}{Details}{Service}) &&
                ($tmpXML->{Monitoring}{Results}{ErrorDetail} eq $xml->{Monitoring}{Results}{ErrorDetail}) &&
                ($tmpXML->{Monitoring}{Results}{ErrorStack} eq $xml->{Monitoring}{Results}{ErrorStack});

        if ($push) {
          $tmpXML->{Monitoring}{Errors}++;
          last; 
        }
      }

      unless ( $push ) {
        $xml->{Monitoring}->{Errors} = 1;
        push (@{$tXml}, $xml);
      }

      $xml->{Monitoring}{Results}{ErrorDetail} = '' if ( $debug != 2 );
      $pop3->Delete( $msgnum ) unless ( $debug or $$asnmtapInherited->getOptionsValue ('onDemand') );
      $self->{defaultArguments}->{numberOfMatches}++;
    } else {
      my $tError = 'Content Error:';
      $tError .= ' - Schema: '. $xml->{Monitoring}{Schema}{Value} ." ne $schema" if ($xml->{Monitoring}{Schema}{Value} ne $schema);
      $tError .= ' - Host: '. $xml->{Monitoring}{Results}{Details}{Host} ." ne $hostname" if ($xml->{Monitoring}{Results}{Details}{Host} ne $hostname);
      $tError .= ' - Service: '. $xml->{Monitoring}{Results}{Details}{Service} ." ne $service" if ($xml->{Monitoring}{Results}{Details}{Service} ne $service);
      $tError .= ' - Environment: ' .$xml->{Monitoring}{Results}{Details}{Environment} ." ne ". $environment{$environment} if ($xml->{Monitoring}{Results}{Details}{Environment} !~ /^$environment{$environment}$/i);
      $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $tError, result => undef }, $TYPE{APPEND} );
    }
  } else {
    $pop3->Delete( $msgnum ) unless ( $debug >= 4 and $$asnmtapInherited->getOptionsValue ('onDemand') );
  }

  return ( $returnCode );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-mail-xml-fingerprint-xml-monitoring.pl

XML fingerprint Mail XML monitoring plugin template for testing the 'Application Monitoring'

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
  
