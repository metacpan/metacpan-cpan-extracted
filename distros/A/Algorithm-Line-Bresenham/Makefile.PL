use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Algorithm::Line::Bresenham',
  VERSION_FROM     => 'lib/Algorithm/Line/Bresenham.pm',
  ABSTRACT_FROM    => 'lib/Algorithm/Line/Bresenham.pm',
  AUTHOR           => 'Saif Ahmed',
  LICENSE          => 'Artistic',
  MIN_PERL_VERSION => '5.008004',
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/saiftynet/Algorithm-Line-Bresenham.git',
              web  => 'https://github.com/saiftynet/Algorithm-Line-Bresenham',
          },
      }})
   : ()
  ),
);
