use Test::More tests => 25;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap::Plugins::SOAP' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::SOAP' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::SOAP', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::SOAP', qw(&get_soap_request) ) };

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'SOAP.t ',
  _programDescription => "Testing ASNMTAP::Asnmtap::Plugins::SOAP",
  _programVersion     => '3.002.003',
  _programGetOptions  => ['proxy:s', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

isa_ok( $objectPlugins, 'ASNMTAP::Asnmtap::Plugins' );
can_ok( $objectPlugins, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp) );
can_ok( $objectPlugins, qw(appendPerformanceData browseragent SSLversion clientCertificate pluginValue pluginValues proxy timeout setEndTime_and_getResponsTime write_debugfile call_system exit) );

use SOAP::Lite;
my $proxy      = 'http://services.soaplite.com/hibye.cgi';
my $namespace  = 'http://www.soaplite.com/Demo';
my $methodName = 'hi';
my $method     = SOAP::Data->name($methodName)->attr( {xmlns => $namespace} );

my %soapService_Register_NS = (
  'http://schemas.xmlsoap.org/wsdl/mime/' => 'mime',
  'http://www.w3.org/2001/XMLSchema'      => 's'
);

my $xmlContent;
my $params;

my ($returnCode, $xml, $errorStatus);

SKIP: {
  my $ASNMTAP_PROXY = ( exists $ENV{ASNMTAP_PROXY} ) ? $ENV{ASNMTAP_PROXY} : undef;
  skip 'Missing ASNMTAP_PROXY', 8 if ( defined $ASNMTAP_PROXY and ( $ASNMTAP_PROXY eq '0.0.0.0' or $ASNMTAP_PROXY eq '' ) );

  if ( defined $ASNMTAP_PROXY ) {
    no warnings 'deprecated';
    $objectPlugins->{_getOptionsArgv}->{proxy} = $ASNMTAP_PROXY;
  }

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    xmlContent        => $xmlContent,
    params            => $params,
    cookies           => 1,
    perfdataLabel     => 'SOAP.t'
  );

  ok ($returnCode == 0, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): normal');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    custom            => \&actionOnSoapResponse,
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    xmlContent        => $xmlContent,
    params            => $params,
    cookies           => 1,
    perfdataLabel     => 'SOAP.t'
  );

  $errorStatus = ($returnCode == 0 && ! defined $objectPlugins->pluginValue ('result'));
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): with custom');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    custom            => \&actionOnSoapResponse,
    customArguments   => 1,
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    xmlContent        => $xmlContent,
    params            => $params,
    cookies           => 1,
    perfdataLabel     => 'SOAP.t'
  );

  $errorStatus = ($returnCode == 0 && $objectPlugins->pluginValue ('result') eq 'SCALAR');
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): with custom and customArguments, scalar');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    custom            => \&actionOnSoapResponse,
    customArguments   => [1, 2, 3],
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    xmlContent        => $xmlContent,
    params            => $params,
    cookies           => 1,
    perfdataLabel     => 'SOAP.t'
  );

  $errorStatus = ($returnCode == 0 && $objectPlugins->pluginValue ('result') eq 'ARRAY');
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): with custom and customArguments, array');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    custom            => \&actionOnSoapResponse,
    customArguments   => {a=>1, b=>2, c=>3},
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    xmlContent        => $xmlContent,
    params            => $params,
    cookies           => 1,
    perfdataLabel     => 'SOAP.t'
  );

  $errorStatus = ($returnCode == 0 && $objectPlugins->pluginValue ('result') eq 'HASH');
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): with custom and customArguments, hash');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    custom            => \&actionOnSoapResponse,
    customArguments   => \1,
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    xmlContent        => $xmlContent,
    params            => $params,
    cookies           => 1,
    perfdataLabel     => 'SOAP.t'
  );

  $errorStatus = ($returnCode == 0 && $objectPlugins->pluginValue ('result') eq 'REF SCALAR');
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): with custom and customArguments, ref scalar');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    custom            => \&actionOnSoapResponse,
    customArguments   => \[1, 2, 3],
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    xmlContent        => $xmlContent,
    params            => $params,
    cookies           => 1,
    perfdataLabel     => 'SOAP.t'
  );

  $errorStatus = ($returnCode == 0 && $objectPlugins->pluginValue ('result') eq 'REF ARRAY');
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): with custom and customArguments, ref array');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    custom            => \&actionOnSoapResponse,
    customArguments   => \{a=>1, b=>2, c=>3},
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    xmlContent        => $xmlContent,
    params            => $params,
    cookies           => 1,
    perfdataLabel     => 'SOAP.t'
  );

  $errorStatus = ($returnCode == 0 && $objectPlugins->pluginValue ('result') eq 'REF HASH');
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): with custom and customArguments, ref hash');
};

