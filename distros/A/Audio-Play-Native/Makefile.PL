use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Audio::Play::Native',
    AUTHOR           => ['Matt Johnson <mjohnson@affectivesilicon.com>'],
    VERSION_FROM     => 'lib/Audio/Play/Native.pm',
    ABSTRACT_FROM    => 'lib/Audio/Play/Native.pm',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.008001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'File::Temp' => 0,
    },
    PREREQ_PM => {
        'POSIX' => 0,
        'Carp'  => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Audio-Play-Native-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/mjohnson108/p5-Audio-Play-Native.git',
                 web  => 'https://github.com/mjohnson108/p5-Audio-Play-Native',
             },
             bugtracker => {
                 web => 'https://github.com/mjohnson108/p5-Audio-Play-Native/issues'
             },
             homepage   => 'https://github.com/mjohnson108/',
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
