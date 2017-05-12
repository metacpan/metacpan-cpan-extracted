#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Bundle::WWW::Scraper::ISBN::Drivers',
    VERSION_FROM        => 'lib/Bundle/WWW/Scraper/ISBN/Drivers.pm',
    ABSTRACT            => 'A bundle for WWW::Scraper::ISBN drivers',
    NO_META             => 1,
    PREREQ_PM           => {

        # build/test prereqs
        'IO::File'                      => '0',
        'Test::More'                    => '0.70'

    }
);
