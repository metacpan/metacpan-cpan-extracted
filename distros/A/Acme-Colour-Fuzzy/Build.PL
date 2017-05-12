#!/usr/bin/perl -w

use strict;

use Module::Build;

my $build = Module::Build->new
  ( module_name        => 'Acme::Colour::Fuzzy',
    license            => 'perl',
    dist_author        => 'Mattia Barbon <mbarbon@cpan.org>',
    requires           => { 'perl'                        => '5.6.0',
                            'Module::Build'               => '0.2607',
                            'Test::More'                  => '0.48',
                            'Color::Similarity'           => '0.01',
                            'Color::Similarity::HCL'      => '0.03',
                            'Class::Accessor'             => '0.30',
                            'Graphics::ColorNames::VACCC' => '1.00',
                            'Graphics::ColorNames'        => '1.00',
                            'List::Util'                  => '0.01',
                            },
    create_makefile_pl => 'passthrough',
    );
$build->create_build_script;
