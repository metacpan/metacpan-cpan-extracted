# ----------------------------------------------------------------------------------------------------------
# © Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Asnmtap::Plugins::XML Object-Oriented Perl
# ----------------------------------------------------------------------------------------------------------

# Class name  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
package ASNMTAP::Asnmtap::Plugins::XML;

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

  @ASNMTAP::Asnmtap::Plugins::XML::ISA         = qw(Exporter ASNMTAP::Asnmtap);

  %ASNMTAP::Asnmtap::Plugins::XML::EXPORT_TAGS = ( ALL => [ qw(&extract_XML) ] );

  @ASNMTAP::Asnmtap::Plugins::XML::EXPORT_OK   = ( @{ $ASNMTAP::Asnmtap::Plugins::XML::EXPORT_TAGS{ALL} } );

  $ASNMTAP::Asnmtap::Plugins::XML::VERSION     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
}

# Utility methods - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub extract_XML {
  my %defaults = ( asnmtapInherited => undef,
                   custom           => undef,
                   customArguments  => undef,
                   resultXML        => undef,
                   filenameXML      => undef,
                   headerXML        => undef,
                   footerXML        => undef,
                   validateDTD      => 0,
                   filenameDTD      => '');

  my %parms = (%defaults, @_);

  my $asnmtapInherited = $parms{asnmtapInherited};
  unless ( defined $asnmtapInherited ) { cluck ( 'ASNMTAP::Asnmtap::Plugins::XML: asnmtapInherited missing' ); exit $ERRORS{UNKNOWN} }

  my $debug = $$asnmtapInherited->getOptionsValue ( 'debug' ) || 0;

  my $resultXML = $parms{resultXML};

  if ( $debug >= 2 ) {
    print 'ASNMTAP::Asnmtap::Plugins::XML: Result   XML: ', "\n", $resultXML, "\n" if (defined $resultXML);
    print 'ASNMTAP::Asnmtap::Plugins::XML: Filename XML: ', $parms{filenameXML}, "\n" if ($parms{filenameXML});
    print 'ASNMTAP::Asnmtap::Plugins::XML: Header   XML: ', $parms{headerXML}, "\n" if ($parms{headerXML});
    print 'ASNMTAP::Asnmtap::Plugins::XML: Footer   XML: ', $parms{footerXML}, "\n" if ($parms{footerXML});
    print 'ASNMTAP::Asnmtap::Plugins::XML: Validate DTD: ', $parms{validateDTD}, "\n";
    print 'ASNMTAP::Asnmtap::Plugins::XML: Filename DTD: ', $parms{filenameDTD}, "\n";
  }

  if ( $parms{filenameXML} ) {
    unless ( -s $parms{filenameXML} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "The XML file '". $parms{filenameXML} ."' doesn't exist" }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    my $rvOpen = open ( XMLFILE, $parms{filenameXML} );

    if ( $rvOpen ) {
      while (<XMLFILE>) { $resultXML .= $_; }
      print "ASNMTAP::Asnmtap::Plugins::XML: XML file\n", $resultXML if ( $debug );
      close (XMLFILE);
    }
  }

  unless ( defined $resultXML ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing resultXML and/or filenameXML' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $parms{headerXML} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing XML HEADER' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( defined $parms{footerXML} ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Missing XML FOOTER' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  unless ( $parms{validateDTD} =~ /^[01]$/ ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Parameter validateDTD must be 0 or 1' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $pos = index $resultXML, $parms{headerXML};

  if ( $pos == -1 ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Wrong XML HEADER' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  $resultXML = substr ( $resultXML, $pos );
  $pos = index $resultXML, $parms{footerXML};

  if ( $pos == -1 ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => 'Wrong XML FOOTER' }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  my $len = length ( $parms{footerXML} );
  $resultXML = substr ($resultXML, 0, $pos + $len);
  print "\nASNMTAP::Asnmtap::Plugins::XML: <out>\n$resultXML\nASNMTAP::Asnmtap::Plugins::XML: </out>\n" if ($debug >= 2);

  if ( $parms{validateDTD} ) {
    unless ( $parms{filenameDTD} and -s $parms{filenameDTD} ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "The DTD file '". $parms{filenameDTD} ."' doesn't exist" }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }

    use XML::LibXML;
    my $dtd = XML::LibXML::Dtd->new ( '', $parms{filenameDTD} );
    my $xml = XML::LibXML->new->parse_string ( $resultXML );

    unless ( $xml->is_valid ( $dtd ) ) {
      $xml->validate ( $dtd ) if ( $debug >= 2 );
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "The XML doesn't validate" }, $TYPE{APPEND} );
      return ( $ERRORS{UNKNOWN} );
    }
  }

  use XML::Simple;
  my $returnXML = XMLin( $resultXML );

  unless ( defined $returnXML ) {
    $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "Error parsing XML formatted data" }, $TYPE{APPEND} );
    return ( $ERRORS{UNKNOWN} );
  }

  if ( $debug >= 2 ) {
    use Data::Dumper;
    print "\nASNMTAP::Asnmtap::Plugins::XML: Start XML data dump\n", Dumper( $returnXML ), "\nASNMTAP::Asnmtap::Plugins::XML: End XML data dump\n";
  }

  my $returnCode = $ERRORS{OK};

  if ( defined $parms{custom} ) {
    $returnCode = ( defined $parms{customArguments} ) ? $parms{custom}->($$asnmtapInherited, $returnXML, $parms{customArguments}) : $parms{custom}->($$asnmtapInherited, $returnXML);
  }
 
  return ( $returnCode, $returnXML );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::XML is a Perl module that provides XML functions used by ASNMTAP-based plugins.

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
