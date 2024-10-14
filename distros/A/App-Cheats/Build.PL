#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $class = Module::Build->subclass(
    code => q{
        use Cwd qw( cwd );

        #---------------------------------
        #            Build
        #---------------------------------

        sub ACTION_build {
            my ($s) = @_;
            $s->_readme();
            $s->SUPER::ACTION_build;
        }

        # Only for the maintainer on "Build build".
        sub _readme {
            my ($s) = @_;
            return if cwd() !~ m{ / git / perlmy / [^/]+ $ }x;

            my ($installed) =
                grep { -x "$_/pod2markdown" }
                split /:/, $ENV{PATH};
            return if !$installed;

            print "Building README\n";
            my $lib = $s->{properties}{dist_version_from};
            system "pod2markdown $lib > README.md";
        }

    },
);

my $builder = $class->new(
    module_name         => 'App::Cheats',
    license             => 'artistic_2',
    dist_author         => q{Tim Potapov <Tim.Potapov[AT]gmail.com>},
    dist_version_from   => 'lib/App/Cheats.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
         'TimTools' => '0.04',
    },
    add_to_cleanup     => [ 'App-Cheats-*' ],
    meta_merge     => {
        resources => {
            bugtracker => 'https://github.com/poti1/app-cheats/issues',
            repository => 'https://github.com/poti1/app-cheats',
        },
    },
);

$builder->create_build_script();
