#! perl -w
use strict;
use 5.008;

use ExtUtils::MakeMaker 6.55_01;

WriteMakefile(
    NAME          => 'Business::IBAN::Validator',
    VERSION_FROM  => 'lib/Business/IBAN/Validator.pm',
    ABSTRACT_FROM => 'lib/Business/IBAN/Validator.pm',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',

    PREREQ_PM => {
        'Hash::Util' => 0, # It's core, but still...
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.56,
    },

    BUILD_REQUIRES => {
        'Test::More'      => 0.88, # done_testing()
        'Test::Exception' => 0,
    },
);
