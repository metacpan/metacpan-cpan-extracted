use strict;
use warnings;
use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
    'NAME'               => 'B::CompilerPhase::Hook',
    'VERSION'            => '0.04',
    'DISTNAME'           => 'B-CompilerPhase-Hook',
    'ABSTRACT'           => 'Programatically install BEGIN/CHECK/INIT/UNITCHECK/END blocks',
    'AUTHOR'             => 'Stevan Little',
    'BUILD_REQUIRES'     => {},
    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker' => '6.30'
    },
    'EXE_FILES'          => [],
    'LICENSE'            => 'perl',
    'NORECURS'           => 1,
    'PREREQ_PM'  => {
        # tests ..
        'Test::More'         => 0,
        # gonna need these later ...
        'XSLoader'          => '0',
    },
    'clean'              => { FILES => 'cover_db/ nytprof/' },
    'test'               => { RECURSIVE_TEST_FILES => 1 },
);

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
