#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::WWW::Blog',
    VERSION_FROM        => 'lib/CPAN/Testers/WWW/Blog.pm',
    ABSTRACT            => 'The CPAN Testers Blog website',
    NO_META             => 1,
    PREREQ_PM => {

        # prereqs
        'Labyrinth'                             => '5.24',
        'Labyrinth::DIUtils::ImageMagick'       => '5.04',
        'Labyrinth::Plugin::Core'               => '5.15',
        'Labyrinth::Plugin::CPAN'               => '3.55',
        'Labyrinth::Plugin::Articles::Diary'    => '1.05',
        'Labyrinth::Plugin::Event'              => '1.04',

        # for testing
        'IO::File'                              => 0,       # for testing
        'Test::More'                            => 0.70     # for testing

    },
);
