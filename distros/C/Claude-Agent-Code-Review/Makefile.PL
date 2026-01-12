use 5.020;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Claude::Agent::Code::Review',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Claude/Agent/Code/Review.pm',
    ABSTRACT         => 'AI-powered code review using Claude',
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
        'Claude::Agent'      => '0.10',
        'Marlin'             => '0.007000',
        'Cpanel::JSON::XS'   => '4.0',
        'Path::Tiny'         => '0.100',
        'Types::Common'      => '2.0',
        'IO::Async'          => '0.80',
        'Future::AsyncAwait' => '0.60',
    },
    # Optional dependencies for enhanced functionality
    # Perl::Critic - enables perlcritic integration (examples/06-perlcritic.pl, examples/07-perlcritic-only.pl)
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/lnation/Claude-Agent-Code-Review.git',
                web  => 'https://github.com/lnation/Claude-Agent-Code-Review',
            },
        },
        recommends => {
            'Perl::Critic' => '1.140',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Claude-Code-Review-*.tar.gz' },
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
