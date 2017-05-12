#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'AnyEvent::Kanye',
    VERSION_FROM => 'lib/AnyEvent/Kanye.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    PREREQ_PM    => {
		'AnyEvent' => 0,
		'Lingua::EN::Inflect' => 0,
		'Test::More' => 0,
		'Test::use::ok' => 0,
    },
);
