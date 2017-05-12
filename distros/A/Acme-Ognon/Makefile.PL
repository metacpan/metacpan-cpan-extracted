#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Acme::Ognon',
    VERSION_FROM     => 'lib/Acme/Ognon.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.6.2',
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Acme::Ognon',
            bugtracker => 'https://github.com/leejo/acme-ognon/issues',
            repository => 'https://github.com/leejo/acme-ognon'
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
