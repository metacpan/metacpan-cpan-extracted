# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Asnmtap::Plugins::SOAP Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

# Class name  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
package ASNMTAP::Asnmtap::Plugins::SOAP;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Carp qw(cluck);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(%ERRORS %TYPE);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN {
  use Exporter ();

  @ASNMTAP::Asnmtap::Plugins::SOAP::ISA         = qw(Exporter ASNMTAP::Asnmtap);

  %ASNMTAP::Asnmtap::Plugins::SOAP::EXPORT_TAGS = ( ALL => [ qw(&get_soap_request) ] );

  @ASNMTAP::Asnmtap::Plugins::SOAP::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Plugins::SOAP::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Plugins::SOAP::VERSION     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub get_soap_request {
  my %defaults = ( asnmtapInherited     => undef,
                   custom               => undef,
                   customArguments      => undef,
                   proxy                => undef,
                   credentials          => undef,
                   namespace            => undef,
                   registerNamespace    => undef,
                   method               => undef,
                   soapaction           => undef,
                   xmlContent           => undef,
                   params               => undef,
                   envprefix            => 'soapenv',
                   encprefix            => 'soapenc',
                   encodingStyle        => undef,
                   readable             => 1,
                   cookies              => undef,
                   perfdataLabel        => undef,

                   PATCH_HTTP_KEEPALIVE => 0,
                   WSRF                 => 0,

                   TYPE_ERROR_RETURN    => 'REPLACE'
				 );

  my %parms = (%defaults, @_);

  my $asnmtapInherited = $parms{asnmtapInherited};
  unless ( defined $asnmtapInherited ) { cluck ( 'ASNMTAP::Asnmtap::Plugins::SOAP: asnmtapInherited missing' ); exit $ERRORS{UNKNOWN} }

  unless ( defined $parms{proxy} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing SOAP parameter proxy' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $namespace = $parms{namespace};

  unless ( defined $namespace ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing SOAP parameter namespace' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $registerNamespace = $parms{registerNamespace};

  if ( defined $registerNamespace ) {
    unless ( ref $registerNamespace eq 'HASH' ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing SOAP parameter registerNamespace' }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  }

  unless ( defined $parms{method} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing SOAP parameter method' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $soapaction = $parms{soapaction};

  my $xmlContent = $parms{xmlContent};

  my $params = $parms{params};

  my $readable = $parms{readable};

  my $envprefix = $parms{envprefix};

  my $encprefix = $parms{envprefix};

  my $encodingStyle = $parms{encodingStyle};

  unless ( $readable =~ /^[01]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'SOAP parameter readable must be 0 or 1' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $cookies = $parms{cookies};

  unless ( $cookies =~ /^[01]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'SOAP parameter cookies must be 0 or 1' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $parms{perfdataLabel} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing SOAP parameter perfdataLabel' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $PATCH_HTTP_KEEPALIVE = $parms{PATCH_HTTP_KEEPALIVE};

  unless ( $PATCH_HTTP_KEEPALIVE =~ /^[01]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'SOAP parameter PATCH_HTTP_KEEPALIVE must be 0 or 1' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $WSRF = $parms{WSRF};

  unless ( $WSRF =~ /^[01]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'SOAP parameter WSRF must be 0 or 1' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $TYPE_ERROR_RETURN = $parms{TYPE_ERROR_RETURN};

  unless ( $TYPE_ERROR_RETURN =~ /^(?:REPLACE|APPEND|INSERT|COMMA_APPEND|COMMA_INSERT)$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'SOAP parameter TYPE_ERROR_RETURN must be [REPLACE|APPEND|INSERT|COMMA_APPEND|COMMA_INSERT]' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my $browseragent  = $$asnmtapInherited->browseragent ();
  my $timeout       = $$asnmtapInherited->timeout ();

  my $proxySettings = $$asnmtapInherited->getOptionsArgv ( 'proxy' );

  my $debug         = $$asnmtapInherited->getOptionsValue ( 'debug' );

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _soapCheckTransportStatus {
    my ($asnmtapInherited, $service, $TYPE_ERROR_RETURN, $debug) = @_;

    my $transportStatus = $service->transport->status;
    print "ASNMTAP::Asnmtap::Plugins::SOAP::_soapCheckTransportStatus: $transportStatus\n" if ($debug);

    if ( $service->transport->is_success ) { 
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{OK}, alert => $transportStatus }, $TYPE{APPEND} );
      return $ERRORS{OK};
    };

    for ( $transportStatus ) {
      /500 Can_t connect to/ &&
        do { $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $transportStatus }, $TYPE{$TYPE_ERROR_RETURN} ); return $ERRORS{UNKNOWN}; last; };
      /500 configure certs failed/ &&
        do { $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $transportStatus }, $TYPE{$TYPE_ERROR_RETURN} ); return $ERRORS{UNKNOWN}; last; };
      /500 Connect failed/ &&
        do { $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $transportStatus }, $TYPE{$TYPE_ERROR_RETURN} ); return $ERRORS{UNKNOWN}; last; };
      /500 proxy connect failed/ &&
        do { $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $transportStatus }, $TYPE{$TYPE_ERROR_RETURN} ); return $ERRORS{UNKNOWN}; last; };
      /500 Internal Server Error/ &&
        do { $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $transportStatus }, $TYPE{$TYPE_ERROR_RETURN} ); return $ERRORS{UNKNOWN}; last; };
    }

    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => $transportStatus }, $TYPE{$TYPE_ERROR_RETURN} ); 
    return $ERRORS{CRITICAL};
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sub _soapCheckFault {
    my ($asnmtapInherited, $som, $debug) = @_;

    my $faultcode   = $som->faultcode; $faultcode =~ s/^\s+//g; $faultcode =~ s/\s+$//g;
    my $faultdetail = $som->faultdetail;
    my $faultstring = $som->faultstring;
    my $faultactor  = $som->faultactor;

    if ( $debug ) {
      print "ASNMTAP::Asnmtap::Plugins::SOAP::_soapCheckFault->faultcode   : ", $faultcode,   "\n" if (defined $faultcode);
      print "ASNMTAP::Asnmtap::Plugins::SOAP::_soapCheckFault->faultdetail : ", $faultdetail, "\n" if (defined $faultdetail);
      print "ASNMTAP::Asnmtap::Plugins::SOAP::_soapCheckFault->faultstring : ", $faultstring, "\n" if (defined $faultstring);
      print "ASNMTAP::Asnmtap::Plugins::SOAP::_soapCheckFault->faultactor  : ", $faultactor,  "\n" if (defined $faultactor);
    }

    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => $faultcode. ( defined $faultstring ? ' - ' .$faultstring : '' ) }, $TYPE{APPEND} ); 
    return $ERRORS{UNKNOWN};
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  my ($service, $alert, $error, $result);

  if ( $WSRF ) {
    if ( $debug >= 4 ) {
      eval "use WSRF::Lite +trace => 'all'";
    } elsif ($debug == 1) {
      eval "use WSRF::Lite +trace => qw( debug )";
    } else {
      eval "use WSRF::Lite";
    }

    $service = new WSRF::Lite
      -> wsaddress  ( WSRF::WS_Address->new()->Address( $parms{proxy} ) )
      -> autotype   ( 1 )
      -> readable   ( $readable )
      -> envprefix  ( $envprefix )
      -> encprefix  ( $encprefix )
      -> xmlschema  ( 'http://www.w3.org/2001/XMLSchema' )
      -> uri        ( $namespace )
      -> on_action  ( sub { my $uri = $_[0]; $uri =~ s/\/$//; my $method = (defined $soapaction ? ( $soapaction eq '' ? '' : $soapaction ) : $uri .'/'. $_[1]) } )
      -> on_fault   ( sub { } )
    ;
  } else {
    if ( $debug >= 4 ) {
      eval "use SOAP::Lite +trace => 'all'";
    } elsif ($debug == 1) {
      eval "use SOAP::Lite +trace => qw( debug )";
    } else {
      eval "use SOAP::Lite";
    }

    $service = new SOAP::Lite
      -> autotype   ( 1 )
      -> readable   ( $readable )
      -> envprefix  ( $envprefix )
      -> encprefix  ( $encprefix )
      -> xmlschema  ( 'http://www.w3.org/2001/XMLSchema' )
      -> uri        ( $namespace )
      -> on_action  ( sub { my $uri = $_[0]; $uri =~ s/\/$//; my $method = (defined $soapaction ? ( $soapaction eq '' ? '' : $soapaction ) : $uri .'/'. $_[1]) } )
      -> on_fault   ( sub { } )
    ;
  }

  $service->serializer->encodingStyle ( $encodingStyle ) if ( defined $encodingStyle );
  $SOAP::Constants::PATCH_HTTP_KEEPALIVE = $PATCH_HTTP_KEEPALIVE;

  if ( defined $parms{registerNamespace} ) {
    while ( my ($key, $value) = each( %{ $parms{registerNamespace} } ) ) {
      $service->serializer->register_ns($key, $value);
    }
  }

  if ( defined $proxySettings ) {
    $service->proxy ( $parms{proxy}, timeout => $timeout, proxy => ['http' => "http://$proxySettings"] );
  } else {
    $service->proxy ( $parms{proxy}, timeout => $timeout );
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $service->transport->credentials( @{$parms{credentials}} ) if ( defined $parms{credentials} );

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # $service->proxy ( 'https://USERNAME:PASSWORD@secure.citap.be/authorization/hibye.cgi' );
  # or
  # $service->proxy ( 'https://secure.citap.be/authorization/hibye.cgi', credentials => [ 'secure.citap.be:443', "ASNMTAP's Authorization Access", 'USERNAME' => 'PASSWORD' ], timeout => $timeout );
  # or
  # $service->transport->credentials( 'secure.citap.be:443', "ASNMTAP's Authorization Access", 'USERNAME' => 'PASSWORD' );
  # or
  # use MIME::Base64;
  # $service->transport->http_request->header( 'Authorization' => 'Basic '. MIME::Base64::encode ( 'USERNAME' .':'. 'PASSWORD', '' ) );
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $service->transport->agent( $browseragent );
  $service->transport->timeout( $timeout );  

  use HTTP::Cookies;
  $service->transport->cookie_jar( HTTP::Cookies->new ) if ( $cookies );

  $service->transport->default_headers->push_header( 'Accept-Language' => "no, en" );
  $service->transport->default_headers->push_header( 'Accept-Charset'  => "iso-8859-1,*,utf-8" );
  $service->transport->default_headers->push_header( 'Accept-Encoding' => "gzip, deflate" );
 
  print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: () -->\n" if ( $debug );
  $$asnmtapInherited->setEndTime_and_getResponsTime ( $$asnmtapInherited->pluginValue ('endTime') );

  my $som = (defined $params and $params ne '') ? (ref $params eq 'ARRAY' ? $service->call( $parms{method} => @$params ) : $service->call( $parms{method} => $params )) : $service->call( $parms{method} );

  my $responseTime = $$asnmtapInherited->setEndTime_and_getResponsTime ( $$asnmtapInherited->pluginValue ('endTime') );
  $$asnmtapInherited->appendPerformanceData ( "'". $parms{perfdataLabel} ."'=". $responseTime ."ms;;;;" );
  print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: () <->\n" if ( $debug );

  my $returnCode = _soapCheckTransportStatus ($asnmtapInherited, $service, $TYPE_ERROR_RETURN, $debug);

  unless ( $returnCode ) {
    unless ( defined $som and defined $som->fault ) {
      $result = UNIVERSAL::isa($som => ($WSRF ? 'WSRF::SOM' : 'SOAP::SOM')) ? (wantarray ? $som->paramsall : $som->result) : $som;

      if ( $debug ) {
        for ( ref $result ) {
          /^REF$/ &&
            do { 
              for ( ref $$result ) {
                /^ARRAY$/ &&
                  do { print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: REF ARRAY: @$$result\n"; last; };
                /^HASH$/ &&
                  do { print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: REF HASH: "; while (my ($key, $value) = each %{ $$result } ) { print "$key => $value "; }; print "\n"; last; };
              }

              last;
            };
          /^ARRAY$/ &&
            do { print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: ARRAY: @$result\n"; last; };
          /^HASH$/ &&
            do { print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: HASH: "; while (my ($key, $value) = each %{ $result } ) { print "$key => $value "; }; print "\n"; last; };
          /^SCALAR$/ &&
            do { print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: REF SCALAR: ", $$result, "\n"; last; };
          print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: SCALAR: ", $result, "\n";
        }
      }

      if ( $returnCode == $ERRORS{OK} and defined $parms{custom} ) {
        my $root = $som->dataof ('/Envelope/Body');

        if ( defined $root ) {
          $returnCode = ( defined $parms{customArguments} ) ? $parms{custom}->($$asnmtapInherited, $som, $parms{customArguments}) : $parms{custom}->($$asnmtapInherited, $som);
        } else {
          print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: Missing SOAP Envelope or Body", "\n" if ( $debug );
          $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing SOAP Envelope or Body' }, $TYPE{APPEND} );
          return ($returnCode, undef);
        }
      }
    } else {
      $returnCode = _soapCheckFault ($asnmtapInherited, $som, $debug);
    }
  } else {
    $returnCode = _soapCheckFault ($asnmtapInherited, $som, $debug) if ( defined $som and defined $som->fault );
  }

  print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: () <--\n" if ( $debug );
  return ($returnCode, undef) unless ( $returnCode == $ERRORS{OK} and defined $xmlContent );

  use XML::Simple;
  my $xml = XMLin($result);

  unless ( defined $xml ) {
    print "ASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: Error parsing XML formatted data", "\n" if ( $debug );
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => 'Error parsing XML formatted data' }, $TYPE{APPEND} ); 
    return ($returnCode, undef);
  }

  if ( $debug >= 2 ) {
    print "\nASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: Start XML dump\n";
    use Data::Dumper;
    print Dumper($xml);
    print "\nASNMTAP::Asnmtap::Plugins::SOAP::get_soap_request: End XML dump\n";
  }

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{OK}, alert => 'SOAP OK' }, $TYPE{APPEND} ); 
  return ($returnCode, $xml);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::SOAP is a Perl module that provides SOAP functions used by ASNMTAP-based plugins.

=head1 SEE ALSO

ASNMTAP::Asnmtap, ASNMTAP::Asnmtap::Plugins

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

ASNMTAP is based on 'Process System daemons v1.60.17-01', Alex Peeters [alex.peeters@citap.be]

 Purpose: CronTab (CT, sysdCT),
          Disk Filesystem monitoring (DF, sysdDF),
          Intrusion Detection for FW-1 (ID, sysdID)
          Process System daemons (PS, sysdPS),
          Reachability of Remote Hosts on a network (RH, sysdRH),
          Rotate Logfiles (system activity files) (RL),
          Remote Socket monitoring (RS, sysdRS),
          System Activity monitoring (SA, sysdSA).

'Process System daemons' is based on 'sysdaemon 1.60' written by Trans-Euro I.T Ltd

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut
