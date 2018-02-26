use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::ForKids::LogicalPuzzleGenerator',
    AUTHOR           => q{Pawel Biernacki <pawel.f.biernacki@gmail>},
    VERSION_FROM     => 'lib/App/ForKids/LogicalPuzzleGenerator.pm',
    ABSTRACT_FROM    => 'lib/App/ForKids/LogicalPuzzleGenerator.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'				=> 1.36,
        'AI::Prolog'		=> 0.741,
        'Capture::Tiny'		=> 0.25
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-ForKids-LogicalPuzzleGenerator-*' },
);
