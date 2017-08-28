use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::rmspaces',
  VERSION_FROM     => 'lib/App/rmspaces.pm',
  ABSTRACT_FROM    => 'lib/App/rmspaces.pm',
  AUTHOR           => 'Athos Ribeiro',
  LICENSE          => 'gpl_3',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => ['script/rmspaces'],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'File::Copy' => '0',
    'File::Spec' => '3.32',
    'Getopt::Long' => '0',
    'Pod::Usage' => '1.33',
  },
  TEST_REQUIRES    => {
    'Test::Script'   => 1.09,
    'Test::More'   => 0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/athos-ribeiro/rmspaces.git',
              web  => 'https://github.com/athos-ribeiro/rmspaces',
          },
      }})
   : ()
  ),
);

