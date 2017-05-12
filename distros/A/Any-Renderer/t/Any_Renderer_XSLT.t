#!/usr/local/bin/perl

# Purpose : unit test for Any::Renderer::XSLT
# Author  : Matt Wilson
# Created : 17th March 2006
# CVS     : $Header: /home/cvs/software/cvsroot/any_renderer/t/Any_Renderer_XSLT.t,v 1.6 2006/08/29 12:40:49 andreww Exp $

BEGIN {
  use vars qw($NumTests $HaveDeps);
  $NumTests = 1;
  eval {
    require XML::Simple;
    require XML::LibXSLT;
    require XML::LibXML;
    require Cache::AgainstFile;
    $NumTests += 11;
    $HaveDeps = 1; 
  } 
}

use Test::Assertions::TestScript tests => $NumTests, auto_import_trace => 1;
ASSERT ( 1, 'Check if dependencies are available' );

if($HaveDeps) {
  
  require Any::Renderer::XSLT;
  ASSERT ( 1, 'Compilation' );
  
  # are we handling what we _think_ we're handling?
  ASSERT ( EQUAL ( [ 'XSLT' ], Any::Renderer::XSLT::available_formats () ), "Handle expected formats" );
  
  # do we require a template as expected (or not)?
  ASSERT ( 1 == Any::Renderer::XSLT::requires_template ( "XSLT" ),
    "Requires template?" );
  
  # initiate an object
  my %options = (
    'TemplateFilename'  => 'data/test.xsl',
  );
  my $xslt = new Any::Renderer::XSLT ( "XSLT", \%options );
  
  my $xml = $xslt->render ( { foo => 'Bar' } );
  
  ASSERT ( "<?xml version=\"1.0\"?>\n<p>Hello Bar</p>\n" eq $xml, "Rendering of a simple XSLT template." );
  
  $xslt = new Any::Renderer::XSLT ( "XSLT", \%options );
  
  $xml = $xslt->render ( { foo => 'Bar' } );
  
  ASSERT ( "<?xml version=\"1.0\"?>\n<p>Hello Bar</p>\n" eq $xml, "Rendering of a simple XSLT template (w/Cache)." );
  
  # let's try that again, this time without caching!
  $options { 'NoCache' } = 1;
  $xslt = new Any::Renderer::XSLT ( "XSLT", \%options );
  
  $xml = $xslt->render ( { foo => 'Bar' } );
  
  ASSERT ( "<?xml version=\"1.0\"?>\n<p>Hello Bar</p>\n" eq $xml, "Rendering of a simple XSLT template." );
  
  # initiate an object
  %options = (
    TemplateFilename  => 'data/test.xsl',
    XmlOptions => { KeepRoot => 1 },
  );
  $xslt = new Any::Renderer::XSLT ( "XSLT", \%options );
  
  $xml = $xslt->render ( { foo => 'Bar' } );
  
  ASSERT ( "<?xml version=\"1.0\"?>\n<p>Hello Bar</p>\n" eq $xml, "Rendering of a simple XSLT template." );
  
  $xslt = new Any::Renderer::XSLT ( "XSLT", \%options );
  
  $xml = $xslt->render ( { foo => 'Bar' } );
  
  ASSERT ( "<?xml version=\"1.0\"?>\n<p>Hello Bar</p>\n" eq $xml, "Rendering of a simple XSLT template (w/Cache)." );
  
  # let's try that again, this time without caching!
  $options { 'NoCache' } = 1;
  $xslt = new Any::Renderer::XSLT ( "XSLT", \%options );
  
  $xml = $xslt->render ( { foo => 'Bar' } ); 
  ASSERT ( "<?xml version=\"1.0\"?>\n<p>Hello Bar</p>\n" eq $xml, "Rendering without cache." );
  
  # Pass in the template as string
  %options = (
    'TemplateString'  => READ_FILE('data/test.xsl'),
  );
  $xslt = new Any::Renderer::XSLT ( "XSLT", \%options );
  $xml = $xslt->render ( { foo => 'Bar' } ); 
  ASSERT ( "<?xml version=\"1.0\"?>\n<p>Hello Bar</p>\n" eq $xml, "Rendering XSLT template from string." );

  # Trap invalid formats
  ASSERT(DIED(sub {new Any::Renderer::XSLT ( "Nonsense", {} )}) && $@=~/Invalid format Nonsense/,"Trap invalid format");  
}

# vim: ft=perl
