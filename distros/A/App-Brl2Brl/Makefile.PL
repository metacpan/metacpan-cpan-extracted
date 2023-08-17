use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;
use utf8;

install_share 'share';

my %WriteMakefileArgs = (
    NAME             => 'App::Brl2Brl',
    AUTHOR           => q{Lars Bjørndal <lars@lamasti.net>},
    VERSION_FROM     => 'lib/App/Brl2Brl.pm',
    ABSTRACT_FROM    => 'lib/App/Brl2Brl.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    EXE_FILES => ['script/brl2brl'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'File::ShareDir::Install' => 0.11,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
      'strict'   => 0,
      'warnings' => 0,
      'utf8' => 0,
      'Exporter' => 0,
      'Carp' => 0,
      'open' => 0,
      'File::ShareDir' => 1.104,
      'Getopt::Long' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-Brl2Brl-*' },
    META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
	repository => {
	  type => 'git',
	  url => 'https://github.com/larsbjorndal/App-Brl2Brl.git',
	  web => 'https://github.com/larsbjorndal/App-Brl2Brl',
	},
	bugtracker => {
	  web => 'https://github.com/larsbjorndal/App-Brl2Brl/issues',
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

package MY;
use File::ShareDir::Install qw(postamble);
