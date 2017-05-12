#!/usr/bin/perl -w

use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Acme::Dot',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Acme/Dot.pm',
    requires          => {},
    build_requires => {
        'Test::More'      => 0.6,
    },
    add_to_cleanup     => ['Acme-Dot-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
