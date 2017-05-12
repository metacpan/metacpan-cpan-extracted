#!/usr/bin/perl -w

use strict;
use warnings;

use Module::Build;

use 5.008;

my $builder = Module::Build->new(
    module_name => 'Carp::Fix::1_25',
    license     => 'perl',
    dist_author => 'Michael G Schwern <schwern@pobox.com>',

    requires => {
        'perl'                    => '5.8.0',
        'Carp'                    => 0,
    },
    configure_requires => {
        # MB's auto configure requires only puts it in the META.yml
        # so some CPAN shells won't see it.
        "Module::Build"      => '0.36',
    },

    meta_merge => {
        resources => {
            repository  => 'http://github.com/schwern/Carp-Fix-1_25/tree/master',
            bugtracker  => 'http://github.com/schwern/Carp-Fix-1_25/issues',
        },
        no_index => {
            package => [qw(Carp::Fix::1_25::Fixed)],
        }
    },

    recursive_test_files => 1,

    create_readme       => 1,
    create_license      => 1,
);

$builder->create_build_script();
