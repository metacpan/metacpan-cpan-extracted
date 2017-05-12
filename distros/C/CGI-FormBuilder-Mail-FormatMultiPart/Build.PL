#!/usr/bin/perl

use strict; 
use warnings;

my %requires = (
    'CGI::FormBuilder'  => '>= 3.0302',     # officially
    'MIME::Types'       => 0,
    'MIME::Lite'        => 0,
    'Text::FormatTable' => 0,
    'Module::Build'     => 0,
    'HTML::QuickTable'  => 0,
    'Regexp::Common'    => 0,
    'Test::More'        => 0,
    'Test::Exception'   => 0,
    'perl'              => '>= 5.6.0',
);

use Module::Build;

my $build = Module::Build->new(
    module_name     => 'CGI::FormBuilder::Mail::FormatMultiPart',
    dist_version    => 1.000006,
    license         => 'perl',
    requires        => { %requires },
    build_requires  => { %requires },
    dist_abstract   => 'Plugin module for CGI::FormBuilder->mailresults()',
    dist_author     => q{Mark Hedges <hedges@ucsd.edu},
);
$build->create_build_script;

