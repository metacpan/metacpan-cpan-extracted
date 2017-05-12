#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-XML.pl
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
  _programName        => 'check_template-XML.pl',
  _programDescription => "XML plugin template for testing the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programGetOptions  => ['environment|e:s', 'proxy:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::XML qw(&extract_XML);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use constant HEADER => '<?xml version="1.0" encoding="UTF-8"?>';
use constant FOOTER => '</MonitoringXML>';

my ($returnCode, $result, $xml);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$result = <<EOT;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE MonitoringXML SYSTEM "dtd/Monitoring-1.0.dtd">
<MonitoringXML>
	<Monitoring>
		<Schema Value="1.0"/>
		<Results>
		    <Details Host="Host Name ..." Service="Service Name ..." Environment="LOCAL" Date="2005/11/04" Time="17:27:30" Epochtime="1131121650" Status="0" StatusMessage="StatusMessage ..." PerfData="'PerfData Label 1'=99ms;0;;; 'PerfData Label n'=99ms;0;;;"/>
			<ErrorDetail><![CDATA[ErrorDetail .1.]]></ErrorDetail>
			<ErrorStack><![CDATA[ErrorStack .1.]]></ErrorStack>
		</Results>
	</Monitoring>
</MonitoringXML>
EOT

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, resultXML => $result, headerXML => HEADER, footerXML => FOOTER );
$objectPlugins->exit (7) if ( $returnCode );

if ( $xml->{Monitoring}->{Results}->{Details}->{Status} ) {
  $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => 'BAD LUCK' }, $TYPE{APPEND} );
  $objectPlugins->exit (7);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$returnCode = extract_XML ( asnmtapInherited => \$objectPlugins, custom => \&actionOnExtractedXML, filenameXML => 'xml/Monitoring-1.0.xml', headerXML => HEADER, footerXML => FOOTER, validateDTD => 1, filenameDTD => 'dtd/Monitoring-1.0.dtd' );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub actionOnExtractedXML {
  my ($asnmtapInherited, $xml) = @_;

  my $returnCode;

  if ( $xml->{Monitoring}->{Results}->{Details}->{Status} ) {
   $returnCode = $ERRORS{CRITICAL};
    $objectPlugins->pluginValues ( { stateValue => $returnCode, error => 'BAD LUCK' }, $TYPE{APPEND} );
  } else {
    $returnCode = $ERRORS{OK};
    $asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => 'XML validated' }, $TYPE{APPEND} );
  }

  return ($returnCode);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-XML.pl

XML plugin template for testing the 'Application Monitor'

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