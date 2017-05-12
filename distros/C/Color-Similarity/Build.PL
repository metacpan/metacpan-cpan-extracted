#!/usr/bin/perl -w

use strict;

use Module::Build;

my $build = Module::Build->new
  ( module_name        => 'Color::Similarity',
    license            => 'perl',
    dist_author        => 'Mattia Barbon <mbarbon@cpan.org>',
    requires           => { 'perl'                  => '5.6.0',
                            'Module::Build'         => '0.2607',
                            'Test::More'            => '0.48',
                            'Graphics::ColorObject' => '0.5.0',
                            },
    create_makefile_pl => 'passthrough',
    );
$build->create_build_script;
