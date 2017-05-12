#!/usr/local/bin/perl

# Purpose : unit test for Any::Renderer::UrlEncoded
# Author  : Matt Wilson
# Created : 17th March 2006
# CVS     : $Header: /home/cvs/software/cvsroot/any_renderer/t/Any_Renderer_UrlEncoded.t,v 1.8 2006/08/29 12:40:48 andreww Exp $

#Check dependencies
BEGIN {
  use vars qw($NumTests $HaveDep);
  $NumTests = 1;
  eval {
    require Hash::Flatten;
    require URI::Escape;
    $NumTests += 7; 
    $HaveDep = 1;
  } 
}

use Test::Assertions::TestScript tests => $NumTests, auto_import_trace => 1;
ASSERT ( 1, 'Check if dependencies are available' );

if($HaveDep) {
  require Any::Renderer::UrlEncoded;
  ASSERT ( 1, 'Compilation' );
  
  # are we handling what we _think_ we're handling?
  ASSERT ( EQUAL ( [ 'UrlEncoded' ], Any::Renderer::UrlEncoded::available_formats () ), "Handle expected formats" );
  
  # do we require a template as expected (or not)?
  ASSERT ( 0 ==
    Any::Renderer::UrlEncoded::requires_template ( "UrlEncoded" ),
    "Requires template?" );
  
  # initiate an object
  my $renderer = new Any::Renderer::UrlEncoded ( "UrlEncoded" );
  
  # rendering a list into JS
  ASSERT ( "1=2" eq $renderer->render ( { 1 => 2 } ), "Render a query string" ), 
  
  ASSERT ( "abc=%26!!!%3B" eq $renderer->render ( { "abc" => "&!!!;" } ), "Render a query string with quotables" ), 

  # use some Hash::Flatten options
  $renderer = new Any::Renderer::UrlEncoded ( "UrlEncoded", {FlattenOptions => {HashDelimiter => ":"}} );
  ASSERT ( "a%3A1=2" eq $renderer->render ( { a => {1 => 2}} ), "Pass options to Hash::Flatten" ), 

  # Trap invalid formats
  ASSERT(DIED(sub {new Any::Renderer::UrlEncoded( "Nonsense", {} )}) && $@=~/Invalid format Nonsense/,"Trap invalid format");  
}

# vim: ft=perl
