use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::Repo',
    AUTHOR           => q{Zdenek Bohunek <zed448@icloud.com>},
    VERSION_FROM     => 'lib/App/Repo.pm',
    ABSTRACT_FROM    => 'lib/App/Repo.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    'EXE_FILES'      => ['repo'],
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
         'Mojolicious'   =>  '7.01',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-Repo*' },
);
