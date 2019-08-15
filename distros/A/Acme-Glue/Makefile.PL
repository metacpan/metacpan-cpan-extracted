#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Acme::Glue',
    VERSION_FROM     => 'lib/Acme/Glue.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.10.0',
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Acme::Glue',
            bugtracker => 'https://github.com/leejo/acme-glue/issues',
            repository => 'https://github.com/leejo/acme-glue'
        },
    },
    TEST_REQUIRES => {
        'Test::Pod' => 0,
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
