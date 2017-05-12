#!/usr/bin/perl

use ExtUtils::MakeMaker;
use 5.008;

WriteMakefile(
    NAME            =>  'Data::Lua',
    VERSION_FROM    =>  'lib/Data/Lua.pm',
    AUTHOR          =>  'Michael Fowler <mfowler@cpan.org>',
    ABSTRACT_FROM   =>  'lib/Data/Lua.pm',

    PREREQ_PM => {
        'Inline::Lua'       =>  0,
        'Test::NoWarnings'  =>  0,
    },
);
