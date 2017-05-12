#!perl
#
# This file is part of Acme::MetaSyntactic::buzzwords.
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new (
    module_name         => 'Acme::MetaSyntactic::buzzwords',
    dist_author         => 'Jerome Quelin <jquelin@cpan.org>',
    license             => 'perl',
    dist_version_from   => 'lib/Acme/MetaSyntactic/buzzwords.pm',
    add_to_cleanup => [
        'Acme-MetaSyntactic-buzzwords-*', 'MANIFEST.bak',
        map { ( '*/' x $_ ) . '*~' } 0..5 ],
    script_files   => [ ],
    build_requires => {
        'Acme::MetaSyntactic' => 0,
        'Test::More'          => 0,
    },
    requires       => {
        'Acme::MetaSyntactic' => 0,
    },
    recommends     => {
        'Test::Kwalitee'      => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
    },
);

$builder->create_build_script();
