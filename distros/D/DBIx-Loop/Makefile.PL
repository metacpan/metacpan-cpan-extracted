use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'DBIx::Loop',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/DBIx/Loop.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Loop.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    INC              => '-I. -Iinclude',
    OBJECT           => 'Loop$(OBJ_EXT)',   # xs/*.xs are INCLUDE:d into Loop.xs
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More'   => '0',
        'DBD::SQLite'  => '0',
        'IO::Async'    => '0',   # baseline adapter: at least one loop in tests
    },
    PREREQ_PM => {
        'DBI' => '1.600',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Loop-*' },
    # MakeMaker maps Loop.xs -> Loop.c and does not rescan the INCLUDE:
    # fragments or the C headers, so an edit to xs/ or include/ left a stale
    # Loop.c behind and the build silently kept the previous XSUBs. Force the
    # regenerate on an xs/ change and the recompile on a header change.
    depend => {
        'Loop.c'         => join(' ', glob('xs/*.xs')),
        'Loop$(OBJ_EXT)' => join(' ', glob('include/*.h'), glob('xs/*.xs')),
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
