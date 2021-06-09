use 5.008004;
use ExtUtils::MakeMaker;

my @scripts;
foreach (`ls script`) {
    chomp;
    push( @scripts, "script/$_" );
}


WriteMakefile(
  NAME             => 'App::zoo',
  VERSION_FROM     => 'lib/App/zoo.pm',
  ABSTRACT_FROM    => 'lib/App/zoo.pm',
  AUTHOR           => 'GaoangLau',
  LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => [@scripts],
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
              url  => 'https://github.com/117v2/cfwp.git',
              web  => 'https://github.com/117v2/cfwp',
          },
      }})
   : ()
  ),
);
