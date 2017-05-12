#!/usr/local/bin/perl

# Purpose : unit test for Any::Renderer::JavaScript
# Author  : Matt Wilson
# Created : 17th March 2006
# CVS     : $Header: /home/cvs/software/cvsroot/any_renderer/t/Any_Renderer_JavaScript.t,v 1.11 2006/09/19 10:29:09 mattheww Exp $

BEGIN {
  use vars qw($NumTests $HaveDJ);
  $NumTests = 1;
  eval {
    require Data::JavaScript;
    $NumTests += 20; 
    $HaveDJ=1;
  } 
}

use Test::Assertions::TestScript tests => $NumTests, auto_import_trace => 1;
ASSERT ( 1, 'Check if Data::JavaScript is available' );

if($HaveDJ) {
  require Any::Renderer::JavaScript;
  ASSERT ( 1, 'Compilation' );
  
  # are we handling what we _think_ we're handling?
  ASSERT (
    EQUAL ( [ 'JavaScript', 'Javascript' ],
            Any::Renderer::JavaScript::available_formats () ),
    "Handle expected formats" );
  
  # do we require a template as expected (or not)?
  ASSERT ( 0 == Any::Renderer::JavaScript::requires_template ( "JavaScript" ),
    "Requires template?" );
  
  # initiate an object with a specific variable name
  my %options = ( 'VariableName' => 'js_var' );
  my $js = new Any::Renderer::JavaScript ( "JavaScript", \%options );
  
  # rendering a list into JS
  $rendered = $js->render ( [ 1, 2, 3 ] );
  ASSERT ( $rendered =~ m/var js_var = new Array;/,
      "Render a list (with specific variable name)" );
  ASSERT ( $rendered =~ m/js_var\s*\[\s*((0)|("0")|('0'))\s*\]\s*=\s*1;/,
      "Render a list (with specific variable name)" );
  ASSERT ( $rendered =~ m/js_var\s*\[\s*((1)|("1")|('1'))\s*\]\s*=\s*2;/,
      "Render a list (with specific variable name)" );
  ASSERT ( $rendered =~ m/js_var\s*\[\s*((2)|("2")|('2'))\s*\]\s*=\s*3;/,
      "Render a list (with specific variable name)" );

  # rendering of a hash into JS
  my $rendered = $js->render ( { 1 => 2 } );

  ASSERT ( $rendered =~ m/var js_var\s*=\s*new Object;/,
      "Render a hash (with specific variable name)" );

  ASSERT ( $rendered =~ m/js_var\s*\[\s*(('1')|("1")|(1))\s*\]\s*=\s*2;/,
      "Render a hash (with specific variable name)" );
  
  # rendering of a singular value
  $rendered = $js->render ( 1 );
  ASSERT ( $rendered =~ m/var\s+js_var\s*=\s*1;/, "Render a single value (with specific variable name)" );
  
  # rendering of a singular string value
  $rendered = $js->render ( "string" );
  ASSERT ( $rendered =~ m/var\s+js_var\s*=\s*('string'|"string");/, "Render a single value (with specific variable name)" );
  
  # initiate an object
  %options = ();
  $js = new Any::Renderer::JavaScript ( "JavaScript", \%options );
  
  # rendering a list into JS
  $rendered = $js->render ( [ 1, 2, 3 ] );
  ASSERT ( $rendered =~ m/var\s+script_output\s*=\s*new\s+Array;/, "Render a list" );
  ASSERT ( $rendered =~ m/script_output\s*\[\s*((0)|("0")|('0'))\s*\]\s*=\s*1;/, "Render a list" );
  ASSERT ( $rendered =~ m/script_output\s*\[\s*((1)|("1")|('1'))\s*\]\s*=\s*2;/, "Render a list" );
  ASSERT ( $rendered =~ m/script_output\s*\[\s*((2)|("2")|('2'))\s*\]\s*=\s*3;/, "Render a list" );
  
  # rendering of a hash into JS
  $rendered = $js->render ( { 1 => 2 } );
  ASSERT ( $rendered =~ m/var script_output = new Object;/, "Render a hash" );
  ASSERT ( $rendered =~ m/script_output\s*\[\s*((1)|("1")|('1'))\s*\]\s*=\s*2;/, "Render a hash" );
  
  # rendering of a singular value
  ASSERT ( $js->render ( 1 ) =~ m/var\s+script_output\s*=\s*1;/, "Render a single value" );
  
  # rendering of a singular string value
  ASSERT ( $js->render ( "string"  ) =~ m/var\s+script_output\s*=\s*('string'|"string");/,
      "Render a single value" );

  # Trap invalid formats
  ASSERT(DIED(sub {new Any::Renderer::JavaScript( "Nonsense", {} )}) && $@=~/format 'Nonsense' isn't supported/,"Trap invalid format");  

}

# vim: ft=perl:et:ts=2:sw=2
