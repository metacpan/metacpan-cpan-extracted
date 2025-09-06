use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME                => 'App::GUI::GoLP',
    AUTHOR              => q{Matt Johnson <mjohnson@cpan.org>},
    VERSION_FROM        => 'lib/App/GUI/GoLP.pm',
    ABSTRACT_FROM       => 'lib/App/GUI/GoLP.pm',
    LICENSE             => 'gpl_3',
    MIN_PERL_VERSION    => '5.014',
    EXE_FILES           => ["bin/golp"],
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Prima'                 =>  '1.74',
        'Cairo'                 =>  '1.109',
        'Game::Life::Faster'    =>  '0.007',
        'List::Util'            =>  '0',
        'File::Basename'        =>  '2.85',
        'Feature::Compat::Try'  =>  '0.05',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-GUI-GoLP-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/mjohnson108/p5-App-GUI-GoLP.git',
                 web  => 'https://github.com/mjohnson108/p5-App-GUI-GoLP',
             },
             bugtracker => {
                 web => 'https://github.com/mjohnson108/p5-App-GUI-GoLP/issues'
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
