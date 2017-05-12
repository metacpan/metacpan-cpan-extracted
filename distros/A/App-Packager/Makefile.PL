use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Packager',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/App/Packager.pm',
    ABSTRACT_FROM       => 'lib/App/Packager.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Packager-*' },
);
