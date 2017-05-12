use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Acme::CPANAuthors::Brazilian',
    AUTHOR        => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM  => 'lib/Acme/CPANAuthors/Brazilian.pm',
    ABSTRACT_FROM => 'lib/Acme/CPANAuthors/Brazilian.pm',
    PREREQ_PM => {
        'Acme::CPANAuthors' => 0,
        'Test::More'        => 0.47,
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.31
        ? ( LICENSE => 'perl' )
        : ()
    ),
    ($ExtUtils::MakeMaker::VERSION >= 6.48
        ? ( MIN_PERL_VERSION => '5.8.0' )
        : ()
    ),
    META_MERGE      => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/garu/Acme-CPANAuthors-Brazilian/issues',
            repository  => 'https://github.com/garu/Acme-CPANAuthors-Brazilian',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-CPANAuthors-Brazilian-*' },
);
