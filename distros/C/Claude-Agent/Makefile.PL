use 5.020;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Claude::Agent',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Claude/Agent.pm',
    ABSTRACT         => 'Perl SDK for the Claude Agent SDK',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.020',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More'      => '0.98',
        'Test::Exception' => '0.43',
        'Test::Deep'      => '1.0',
    },
    PREREQ_PM => {
        'Marlin'             => '0.007000',
        'JSON::Lines'        => '1.10',
        'IO::Async'          => '0.80',
        'Future::AsyncAwait' => '0.60',
        'Type::Tiny'         => '2.0',
        'Types::Common'      => '2.0',
        'Try::Tiny'          => '0.30',
        'File::Which'        => '1.27',
        'Const::XS'          => '1.03',
        'namespace::clean'   => '0.27',
        'Crypt::URandom'     => '0.54',
        'Log::Any'           => '1.710',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/lnation/Claude-Agent.git',
                web  => 'https://github.com/lnation/Claude-Agent',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Claude-Agent-*' },
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
