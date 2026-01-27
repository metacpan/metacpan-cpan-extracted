use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME               => 'Benchmark::MCE',
    AUTHOR             => q{Dimitrios Kechagias <dkechag@cpan.org>},
    VERSION_FROM       => 'lib/Benchmark/MCE.pm',
    ABSTRACT_FROM      => 'lib/Benchmark/MCE.pm',
    LICENSE            => 'perl_5',
    MIN_PERL_VERSION   => '5.10.0',
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => '6.52',
    },
    TEST_REQUIRES => {
        'Test2::V0' => '0',
    },
    PREREQ_PM => {
        'MCE::Loop'    => '0',
        'System::CPU'  => '0',
        'System::Info' => '0.057',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    META_MERGE        => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'git://github.com/SpareRoom/Benchmark-MCE.git',
                web  => 'https://github.com/SpareRoom/Benchmark-MCE',
            },
        },
    },
    clean => {FILES => 'Benchmark-MCE-*'},
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
