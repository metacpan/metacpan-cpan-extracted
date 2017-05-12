#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::WWW::Reports::Query::AJAX',
    VERSION_FROM        => 'lib/CPAN/Testers/WWW/Reports/Query/AJAX.pm',
    ABSTRACT            => 'Retrieve distribution stats direct from CPAN Testers website',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'WWW::Mechanize'    => 0,

        # build/test prereqs
        'IO::File'          => '0',
        'Test::More'        => '0.70'

    }
);
