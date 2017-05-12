#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-SOAP.pl
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
  _programName        => 'check_template-SOAP.pl',
  _programDescription => "SOAP::LITE plugin template for testing the '$APPLICATION' with Performance Data",
  _programVersion     => '3.002.003',
  _programGetOptions  => ['proxy:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::SOAP qw(&get_soap_request);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use SOAP::Lite;

my $proxy      = 'http://services.soaplite.com/hibye.cgi';
my $namespace  = 'http://www.soaplite.com/Demo';
my $methodName = 'hi';
my $method     = SOAP::Data->name($methodName)->attr( {xmlns => $namespace} );

my %soapService_Register_NS = (
  'http://schemas.xmlsoap.org/wsdl/mime/' => 'mime',
  'http://www.w3.org/2001/XMLSchema'      => 's'
);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($returnCode, $xml);

($returnCode, $xml) = get_soap_request ( 
  asnmtapInherited  => \$objectPlugins,
  custom            => \&actionOnSoapResponse,
  customArguments   => 'scalar',
  proxy             => $proxy,
  namespace         => $namespace,
  method            => $method,
  registerNamespace => \%soapService_Register_NS,
  cookies           => 1,
  perfdataLabel     => 'SOAP'
);

($returnCode, $xml) = get_soap_request ( 
  asnmtapInherited  => \$objectPlugins,
  custom            => \&actionOnSoapResponse,
  customArguments   => [1, 2, 3],
  proxy             => $proxy,
  namespace         => $namespace,
  method            => $method,
  registerNamespace => \%soapService_Register_NS,
  cookies           => 1,
  perfdataLabel     => 'SOAP'
);

($returnCode, $xml) = get_soap_request ( 
  asnmtapInherited  => \$objectPlugins,
  custom            => \&actionOnSoapResponse,
  customArguments   => {a => 1, b => 2, c => 3},
  proxy             => $proxy,
  namespace         => $namespace,
  method            => $method,
  registerNamespace => \%soapService_Register_NS,
  cookies           => 1,
  perfdataLabel     => 'SOAP'
);

($returnCode, $xml) = get_soap_request ( 
  asnmtapInherited  => \$objectPlugins,
  custom            => \&actionOnSoapResponse,
  customArguments   => \$proxy,
  proxy             => $proxy,
  namespace         => $namespace,
  method            => $method,
  registerNamespace => \%soapService_Register_NS,
  cookies           => 1,
  perfdataLabel     => 'SOAP'
);

($returnCode, $xml) = get_soap_request ( 
  asnmtapInherited  => \$objectPlugins,
  custom            => \&actionOnSoapResponse,
  customArguments   => \[1, 2, 3],
  proxy             => $proxy,
  namespace         => $namespace,
  method            => $method,
  registerNamespace => \%soapService_Register_NS,
  cookies           => 1,
  perfdataLabel     => 'SOAP'
);

($returnCode, $xml) = get_soap_request ( 
  asnmtapInherited  => \$objectPlugins,
  custom            => \&actionOnSoapResponse,
  customArguments   => \{a => 1, b => 2, c => 3},
  proxy             => $proxy,
  namespace         => $namespace,
  method            => $method,
  registerNamespace => \%soapService_Register_NS,
  cookies           => 1,
  perfdataLabel     => 'SOAP'
);

unless ( $returnCode ) {
  if (defined $xml) {
  } else {
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub actionOnSoapResponse {
  my ($asnmtapInherited, $tSom, $arguments) = @_;

  my $debug = $asnmtapInherited->getOptionsValue ('debug');

  if ($debug and defined $arguments) {
    for ( ref $arguments ) {
      /^REF$/ &&
        do { 
          for ( ref $$arguments ) {
            /^ARRAY$/ &&
              do { print "REF ARRAY: @$$arguments\n"; last; };
            /^HASH$/ &&
              do { print "REF HASH: "; while (my ($key, $value) = each %{ $$arguments } ) { print "$key => $value "; }; print "\n"; last; };
          }

          last;
        };
      /^ARRAY$/ &&
        do { print "ARRAY: @$arguments\n"; last; };
      /^HASH$/ &&
        do { print "HASH: "; while (my ($key, $value) = each %{ $arguments } ) { print "$key => $value "; }; print "\n"; last; };
      /^SCALAR$/ &&
        do { print "REF SCALAR: ", $$arguments, "\n"; last; };
      print "SCALAR: ", $arguments, "\n";
    }
  }

  my $returnCode = $ERRORS{OK};
  $asnmtapInherited->pluginValues ( { stateValue => $returnCode, alert => 'SOAP::LITE' }, $TYPE{APPEND} );
  return ($returnCode);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-SOAP.pl

SOAP::LITE plugin template for testing the 'Application Monitor' with Performance Data

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
