#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_xml.pl
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

my $schema = "1.0";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins::Nagios->new (
  _programName        => 'check_xml.pl',
  _programDescription => 'Check Nagios by XML',
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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);

use constant HEADER => '<?xml version="1.0" encoding="UTF-8"?>';
use constant FOOTER => '</ServiceReports>';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ( defined $plugin ) {
  if (-s $plugin ) {
    $objectNagios->exit (7) if ( $objectNagios->call_system ( $plugin .' '. $parameters, 1 ) );
  } else {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "The Plugin '$plugin' doesn't exist" }, $TYPE{APPEND} );
    $objectNagios->exit (7);
  }
}

my ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectNagios, filenameXML => $filename, headerXML => HEADER, footerXML => FOOTER, validateDTD => $validateDTD, filenameDTD => "dtd/nagios-$schema.dtd" );
$objectNagios->exit (7) if ( $returnCode );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $currentTimeslot = timelocal (0, (localtime)[1,2,3,4,5]);

if ($xml->{Schema}{Value} eq $schema and $xml->{ServiceReport}{Host} eq $hostname and $xml->{ServiceReport}{Service} eq $service and $xml->{ServiceReport}{Environment} =~ /^$environment/i) {
  my ($checkEpochtime, $checkDate, $checkTime) = ($xml->{ServiceReport}{Epochtime}, $xml->{ServiceReport}{Date}, $xml->{ServiceReport}{Time});
  my ($checkYear, $checkMonth, $checkDay) = split (/[\/-]/, $checkDate);
  my ($checkHour, $checkMin, $checkSec) = split (/:/, $checkTime);
  my $xmlEpochtime = timelocal ( $checkSec, $checkMin, $checkHour, $checkDay, ($checkMonth-1), ($checkYear-1900) );
  print "$checkEpochtime, $xmlEpochtime ($checkDate, $checkTime), $currentTimeslot - $checkEpochtime = ". ($currentTimeslot - $checkEpochtime) ." > $resultOutOfDate\n" if ( $objectNagios->getOptionsValue ('debug') );

  unless ( check_date ( $checkYear, $checkMonth, $checkDay) or check_time($checkHour, $checkMin, $checkSec ) ) {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Date or Time into XML file '$filename' are wrong: $checkDate $checkTime", result => undef }, $TYPE{APPEND} );
  } elsif ( $checkEpochtime != $xmlEpochtime ) {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Epochtime difference from Date and Time into XML file '$filename' are wrong: $checkEpochtime != $xmlEpochtime ($checkDate $checkTime)", result => undef }, $TYPE{APPEND} );
  } elsif ( $currentTimeslot - $checkEpochtime > $resultOutOfDate ) {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Result into XML file '$filename' are out of date: $checkDate $checkTime", result => undef }, $TYPE{APPEND} );
  } else {
    $objectNagios->pluginValues ( { stateValue => $ERRORS{$STATE{$xml->{ServiceReport}{Status}}}, alert => $xml->{ServiceReport}{StatusMessage}, result => $xml->{ServiceReport}{content} }, $TYPE{APPEND} );
    $objectNagios->appendPerformanceData( $xml->{ServiceReport}{PerfData} ) if ( $xml->{ServiceReport}{PerfData} );
  }
} else {
  my $tError = 'Content Error:';
  $tError .= ' - Schema: '. $xml->{Schema}{Value} ." ne $schema" if ($xml->{Schema}{Value} ne $schema);
  $tError .= ' - Host: '. $xml->{ServiceReport}{Host}. " ne $hostname" if ($xml->{ServiceReport}{Host} ne $hostname);
  $tError .= ' - Service: '. $xml->{ServiceReport}{Service} ." ne $service" if ($xml->{ServiceReport}{Service} ne $service);
  $tError .= ' - Environment: ' .$xml->{ServiceReport}{Environment} . " ne $environment" if ($xml->{ServiceReport}{Environment} !~ /^$environment$/i);
  $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $tError, result => undef }, $TYPE{APPEND} );
}

$objectNagios->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::Nagios

check_xml.pl

Check Nagios by XML

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
