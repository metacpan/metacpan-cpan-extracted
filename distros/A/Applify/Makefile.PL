# Generated by git-ship. See 'git-ship --man' for help or https://github.com/jhthorsen/app-git-ship
use utf8;
use ExtUtils::MakeMaker;
my %WriteMakefileArgs = (
  NAME           => 'Applify',
  AUTHOR         => 'Diab Jerius <djerius@cfa.harvard.edu>',
  LICENSE        => 'artistic_2',
  ABSTRACT_FROM  => 'lib/Applify.pm',
  VERSION_FROM   => 'lib/Applify.pm',
  EXE_FILES      => [qw()],
  OBJECT         => '',
  BUILD_REQUIRES => {}
,
  TEST_REQUIRES  => {
  'Test::More' => '0.88'
}
,
  PREREQ_PM      => {
  'Cwd' => '0',
  'File::Basename' => '0',
  'Getopt::Long' => '0',
  'perl' => '5.014004'
}
,
  META_MERGE     => {
    'dynamic_config' => 0,
    'meta-spec'      => {version => 2},
    'resources'      => {
      bugtracker => {web => 'https://github.com/jhthorsen/applify/issues'},
      homepage   => 'https://github.com/jhthorsen/applify',
      repository => {
        type => 'git',
        url  => 'https://github.com/jhthorsen/applify.git',
        web  => 'https://github.com/jhthorsen/applify',
      },
    },
    'x_contributors' => [
  'Jan Henning Thorsen <jhthorsen@cpan.org>',
  'Roy Storey <kiwiroy@cpan.org>'
]
,
  },
  test => {TESTS => (-e 'META.yml' ? 't/*.t' : 't/*.t xt/*.t')},
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.63_03') }) {
  my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
  @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

WriteMakefile(%WriteMakefileArgs);
