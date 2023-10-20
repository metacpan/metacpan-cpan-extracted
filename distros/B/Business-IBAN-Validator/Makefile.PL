#! perl -w
use strict;
use 5.008;

use ExtUtils::MakeMaker 6.55_01;

my $testfiles = 't/*.t';
$testfiles = "xt/*.t $testfiles" if $ENV{AUTHOR_TESTING};

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
        'Test::Simple'   => 0.88,    # done_testing()
        'Test::Fatal'    => 0,
        'Test::Warnings' => 0,
    },

    MIN_PERL_VERSION => 5.008,
    META_ADD => {
        'meta-spec' => {
            version => 2,
        },
        license => [ 'perl_5' ],
        'resources' => {
            repository => {
                type => 'git',
                url  => 'https://github.com/abeltje/Business-IBAN-Validator.git',
                web  => 'https://github.com/abeltje/Business-IBAN-Validator',
            },
            bugtracker => {
                web => 'https://github.com/abeltje/Business-IBAN-Validator/issues',
            },
        },
    },

    test => { TESTS => $testfiles },
);
