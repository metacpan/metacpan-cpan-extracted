#!/usr/local/bin/perl

# Purpose : unit test for Any::Renderer::Data::Dumper
# Author  : Matt Wilson
# Created : 17th March 2006
# CVS     : $Header: /home/cvs/software/cvsroot/any_renderer/t/Any_Renderer_Data_Dumper.t,v 1.6 2006/08/29 12:40:48 andreww Exp $

use Test::Assertions::TestScript;
use Any::Renderer::Data::Dumper;

ASSERT ( 1, 'Compilation' );

# are we handling what we _think_ we're handling?
ASSERT ( EQUAL ( [ 'Data::Dumper' ], Any::Renderer::Data::Dumper::available_formats () ), "Handle expected formats" );

# do we require a template as expected (or not)?
ASSERT ( 0 == Any::Renderer::Data::Dumper::requires_template ( "Data::Dumper" ),  "Requires template?" );

# initiate an object with a specific variable name
my %options = ( VariableName => 'dd_var' );
my $dd = new Any::Renderer::Data::Dumper ( "Data::Dumper", \%options );

# rendering a list into Data::Dumper
ASSERT ( "\$dd_var = [\n            1,\n            2,\n            3\n          ];\n" eq $dd->render ( [ 1, 2, 3 ] ), "Render a list (with specific variable name)" );

# rendering of a hash into Data::Dumper
ASSERT ( "\$dd_var = {\n            '1' => 2\n          };\n" eq $dd->render ( { 1 => 2 } ), "Render a hash (with specific variable name)" );

# rendering of a singular value
ASSERT ( "\$dd_var = 1;\n" eq $dd->render ( 1 ), "Render a single value (with specific variable name)" );

# rendering of a singular string value
ASSERT ( "\$dd_var = 'string';\n" eq $dd->render ( "string" ), "Render a single value (with specific variable name)" );

# initiate an object
%options = ();
$dd = new Any::Renderer::Data::Dumper ( "Data::Dumper", \%options );

# rendering a list into Data::Dumper
ASSERT ( "\$VAR1 = [\n          1,\n          2,\n          3\n        ];\n" eq $dd->render ( [ 1, 2, 3 ] ), "Render a list" );

# rendering of a hash into Data::Dumper
ASSERT ( "\$VAR1 = {\n          '1' => 2\n        };\n" eq $dd->render ( { 1 => 2 } ), "Render a hash" );

# rendering of a singular value
ASSERT ( "\$VAR1 = 1;\n" eq $dd->render ( 1 ), "Render a single value" );

# rendering of a singular string value
ASSERT ( "\$VAR1 = 'string';\n" eq $dd->render ( "string" ), "Render a single value" );

# Test passing options to Data::Dumper
$dd = new Any::Renderer::Data::Dumper ( "Data::Dumper", {'DumperOptions' => {'Indent' => 0}} );
my $rv = $dd->render ( { 1 => 2 } );
ASSERT ( "\$VAR1 = {'1' => 2};" eq $rv, "Set Indent" );

# Test Data::Dumper method name checking
ASSERT(DIED(sub{ new Any::Renderer::Data::Dumper ( "Data::Dumper", {'DumperOptions' => {'Nonsense' => 1}} ) }) && $@ =~ /does not support a Nonsense method/,"Trapped dodgy method name");

# Trap invalid formats
ASSERT(DIED(sub {new Any::Renderer::Data::Dumper( "Nonsense", {} )}) && $@=~/Invalid format Nonsense/,"Trap invalid format");  

# vim: ft=perl
