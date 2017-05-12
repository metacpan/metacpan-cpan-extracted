package Acme::SList::XSLT;
$Acme::SList::XSLT::VERSION = '0.04';
use strict;
use warnings;

my ($mod_xslt, $mod_xml);

eval{
    require XML::LibXSLT;
    $mod_xslt = 'XML::LibXSLT';
    $mod_xml  = 'XML::LibXML';
};
if ($@) {
    require Win32::MinXSLT;
    $mod_xslt = 'Win32::MinXSLT';
    $mod_xml  = 'Win32::MinXML';
}

sub module { $mod_xslt; }

sub new { $mod_xslt->new; }

package Acme::SList::XML;
$Acme::SList::XML::VERSION = '0.04';
sub module { $mod_xml; }

sub new { $mod_xml->new; }

1;

__END__

=head1 NAME

Acme::SList::XSLT - Perform XSLT transparently between XML::LibXSLT and Win32::MinXSLT

=head1 SYNOPSIS

  use Acme::SList::XSLT;

  print "XSLT Module being used is: ", Acme::SList::XSLT->module, "\n";
  print "XML  Module being used is: ", Acme::SList::XML->module,  "\n";
  print "\n";

  my $parser     = Acme::SList::XML->new();
  my $xslt       = Acme::SList::XSLT->new();
  
  my $source     = $parser->parse_string(
  q{<?xml version="1.0" encoding="iso-8859-1"?>
    <index>
      <data>aaa</data>
      <data>bbb</data>
      <data>ccc</data>
      <data>ddd</data>
    </index>
    });

  my $style_doc  = $parser->parse_string(
  q{<?xml version="1.0" encoding="iso-8859-1"?>
    <xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="xml" indent="yes" encoding="iso-8859-1"/>
      <xsl:template match="/">
        <html>
          <body>
            <title>Test</title>
            Data:
            <hr/>
            <xsl:for-each select="index/data">
              <p>Test: *** <xsl:value-of select="."/> ***</p>
            </xsl:for-each>
          </body>
        </html>
      </xsl:template>
    </xsl:stylesheet>
    });

  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  my $results    = $stylesheet->transform($source);

  print $stylesheet->output_string($results);

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=cut
