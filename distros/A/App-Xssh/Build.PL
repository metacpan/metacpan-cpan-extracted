#! /usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new (
     module_name => 'App::Xssh',
     dist_author => 'Evan Giles <egiles@cpan.org>',
     license  => 'perl',
     requires => {
        'perl'               => '5.6.1',
        'X11::Terminal'      => 0.2,
        'Config::General'    => 2.4,
        'Getopt::Long'       => 2.37,
        'Moose'              => 1.09,
        'Pod::Usage'         => 1.35,
        'UNIVERSAL::require' => 0,
     },
     create_makefile_pl => 'traditional',
     configure_requires => {
        'Module::Build' => 0.38,
        'version' => 0
     },
     meta_merge     => {
       resources => {
         repository => "http://github.com/egiles/app-xssh",
       }
     },
     add_to_cleanup => [ 'Makefile.PL', 'META.yml' ],
);
$build->create_build_script;
