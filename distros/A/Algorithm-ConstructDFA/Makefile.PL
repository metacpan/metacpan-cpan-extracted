use 5.012000;
use ExtUtils::MakeMaker;

WriteMakefile(
  MIN_PERL_VERSION  => 5.012000,
  NAME              => 'Algorithm::ConstructDFA',
  VERSION_FROM      => 'lib/Algorithm/ConstructDFA.pm',
  PREREQ_PM         => {
    'Test::More'         =>  0,
    'Data::AutoBimap'    =>  0,
    'Storable'           =>  0,
    'Memoize'            =>  0,
    'List::UtilsBy'      =>  0,
    'List::MoreUtils'    =>  0,
    # TODO: put these into TEST_REQUIRES some day. 
    'Graph::RandomPath'  =>  0,
    'Graph::Directed'    =>  0,
  },
#  TEST_REQUIRES     => {
#  },
  ABSTRACT_FROM     => 'lib/Algorithm/ConstructDFA.pm',
  AUTHOR            => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>',
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
         url  => 'https://github.com/hoehrmann/Algorithm-ConstructDFA.git',
         web  => 'https://github.com/hoehrmann/Algorithm-ConstructDFA',
      },
    },
  },
);
