#!/usr/bin/perl -w

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    dist_name            => 'Bio-Community',
    module_name          => 'Bio::Community', # look here for version number
    dist_author          => 'BioPerl Team <bioperl-l@bioperl.org>',
    dist_abstract        => 'Modules to represent and manipulate communities of biological organisms',
    license              => 'perl',
    recursive_test_files => 1,
    create_license       => 1,
    meta_merge           => {
                             'resources' => {
                                             'repository' => 'git://github.com/bioperl/Bio-Community.git',
                                             'homepage'   => 'http://www.bioperl.org',
                                             'bugtracker' => 'https://redmine.open-bio.org/projects/bioperl/',
                                            },
                            },
    build_requires       => {
                             'Test::Number::Delta'          =>  0,
                             # Modules for author tests
                             #'Test::Pod::Coverage'         =>  1.00,
                             #'Pod::Coverage::Moose'        =>  0,
                            },
    requires             => {
                             'perl'                         => '5.10.0',
                             'Bio::Root::Version'           => '1.006923',
                             'DateTime'                     =>  0,
                             'Getopt::Euclid'               => '0.4.3',
                             'JSON::XS'                     =>  0, # biom format
                             'Hash::Util'                   =>  0,
                             'Math::Random::MT'             =>  0, # PRNG role
                             'Method::Signatures'           =>  20140224,
                             'Module::Runtime'              =>  0, # load IO drivers
                             'Moose'                        =>  0,
                             'MooseX::NonMoose'             =>  0,
                             'MooseX::StrictConstructor'    =>  0,
                             'PerlIO::eol'                  =>  0, # IO portable line endings
                             'Scalar::Util'                 =>  0,
                             'Tie::IxHash'                  =>  0, # metacommunity
                            },
    recommends           => {
                             #'Clone::Fast'                 =>  0, # C bindings for Bio::Root::clone(). Broken in 0.97?!
                             'Math::GSL::SF'                =>  0, # C bindings for arithmetic
                             'Math::GSL::Randist'           =>  0, # C bindings for random number generation
                             'Math::GSL::RNG'               =>  0, # C bindings for random number generation
                            },
    script_files         => [
                             'bin/bc_accumulate',
                             'bin/bc_add_taxonomy',
                             'bin/bc_clean_shrapnel',
                             'bin/bc_convert_files',
                             'bin/bc_convert_ids',
                             'bin/bc_correct_misassignments',
                             'bin/bc_get_info',
                             'bin/bc_manage_members',
                             'bin/bc_manage_samples',
                             'bin/bc_measure_alpha',
                             'bin/bc_measure_beta',
                             'bin/bc_rarefy',
                             'bin/bc_relative_to_absolute',
                             'bin/bc_remove_unexpected_members',
                             'bin/bc_summarize',
                            ],
    recursive_test_files => 1,
    dynamic_config       => 1,
);

$build->create_build_script;

exit;
