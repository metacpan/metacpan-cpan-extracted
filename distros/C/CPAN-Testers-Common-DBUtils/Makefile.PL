#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'CPAN::Testers::Common::DBUtils',
    VERSION_FROM        => 'lib/CPAN/Testers/Common/DBUtils.pm',
    ABSTRACT            => 'Basic Database Wrapper used by CPAN Testers modules',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'Class::Accessor::Fast' => 0,
        'Carp'                  => 0,
        'DBI'                   => 0,

        # build/test prereqs
        'IO::File'              => '0',
        'Test::More'            => '0.70',

    }
);
