#!/usr/bin/perl -w

# This is a Module::Build script for BioPerl-Network installation.
# See http://search.cpan.org/~kwilliams/Module-Build/lib/Module/Build.pm

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    dist_name           => 'BioPerl-Network',
    dist_version        => '1.006902',
    module_name         => 'Bio::Network',
    dist_author         => 'BioPerl Team <bioperl-l@bioperl.org>',
    dist_abstract       => 'BioPerl-Network - package for biological networks',
    license             => 'perl',
    requires            => {
                            'perl'                => '5.6.1',
                            'Bio::Root::Version'  => '1.006901',
                            'Graph'               => 0.86
                           },
    recommends          => {
                            'XML::Twig' => 3.22 # parsing PSI XML/Bio::Graph::IO::psi
                           },
    build_requires      => {
                            'Test::More'            => '0',
                            'Test::Warn'            => '0',
                            'Test::Exception'       => '0'
        }
    #dynamic_config      => 1,
    #create_makefile_pl  => 'passthrough'
);

$build->create_build_script;

exit;
