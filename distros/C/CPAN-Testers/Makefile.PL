#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Adam J. Foxson <afoxson@pobox.com>, Barbie <barbie@missbarbell.co.uk>, David Golden <dagolden@cpan.org>',
    NAME                => 'CPAN::Testers',
    VERSION_FROM        => 'lib/CPAN/Testers.pm',
    ABSTRACT	        => 'QA of CPAN distributions via cross-platform testing',
    LICENSE             => 'artistic_2',
    NO_META             => 1,
    PREREQ_PM           => {

        # build/test prereqs
        'Test::More'            => '0.70',
        'IO::File'              => '0'
    }
);

