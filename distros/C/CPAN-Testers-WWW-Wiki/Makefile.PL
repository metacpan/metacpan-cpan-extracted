#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::WWW::Wiki',
    VERSION_FROM        => 'lib/CPAN/Testers/WWW/Wiki.pm',
    ABSTRACT            => 'The CPAN Testers Wiki website',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Labyrinth'                         => '5.32',
        'Labyrinth::DIUtils::ImageMagick'   => '5.04',
        'Labyrinth::Plugin::Core'           => '5.19',
        'Labyrinth::Plugin::CPAN'           => '3.55',
        'Labyrinth::Plugin::Wiki'           => '1.04',

        # build/test prereqs
        'IO::File'                          => '0',
        'Test::More'                        => '0.70'

    }
);
