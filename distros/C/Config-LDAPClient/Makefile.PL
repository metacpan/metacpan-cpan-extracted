#!/usr/bin/perl

use ExtUtils::MakeMaker;
use 5.008;

WriteMakefile(
    NAME            =>  'Config::LDAPClient',
    VERSION_FROM    =>  'lib/Config/LDAPClient.pm',
    AUTHOR          =>  'Michael Fowler <mfowler@cpan.org>',
    ABSTRACT_FROM   =>  'lib/Config/LDAPClient.pm',

    PREREQ_PM => {
        Moose                       =>  0,
        'MooseX::AttributeHelpers'  =>  0,
    },
);
