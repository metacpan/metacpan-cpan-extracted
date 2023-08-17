use strict;
use warnings;
use ExtUtils::MakeMaker 6.48;

my %options = (
    NAME                => 'CPE',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/CPE.pm',
    ABSTRACT_FROM       => 'lib/CPE.pm',
    MIN_PERL_VERSION => 5.010000,
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Carp'            => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/CPAN-Security/CPE/issues/',
            repository  => 'https://github.com/CPAN-Security/CPE',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CPE-*' },
);

WriteMakefile( %options );
