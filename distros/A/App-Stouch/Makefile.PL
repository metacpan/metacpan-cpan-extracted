use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'App::Stouch',
    AUTHOR           => q{Samuel Young <samyoung12788@gmail.com>},
    VERSION_FROM     => 'lib/App/Stouch.pm',
    ABSTRACT_FROM    => 'lib/App/Stouch.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'File::Find' => '0',
        'File::Path' => '0',
        'File::Spec' => '0',
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'File::Path'     => '0',
        'File::Spec'     => '0',
        'Getopt::Long'   => '0',
    },
    EXE_FILES => [
        'bin/stouch',
    ],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                url => 'https://codeberg.org/1-1sam/stouch.git',
                web => 'https://codeberg.org/1-1sam/stouch',
                type => 'git',
            },
            bugtracker => {
                web => 'https://codeberg.org/1-1sam/stouch/issues',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-Stouch-*' },
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
delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };

WriteMakefile(%WriteMakefileArgs);
