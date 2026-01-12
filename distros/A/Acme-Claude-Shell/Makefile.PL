use 5.020;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Acme::Claude::Shell',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Acme/Claude/Shell.pm',
    ABSTRACT_FROM    => 'lib/Acme/Claude/Shell.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.020',
    EXE_FILES        => ['bin/acme_claude_shell'],
    macro            => { TARFLAGS => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Claude::Agent'         => '0.13',
        'Future::AsyncAwait'    => '0.60',
        'IO::Async'             => '0.80',
        'Marlin'                => '0.007000',
        'Term::ANSIColor'       => '0',
        'Term::ReadLine'        => '0',
        'Term::Choose'          => '0',
        'Term::ProgressSpinner' => '0',
        'Term::ReadKey'         => '0',
        'Types::Standard'       => '2.0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Acme-Claude-Shell-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/Acme-Claude-Shell.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/Acme-Claude-Shell',
            },
        },
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
