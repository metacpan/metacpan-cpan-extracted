use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Algorithm::DLX',
  VERSION_FROM     => 'lib/Algorithm/DLX.pm',
  ABSTRACT         => "Solve the Exact cover problem with Donald Knuth's DLX Algorithm",
  AUTHOR           => 'James Hammer',
  LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.008004',
  PREREQ_PM        => {
    'strict'   => 1,
    'warnings' => 1,
  },
  test         => {TESTS => 't/*.t'},
  (eval { ExtUtils::MakeMaker->VERSION(7.70) } ? (META_MERGE => {
      'meta-spec' => { version => 0.01 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/jmh0036/perlDLX.git',
              web  => 'https://github.com/jmh0036/perlDLX',
          },
      }})
   : ()
  ),
);
