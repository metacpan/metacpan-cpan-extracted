use Test::More tests => 23;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap::Plugins::XML' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::XML' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::XML', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::XML', qw(&extract_XML) ) };

TODO: {
  use ASNMTAP::Asnmtap::Plugins v3.002.003;
  use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

  my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
    _programName        => 'XML.t',
    _programDescription => 'Testing ASNMTAP::Asnmtap::Plugins::XML',
    _programVersion     => '3.002.003',
    _timeout            => 30,
    _debug              => 0);

  isa_ok( $objectPlugins, 'ASNMTAP::Asnmtap::Plugins' );
  can_ok( $objectPlugins, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp) );
  can_ok( $objectPlugins, qw(appendPerformanceData browseragent SSLversion clientCertificate pluginValue pluginValues proxy timeout setEndTime_and_getResponsTime write_debugfile call_system exit) );

  use constant HEADER => '<?xml version="1.0" encoding="UTF-8"?>';
  use constant FOOTER => '</MonitoringXML>';

  my $schema = "1.0";

  my $resultXML = <<EOT;
<?xml version="1.0" encoding="UTF-8"?>
<MonitoringXML>
	<Monitoring>
		<Schema Value="1.0"/>
		<Results>
		    <Details Host="Host Name ..." Service="Service Name ..." Environment="LOCAL" Date="2005/11/04" Time="17:27:30" Epochtime="1131121650" Status="2" StatusMessage="StatusMessage ..." PerfData="'PerfData Label 1'=99ms;0;;; 'PerfData Label n'=99ms;0;;;"/>
			<ErrorDetail><![CDATA[ErrorDetail .1.]]></ErrorDetail>
			<ErrorStack><![CDATA[ErrorStack .1.]]></ErrorStack>
  	        <Extension>
		        <Element eName="one integer" eDescription="description a" eType="INTEGER" eValue="1" ePerfData="'PerfData Label 1'=99ms;0;;; 'PerfData Label n'=99ms;0;;;"/>
		        <Element eName="one string" eDescription="description b" eType="STRING" eValue="string, no Format" ePerfData="'PerfData Label 1'=99ms;0;;; 'PerfData Label n'=99ms;0;;;"/>
		        <Element eName="one string" eDescription="description c" eType="STRING" eFormat="" eValue="string, no Perfdata"/>
		        <Element eName="one string" eDescription="description d" eType="STRING" eValue="string, no Format, no Perfdata"><![CDATA[ErrorDetail .1.]]></Element>
	        </Extension>
		</Results>
	</Monitoring>
</MonitoringXML>
EOT

  my ($returnCode, $xml, $errorStatus);

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, custom => \&actionOnExtractedXML, resultXML => $resultXML, headerXML => HEADER, footerXML => FOOTER );
  ok ($returnCode == 0, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): custom');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, resultXML => $resultXML, headerXML => HEADER, footerXML => FOOTER, validateDTD => 0 );
  ok ($returnCode == 0, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): resultXML with validateDTD = 0');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, resultXML => $resultXML, headerXML => HEADER, footerXML => FOOTER, validateDTD => 1, filenameDTD => "../plugins/templates/dtd/Monitoring-$schema.dtd" );
  ok ($returnCode == 0, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): resultXML with validateDTD = 1');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => "../plugins/templates/xml/Monitoring-$schema.xml", headerXML => HEADER, footerXML => FOOTER, validateDTD => 0 );
  ok ($returnCode == 0, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): filenameXML with validateDTD = 0');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => "../plugins/templates/xml/Monitoring-$schema.xml", headerXML => HEADER, footerXML => FOOTER, validateDTD => 1, filenameDTD => "../plugins/templates/dtd/Monitoring-$schema.dtd" );
  ok ($returnCode == 0, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): filenameXML with validateDTD = 1');
  
  $errorStatus = ($returnCode != 0) ? $returnCode : ($xml->{Monitoring}{Schema}{Value} eq $schema and $xml->{Monitoring}{Results}{Details}{Host} eq 'Host Name ...' and $xml->{Monitoring}{Results}{Details}{Service} eq 'Service Name ...' and $xml->{Monitoring}{Results}{Details}{Environment} =~ /^L/i);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML: XML Monitoring validation OK');

  $errorStatus = ! ($xml->{Monitoring}{Schema}{Value} eq $schema and $xml->{Monitoring}{Results}{Details}{Host} eq '... Host Name ...' and $xml->{Monitoring}{Results}{Details}{Service} eq '... Service Name ...' and $xml->{Monitoring}{Results}{Details}{Environment} =~ /^L/i);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML: XML Monitoring validation NOK');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins );
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing resultXML and\/or filenameXML\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): Missing resultXML and/or filenameXML');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => "xml/Monitoring-1.0-UNKNOWN.xml" );
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QThe XML file 'xml\/Monitoring-1.0-UNKNOWN.xml' doesn't exist\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): filenameXML: The XML file doesn\'t exist');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => "../plugins/templates/xml/Monitoring-$schema.xml" );
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing XML HEADER\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): headerXML: Missing XML HEADER');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => "../plugins/templates/xml/Monitoring-$schema.xml", headerXML => HEADER );
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing XML FOOTER\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): footerXML: Missing XML FOOTER');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => "../plugins/templates/xml/Monitoring-$schema.xml", headerXML => HEADER, footerXML => FOOTER, validateDTD => 2 );
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QParameter validateDTD must be 0 or 1\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): validateDTD: Parameter validateDTD must be 0 or 1');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => "../plugins/templates/xml/Monitoring-$schema.xml", headerXML => 'HEADER', footerXML => FOOTER, validateDTD => 0 );
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QWrong XML HEADER\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): headerXML: Wrong XML HEADER');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => "../plugins/templates/xml/Monitoring-$schema.xml", headerXML => HEADER, footerXML => 'FOOTER', validateDTD => 0 );
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QWrong XML FOOTER\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): footerXML: Wrong XML FOOTER');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => "../plugins/templates/xml/Monitoring-1.0.xml", headerXML => HEADER, footerXML => FOOTER, validateDTD => 1, filenameDTD => "dtd/Monitoring-1.0-UNKNOWN.dtd" );
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QThe DTD file 'dtd\/Monitoring-1.0-UNKNOWN.dtd' doesn't exist\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): filenameDTD: The DTD file doesn\'t exist');

  ($returnCode, $xml) = extract_XML ( asnmtapInherited => \$objectPlugins, filenameXML => "../plugins/templates/xml/Monitoring-1.0-doNotValidate.xml", headerXML => HEADER, footerXML => FOOTER, validateDTD => 1, filenameDTD => "../plugins/templates/dtd/Monitoring-$schema.dtd" );
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QThe XML doesn't validate\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::XML::extract_XML(): The XML doesn\'t validate');


  no warnings 'deprecated';
  $objectPlugins->{_pluginValues}->{stateValue} = $ERRORS{OK};
  $objectPlugins->{_pluginValues}->{stateError} = $STATE{$ERRORS{OK}};
  $objectPlugins->exit (0);

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub actionOnExtractedXML {
    my ($asnmtapInherited, $xml) = @_;
    return ( $ERRORS{OK} );
  }
}
