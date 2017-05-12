#!/usr/local/bin/perl

# Purpose : unit test for Any::Renderer::XML
# Author  : Matt Wilson
# Created : 17th March 2006
# CVS     : $Header: /home/cvs/software/cvsroot/any_renderer/t/Any_Renderer_XML.t,v 1.8 2006/08/29 12:40:48 andreww Exp $

BEGIN {
  use vars qw($NumTests $HaveXMLSimple);
  $NumTests = 1;
  eval {
    require XML::Simple;
    $NumTests += 10;
    $HaveXMLSimple = 1; 
  } 
}

use Test::Assertions::TestScript tests => $NumTests, auto_import_trace => 1;
ASSERT ( 1, 'Check if XML::Simple is available' );

if($HaveXMLSimple) {
  require Any::Renderer::XML;
  ASSERT ( 1, 'Compilation' );
  
  # are we handling what we _think_ we're handling?
  ASSERT ( EQUAL ( [ 'XML' ], Any::Renderer::XML::available_formats () ), "Handle expected formats" );
  
  # do we require a template as expected (or not)?
  ASSERT ( 0 == Any::Renderer::XML::requires_template ( "XML" ),
    "Requires template?" );
  
  # initiate an object
  my $renderer = new Any::Renderer::XML ( "XML" );
  
  # rendering a list
  ASSERT ( "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" standalone=\"yes\"?>\n<anon>1</anon>\n<anon>2</anon>\n<anon>3</anon>\n<anon>4</anon>\n" eq $renderer->render ( [ 1, 2, 3, 4 ] ), "Rendering a list" );
  
  # rendering a hash
  ASSERT ( "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" standalone=\"yes\"?>\n<output>\n  <1>2</1>\n  <2>3</2>\n  <3>4</3>\n  <abc>cde</abc>\n</output>\n" eq $renderer->render ( { 1 => 2, 2 => 3, 3 => 4, "abc" => "cde" } ), "Rendering a hash" );
  
  # initiate an object
  $renderer = new Any::Renderer::XML ( "XML", { XmlOptions => { KeepRoot => 1 } } );
  
  # rendering a list
  ASSERT ( "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" standalone=\"yes\"?>\n<anon>1</anon>\n<anon>2</anon>\n<anon>3</anon>\n<anon>4</anon>\n" eq $renderer->render ( [ 1, 2, 3, 4 ] ), "Rendering a list" );
  
  # rendering a hash
  ASSERT ( "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" standalone=\"yes\"?>\n<output>\n  <1>2</1>\n  <2>3</2>\n  <3>4</3>\n  <abc>cde</abc>\n</output>\n" eq $renderer->render ( { 1 => 2, 2 => 3, 3 => 4, "abc" => "cde" } ), "Rendering a hash" );
  
  # -------------------
  # Constructor options
  # -------------------
  
  my $output = '';
  
  # ------------
  # VariableName
  # ------------
  
  # initiate an object with a specific variable name
  %options = ( VariableName => 'xml_var' );
  $renderer = new Any::Renderer::XML ( "XML", \%options );
  
  # render a hash using a specific variable name
  $output = $renderer->render ( { 1 => 2, 2 => 3, 3 => 4, "abc" => "cde" } );
  ASSERT ( "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" standalone=\"yes\"?>\n<xml_var>\n  <1>2</1>\n  <2>3</2>\n  <3>4</3>\n  <abc>cde</abc>\n</xml_var>\n" eq $output, "Rendering a hash, with specific VariableName" );
  TRACE("output was:", $output);
  
  # ---
  # XML
  # ---
  
  # initiate an object with constructor options for the XML::Simple backend
  %options = ( XmlOptions => { RootName => 'xml_simple_var' } );
  $renderer = new Any::Renderer::XML ( "XML", \%options );
  
  # use RootName since it's easy to test
  $output = $renderer->render ( { 1 => 2, 2 => 3, 3 => 4, "abc" => "cde" } );
  ASSERT ( "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" standalone=\"yes\"?>\n<xml_simple_var>\n  <1>2</1>\n  <2>3</2>\n  <3>4</3>\n  <abc>cde</abc>\n</xml_simple_var>\n" eq $output, "Rendering a hash, with options passed to the XML::Simple backend" );
  TRACE("output was:", $output);
  
  # Trap invalid formats
  ASSERT(DIED(sub {new Any::Renderer::XML ( "Nonsense", {} )}) && $@=~/Invalid format Nonsense/,"Trap invalid format");  
}

# vim: ft=perl

sub xml_sanity_check {
    my ($xml) = @_;
    TRACE("xml: ".$xml);
    require XML::Simple;
    eval { XML::Simple::XMLin($xml) };
    warn $@ if $@;
    return !$@;
}
