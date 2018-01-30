use 5.022;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'Algorithm::ConstructDFA2',
  VERSION_FROM      => 'lib/Algorithm/ConstructDFA2.pm', # finds $VERSION
  PREREQ_PM         => {
    'DBD::SQLite' => '1.5',
    'Types::Standard' => 0,
    'List::UtilsBy' => 0,
    'List::Util' => 0,
    'Moo' => 0,
    'Memoize' => 0,
    'Log::Any' => 0,
    'DBI' => '1.635',
  },
  TEST_REQUIRES       => {
    'Test::More'      => 0,
    'List::UtilsBy'   => 0,
    'List::Util'      => 0,
    'List::MoreUtils' => 0,
    'Graph::Directed' => 0,
    'Graph::Feather'  => 0,
    'YAML::XS'        => 0,
  },
  ($] >= 5.005 ?     
    (ABSTRACT_FROM  => 'lib/Algorithm/ConstructDFA2.pm', # retrieve abstract from module
     AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),

  LICENSE           => 'perl',
  'dist'            => {
    PREOP     => 'chmod 600 Makefile.PL',
    TARFLAGS	=> '--group=none --owner=bjoern --mode=a+rw -cvf',
  },
  META_MERGE        => {
    'meta-spec' => { version => 2 },
    resources => {
       repository => {
         type => 'git',
         url  => 'https://github.com/hoehrmann/Algorithm-ConstructDFA2.git',
         web  => 'https://github.com/hoehrmann/Algorithm-ConstructDFA2',
      },
    },
  },
);

