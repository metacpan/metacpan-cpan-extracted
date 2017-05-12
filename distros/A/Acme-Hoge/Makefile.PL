use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Hoge',
    AUTHOR              => 'Hogeist <mahito@cpan.org>',
    VERSION_FROM        => 'lib/Acme/Hoge.pm',
    ABSTRACT_FROM       => 'lib/Acme/Hoge.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Hoge-*' },
);
