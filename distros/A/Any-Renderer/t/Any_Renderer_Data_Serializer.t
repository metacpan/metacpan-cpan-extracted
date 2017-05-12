#!/usr/local/bin/perl

# Purpose : unit test for Any::Renderer::Data::Serializer
# Author  : John Alden
# Created : 15th August 2006
# CVS     : $Header: /home/cvs/software/cvsroot/any_renderer/t/Any_Renderer_Data_Serializer.t,v 1.7 2006/08/29 12:40:48 andreww Exp $

BEGIN {
  use vars qw($NumTests $HaveDataSerializer);
  $NumTests = 1;
  eval {
    require Data::Serializer;
    $NumTests += 8; 
    $HaveDataSerializer = 1;
  } 
}

use Test::Assertions::TestScript tests => $NumTests, auto_import_trace => 1;
ASSERT ( 1, 'Check if Data::Serializer is available' );

if($HaveDataSerializer) {
  require Any::Renderer::Data::Serializer;
  ASSERT ( 1, 'Compilation' );
  
  # are we handling what we _think_ we're handling?
  ASSERT ( scalar (grep { $_ eq 'Data::Dumper' } @{Any::Renderer::Data::Serializer::available_formats ()}), "Handle expected formats" );
  
  # do we require a template as expected (or not)?
  ASSERT ( 0 == Any::Renderer::Data::Serializer::requires_template ( "Data::Dumper" ), "Requires template?" );
  
  # initiate an object
  %options = ();
  $dd = new Any::Renderer::Data::Serializer ( "Data::Dumper", \%options );
  
  # rendering a list into Data::Serializer
  ASSERT ( "[1,2,3]" eq $dd->render ( [ 1, 2, 3 ] ), "Render a list" );
  
  # rendering of a hash into Data::Serializer
  ASSERT ( "{'1' => 2}" eq $dd->render ( { 1 => 2 } ), "Render a hash" );
  
  # rendering of a integer value
  ASSERT ( "1" eq $dd->render ( 1 ), "Render an integer" );
  
  # rendering of a singular string value (allow for variations in Data::Serializer/Dumper versions)
  ASSERT ( $dd->render("string") =~ /\bstring\b/, "Render a string value" );

  # Trap invalid formats
  ASSERT(DIED(sub {new Any::Renderer::Data::Serializer( "Nonsense", {} )}) && $@=~/format 'Nonsense'/,"Trap invalid format");  

}
# vim: ft=perl
