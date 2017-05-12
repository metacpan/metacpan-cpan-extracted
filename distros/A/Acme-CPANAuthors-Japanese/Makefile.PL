use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME          => 'Acme::CPANAuthors::Japanese',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Acme/CPANAuthors/Japanese.pm',
    ABSTRACT_FROM => 'lib/Acme/CPANAuthors/Japanese.pm',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/charsbar/acme-cpanauthors-japanese',
        },
    },
);
