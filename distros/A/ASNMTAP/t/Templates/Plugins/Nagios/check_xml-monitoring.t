#!/usr/bin/env perl -w -I ..
#
# ... Tests via check_xml-monitoring.pl
#
# $Id: check_xml-monitoring.t, v 1.0 2006/02/01 Alex Peeters Exp $
#

use strict;
use Test;
use ASNMTAP::Asnmtap::Plugins::NPTest;

use vars qw($tests);
BEGIN {$tests = 23; plan tests => $tests}

my $t;
my $prefix = '../plugins/nagios/templates';
my $plugin = 'check_xml-monitoring.pl';

if ( -x "$prefix/$plugin" ) {
  $t += checkCmd( "$prefix/$plugin -V", 3, "/$plugin/");
  $t += checkCmd( "$prefix/$plugin -h", 3);
  $t += checkCmd( "$prefix/$plugin", 3, '/Missing command line argument environment/');
  $t += checkCmd( "$prefix/$plugin -e P", 3, '/Missing command line argument filename/');
  $t += checkCmd( "$prefix/$plugin -e P -F $prefix/xml/doNotExist", 3, '/Missing command line argument interval/');
  $t += checkCmd( "$prefix/$plugin -e P -F $prefix/xml/doNotExist -i 1", 3, '/Missing command line argument hostname/');
  $t += checkCmd( "$prefix/$plugin -e P -F $prefix/xml/doNotExist -i 1 -H hostname", 3, '/Missing command line argument service/');
  $t += checkCmd( "$prefix/$plugin -e P -F $prefix/xml/doNotExist -i 1 -H hostname -s service", 3, '/UNKNOWN - Check Nagios by XML: The XML file \'[//\w]+\' doesn\'t exist|/');
  $t += checkCmd( "$prefix/$plugin -e P -F $prefix/xml/Monitoring-1.0.xml -i 1 -H hostname -s service", 3, '/ERROR: Content Error: - Host: Host Name ... ne hostname - Service: Service Name ... ne service - Environment: LOCAL ne P/');
  $t += checkCmd( "$prefix/$plugin -e P -F $prefix/xml/Monitoring-1.0.xml -i 10 -H 'Host Name ...' -s service", 3, '/ERROR: Content Error: - Service: Service Name ... ne service - Environment: LOCAL ne P/');
  $t += checkCmd( "$prefix/$plugin -e P -F $prefix/xml/Monitoring-1.0.xml -i 10 -H 'Host Name ...' -s 'Service Name ...'", 3, '/ERROR: Content Error: - Environment: LOCAL ne P/');
  $t += checkCmd( "$prefix/$plugin -e L -F $prefix/xml/Monitoring-1.0.xml -i 10 -H 'Host Name ...' -s 'Service Name ...'", 3, '/Result into XML file \'[//\w\-\.]+\' are out of date:/');
} else {
  $t += skipMissingCmd( "$prefix/$plugin", $tests );
}

exit(0) if defined($Test::Harness::VERSION);
exit($tests - $t);
