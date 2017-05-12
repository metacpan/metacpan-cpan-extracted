#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-WebTransact-XML.pl
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
  _programName        => 'check_template-WebTransact-XML.pl',
  _programDescription => "WebTransact XML plugin template for testing the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programGetOptions  => ['environment|e:s', 'proxy:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::WebTransact;
use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);

my @URLS = ();
my $objectWebTransact = ASNMTAP::Asnmtap::Plugins::WebTransact->new ( \$objectPlugins, \@URLS );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use constant HEADER1 => '<?xml version="1.0" encoding="UTF-8" ?>';
use constant FOOTER1 => '</testsuites>';

use constant HEADER2 => '<?xml version="1.0" encoding="UTF-8"?>';
use constant FOOTER2 => '</MonitoringXML>';

my ($returnCode, $result, $xml);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@URLS = (
  { Method => 'GET',  Url => 'http://asnmtap.citap.com/ServletTestRunner.xml', Qs_var => [], Qs_fixed => [], Exp => "\Q<testsuites>\E", Exp_Fault => ">>>NIHIL<<<", Msg => "ServletTestRunner.xml", Msg_Fault => "ServletTestRunner.xml" },
);

$returnCode = $objectWebTransact->check ( { } );
undef $objectWebTransact;
$objectPlugins->exit (7) if ( $returnCode );

$result = $objectPlugins->pluginValue ('result');
($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, resultXML => $result, headerXML => HEADER1, footerXML => FOOTER1 );
$objectPlugins->exit (7) if ( $returnCode );

if ( $xml->{testsuite}->{failures} + $xml->{testsuite}->{errors} ) {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => 'failures or errors' }, $TYPE{APPEND} );
  $objectPlugins->exit (7);
}

($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => 'xml/Monitoring-1.0.xml', headerXML => HEADER2, footerXML => FOOTER2, validateDTD => 1, filenameDTD => 'dtd/Monitoring-1.0.dtd' );
$objectPlugins->exit (7) if ( $returnCode );

if ( $xml->{Monitoring}->{Schema}->{Value} ne "1.0" ) {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'wrong schema' }, $TYPE{APPEND} );
  $objectPlugins->exit (7);
}

$objectPlugins->pluginValues ( { stateValue => $ERRORS{OK}, alert => 'XML validated' }, $TYPE{APPEND} );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-WebTransact-XML.pl

WebTransact XML plugin template for testing the 'Application Monitor'

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