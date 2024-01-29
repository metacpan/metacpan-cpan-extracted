use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::lapidary',
  VERSION_FROM     => 'lib/App/lapidary.pm',
  ABSTRACT_FROM    => 'lib/App/lapidary.pm',
  AUTHOR           => 'Samuel Bloomfield',
  LICENSE          => 'GPL_3',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => ['script/lapidary'],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'Getopt::Long' => 0,
    'List::MoreUtils' => 0,
    'FindBin' => 0,
    'File::Basename' => 0,
    'File::Spec::Functions' => 0,
    'LWP::Simple' => 0,
    'Archive::Extract' => 0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/samuelbloomfield/Lapidary.git',
              web  => 'https://github.com/samuelbloomfield/Lapidary',
          },
      }})
   : ()
  ),
);
