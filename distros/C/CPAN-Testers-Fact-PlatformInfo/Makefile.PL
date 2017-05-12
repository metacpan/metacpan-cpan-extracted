#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::Fact::PlatformInfo',
    VERSION_FROM        => 'lib/CPAN/Testers/Fact/PlatformInfo.pm',
    ABSTRACT            => 'Platform information on which a CPAN Testers smoker is running',
    NO_META             => 1,

    PREREQ_PM           => {

        # prereqs
        'Carp'                  => 0,
        'Metabase::Fact::Hash'  => 0.016,

        # build/test prereqs
        'IO::File'              => 0,
        'Test::More'            => '0.70'

    }
);
