#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'AWS-Signature4',
    license           => 'perl',
    dist_version_from => 'lib/AWS/Signature4.pm',
    dist_author       => 'Lincoln Stein <lincoln.stein@gmail.com>',
    configure_requires => { 'Module::Build' => 0.4205 },
    requires          => {
      'LWP'          => 5.835,
      'Digest::SHA'  => '5.47',
      'URI'          => 1.59,
      'URI::QueryParam' => 0,
      'Date::Parse'  => 0,
    },
    build_class        => 'Module::Build',
    );


$build->create_build_script;
exit 0;