TODO: {
  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing SOAP parameter proxy\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): Missing SOAP parameter proxy');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    proxy             => $proxy
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing SOAP parameter namespace\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): Missing SOAP parameter namespace');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    proxy             => $proxy,
    namespace         => $namespace
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing SOAP parameter method\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): Missing SOAP parameter method');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => '%soapService_Register_NS'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing SOAP parameter registerNamespace\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): Missing SOAP parameter registerNamespace');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    readable          => 2
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QSOAP parameter readable must be 0 or 1\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): SOAP parameter readable must be 0 or 1');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    readline          => 1,
    cookies           => 2
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QSOAP parameter cookies must be 0 or 1\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): SOAP parameter cookies must be 0 or 1');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    cookies           => 1
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing SOAP parameter perfdataLabel\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): Missing SOAP parameter perfdataLabel');

  ($returnCode, $xml)    = get_soap_request ( 
    asnmtapInherited     => \$objectPlugins,
    proxy                => $proxy,
    namespace            => $namespace,
    registerNamespace    => \%soapService_Register_NS,
    method               => $method,
    xmlContent           => $xmlContent,
    params               => $params,
    cookies              => 1,
    perfdataLabel        => 'SOAP.t',
    PATCH_HTTP_KEEPALIVE => 2
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QSOAP parameter PATCH_HTTP_KEEPALIVE must be 0 or 1\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): SOAP parameter PATCH_HTTP_KEEPALIVE must be 0 or 1');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    xmlContent        => $xmlContent,
    params            => $params,
    cookies           => 1,
    perfdataLabel     => 'SOAP.t',
    WSRF              => 2
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QSOAP parameter WSRF must be 0 or 1\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): SOAP parameter WSRF must be 0 or 1');

  ($returnCode, $xml) = get_soap_request ( 
    asnmtapInherited  => \$objectPlugins,
    proxy             => $proxy,
    namespace         => $namespace,
    registerNamespace => \%soapService_Register_NS,
    method            => $method,
    xmlContent        => $xmlContent,
    params            => $params,
    cookies           => 1,
    perfdataLabel     => 'SOAP.t',
    TYPE_ERROR_RETURN => 'UNKNOWN'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QSOAP parameter TYPE_ERROR_RETURN must be [REPLACE|APPEND|INSERT|COMMA_APPEND|COMMA_INSERT]\E/);
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request(): SOAP parameter TYPE_ERROR_RETURN must be [REPLACE|APPEND|INSERT|COMMA_APPEND|COMMA_INSERT]');
}

no warnings 'deprecated';
$objectPlugins->{_pluginValues}->{stateValue} = $ERRORS{OK};
$objectPlugins->{_pluginValues}->{stateError} = $STATE{$ERRORS{OK}};
$objectPlugins->exit (0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub actionOnSoapResponse {
  my ($asnmtapInherited, $som, $arguments) = @_;

  my $result;

  if (defined $arguments) {
    for ( ref $arguments ) {
      /^REF$/ &&
        do { 
          for ( ref $$arguments ) {
            /^ARRAY$/ &&
              do { $result = 'REF ARRAY'; last; };
            /^HASH$/ &&
              do { $result = 'REF HASH'; last; };
          }

          last;
        };
      /^ARRAY$/ &&
        do { $result = 'ARRAY'; last; };
      /^HASH$/ &&
        do { $result = 'HASH'; last; };
      /^SCALAR$/ &&
        do { $result = 'REF SCALAR'; last; };
      $result = 'SCALAR';
    }
  }

  my $returnCode = $ERRORS{OK};
  $asnmtapInherited->pluginValues ( { stateValue => $returnCode, result => $result }, $TYPE{APPEND} );
  return ($returnCode);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

