#!/usr/local/bin/perl

# Purpose : unit test for Any::Renderer::JavaScript::Anon
# Author  : Matt Wilson
# Created : 17th March 2006
# CVS     : $Header: /home/cvs/software/cvsroot/any_renderer/t/Any_Renderer_JavaScript_Anon.t,v 1.9 2006/08/29 12:40:48 andreww Exp $

BEGIN {
  use vars qw($NumTests $HaveDJA);
  $NumTests = 1;
  eval {
    require Data::JavaScript::Anon;
    $NumTests += 16; 
    $HaveDJA = 1;
  } 
}

use Test::Assertions::TestScript tests => $NumTests, auto_import_trace => 1;
ASSERT ( 1, 'Check if Data::JavaScript::Anon is available' );

if($HaveDJA) {
  require Any::Renderer::JavaScript::Anon;
  ASSERT ( 1, 'Compilation' );
  
  # are we handling what we _think_ we're handling?
  ASSERT ( EQUAL ( [ 'JavaScript::Anon', 'Javascript::Anon', 'JSON' ],
           Any::Renderer::JavaScript::Anon::available_formats () ), "Handle expected formats" );
  
  # do we require a template as expected (or not)?
  ASSERT ( 0 ==
    Any::Renderer::JavaScript::Anon::requires_template ( "JavaScript::Anon" ),
    "Requires template?" );
  
  # initiate an object with a specific output variable name
  my %options = ( 'VariableName' => 'js_var' );
  my $js = new Any::Renderer::JavaScript::Anon ( "JavaScript::Anon", \%options );
  
  # rendering a list into JS
  ASSERT ( "var js_var = [ 1, 2, 3 ];" eq $js->render ( [ 1, 2, 3 ] ), "Render a list (with specific variable name)" );
  
  # rendering of a hash into JS
  ASSERT ( "var js_var = { 1: 2 };" eq $js->render ( { 1 => 2 } ), "Render a hash (with specific variable name)" );
  
  # rendering of a singular value
  ASSERT ( "var js_var = 1;" eq $js->render ( 1 ), "Render a single value (with specific variable name)" );
  
  # rendering of a singular string value
  ASSERT ( "var js_var = \"string\";" eq $js->render ( "string" ), "Render a single value (with specific variable name)" );
  
  
  # initiate an object
  %options = ();
  $js = new Any::Renderer::JavaScript::Anon ( "JavaScript::Anon", \%options );
  
  # rendering a list into JS
  ASSERT ( "var script_output = [ 1, 2, 3 ];" eq $js->render ( [ 1, 2, 3 ] ), "Render a list" );
  
  # rendering of a hash into JS
  ASSERT ( "var script_output = { 1: 2 };" eq $js->render ( { 1 => 2 } ), "Render a hash" );
  
  # rendering of a singular value
  ASSERT ( "var script_output = 1;" eq $js->render ( 1 ), "Render a single value" );
  
  # rendering of a singular string value
  ASSERT ( "var script_output = \"string\";" eq $js->render ( "string" ), "Render a single value" );
  
  
  # instantiate an object with anonymous output
  %options = ( );
  $js = new Any::Renderer::JavaScript::Anon ( "JSON", \%options );
  
  # rendering a list into JS
  ASSERT ( "[ 1, 2, 3 ]" eq $js->render ( [ 1, 2, 3 ] ), "Render a list (with specific variable name)" );
  
  # rendering of a hash into JS
  ASSERT ( "{ 1: 2 }" eq $js->render ( { 1 => 2 } ), "Render a hash (with specific variable name)" );
  
  # rendering of a singular value
  ASSERT ( "1" eq $js->render ( 1 ), "Render a single value (with specific variable name)" );
  
  # rendering of a singular string value
  ASSERT ( "\"string\"" eq $js->render ( "string" ), "Render a single value (with specific variable name)" );

  # Trap invalid formats
  ASSERT(DIED(sub {new Any::Renderer::JavaScript::Anon( "Nonsense", {} )}) && $@=~/format 'Nonsense' isn't supported/,"Trap invalid format");  
}

# vim: ft=perl
