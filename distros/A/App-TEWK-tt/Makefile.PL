use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::TEWK::tt',
  VERSION_FROM     => 'lib/App/TEWK/tt.pm',
  ABSTRACT_FROM    => 'lib/App/TEWK/tt.pm',
  AUTHOR           => 'Kevin Tew',
  LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.22',
  EXE_FILES        => ['script/tt'],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'DateTime' => '0.37',
    'Modern::Perl' => 0,
    'File::Find::Rule' => 0, 
    'Cwd' => 0,
    'List::MoreUtils' => 0,
    'Term::ANSIColor' => 0,
    'Term::ReadKey' => 0
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/tewk/tt.git',
              web  => 'https://github.com/tewk/tt',
          },
      }})
   : ()
  ),
);
