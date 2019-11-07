use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'App::bookmarks',
    AUTHOR           => q{jul <kaldor@cpan.com>},
    VERSION_FROM     => 'lib/App/bookmarks.pm',
    ABSTRACT_FROM    => 'lib/App/bookmarks.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    EXE_FILES        => ['script/bookmarks'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Getopt::Std'    => '0',
		'File::Basename' => '0',
		'DBI'            => '0',
		'Config::Any'    => '0',
		'File::Find'     => '0'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-bookmarks-*' },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/kal247/App-bookmarks.git',
                 web  => 'https://github.com/kal247/App-bookmarks',
             },
             bugtracker => {web => 'https://github.com/kal247/App-bookmarks/issues'},
             homepage   => 'https://github.com/kal247/App-bookmarks',
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
