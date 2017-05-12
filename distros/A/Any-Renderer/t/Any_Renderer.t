#!/usr/local/bin/perl

# Purpose : unit test for Any::Renderer
# Author  : Matt Wilson
# Created : 17th March 2006
# CVS     : $Header: /home/cvs/software/cvsroot/any_renderer/t/Any_Renderer.t,v 1.8 2006/08/29 12:40:48 andreww Exp $

use Test::Assertions::TestScript auto_import_trace => 1;

use Any::Renderer;
ASSERT ( 1, 'Compilation' );

########################################################################
# Test available backends - this has to work whatever we have installed
########################################################################

# the known renderers and whether or not they require templates
my %known_renderers = (
    "Data::Dumper"      => 0,
    "JavaScript"        => 0,
    "JavaScript::Anon"  => 0,
    "Javascript"        => 0,
    "Javascript::Anon"  => 0,
    "JSON"              => 0,
    "UrlEncoded"        => 0,
    "XML"               => 0,
    "XSLT"              => 1,
);

# add all known Any::Template backends to that list with template=1
eval  {
  require Any::Template;
  my $atbe = Any::Template::available_backends();
  foreach my $f( @$atbe )
  {
    TRACE ( "Adding $f to list of known renderers" );
    $known_renderers { $f } = 1;
  }
};

#Ask what's available
my %d_renderers = map {$_ => Any::Renderer::requires_template ( $_ ) || 0} @{Any::Renderer::available_formats()};

DUMP ( "discovered renderers", \%d_renderers );
DUMP ( "known renderers", \%known_renderers );
ASSERT ( intersects( \%known_renderers, \%d_renderers ), "Check of available formats" );

##############################################################
# Use Data::Dumper to test the API as it's a core module
##############################################################

$format = "Data::Dumper";

#Test defaults (no options)
%options = ();
$renderer = new Any::Renderer ( $format, \%options );
ASSERT ( "\$VAR1 = [\n          1,\n          2,\n          3\n        ];\n" eq $renderer->render ( [ 1, 2, 3 ] ), "Render using defaults" );

#Test option passing
%options = ( VariableName => 'dd_var' );
$renderer = new Any::Renderer ( $format, \%options );
ASSERT ( "\$dd_var = [\n            1,\n            2,\n            3\n          ];\n" eq $renderer->render ( [ 1, 2, 3 ] ), "Using options" );

#############################################################
# Error trapping
#############################################################

eval
{
  new Any::Renderer ();
};
ASSERT ( $@, "No rendering format requested request throws an error?" );

eval
{
  new Any::Renderer ( "!!!");
};
ASSERT ( $@, "Invalid rendering format request throws an error?" );

sub intersects {
  my($lhs, $rhs) = @_;
  foreach (keys %$lhs) {
    return 0 if(exists $rhs->{$_} && ! EQUAL($lhs->{$_}, $rhs->{$_}));
  }
  return 1;
}

# vim: ft=perl
