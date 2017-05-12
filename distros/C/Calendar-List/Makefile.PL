#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Calendar::List',
    VERSION_FROM        => 'lib/Calendar/List.pm',
    ABSTRACT            => 'A module for creating date lists',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
		'Clone'             => '0',
		'Tie::IxHash'	    => '0',
		'Time::Local'	    => '0',

        # build/test prereqs
        'Test::More'        => '0.70',
        'IO::File'          => '0'

    }
);
