use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::BR::CEP',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Business/BR/CEP.pm',
    ABSTRACT_FROM       => 'lib/Business/BR/CEP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'parent'     => 0,
        'Test::More' => '0.88',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-BR-CEP-*' },
);
