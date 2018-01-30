use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::euro_lotto',
  VERSION_FROM     => 'lib/App/euro_lotto.pm',
  ABSTRACT_FROM    => 'lib/App/euro_lotto.pm',
  AUTHOR           => 'Mike Kelly',
  LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => ['script/euro_lotto'],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'DateTime' => '0.37',
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/mikekellydatrys/euro_lotto.git',
              web  => 'https://github.com/mikekellydatrys/euro_lotto',
          },
      }})
   : ()
  ),
);