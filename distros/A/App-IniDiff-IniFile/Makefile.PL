use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'App::IniDiff::IniFile',
    AUTHOR           => [
      q{Michael Rendell, Memorial University of Newfoundland},
      q{Jeremy Squires <j.squires@computer.org> (Current Maintainer)},
    ],
    VERSION_FROM     => 'lib/App/IniDiff/IniFile.pm',
    ABSTRACT         => 'App::IniDiff, scripts to diff and patch INI files',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.006',
    EXE_FILES => [ 
      'bin/inicat',
      'bin/inidiff',
      'bin/iniedit',
      'bin/inifilter',
    ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::Pod' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'Test2::Bundle::More' => '0',
        'Test::Cmd' => '0',
        'Cwd' => '0',
        'File::Temp' => '0',
    },
    PREREQ_PM => {
        'Getopt::Std'       => 0,
        'IO::File'          => 0,
        'IO::Handle'        => 0,
        'Carp'              => 0,
    },
    META_MERGE        => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git@github.com:jeremysquires/App-IniDiff.git',
                web => 'https://github.com/jeremysquires/App-IniDiff',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-IniDiff-IniFile-*' },
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
