use 5.012000;
use ExtUtils::MakeMaker;
use Config;

my %options = (
  MIN_PERL_VERSION  => 5.012000,
  NAME              => 'Algorithm::ConstructDFA::XS',
  VERSION_FROM      => 'lib/Algorithm/ConstructDFA/XS.pm',
  PREREQ_PM         => {
    'Config'             =>  0,
    'Test::More'         =>  0,
    'Data::AutoBimap'    =>  0,
    'Storable'           =>  0,
    'Memoize'            =>  0,
    'List::UtilsBy'      =>  0,
    'List::MoreUtils'    =>  0,
    # TODO: put these into TEST_REQUIRES some day. 
    'Graph::RandomPath'  =>  0,
    'Graph::Directed'    =>  0,
    'Algorithm::ConstructDFA' => 0,
  },
  ABSTRACT_FROM  => 'lib/Algorithm/ConstructDFA/XS.pm',
  AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>',
  LIBS              => [''], # e.g., '-lm'
  DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
  INC               => '', # e.g., '-I/usr/include/other'
  XSOPT             => '-C++',
  OBJECT            => '$(O_FILES)',
  LICENSE           => 'perl',
  'dist'            => {
    PREOP     => 'chmod 600 Makefile.PL',
    TARFLAGS	=> '--group=none --owner=bjoern --mode=a+rw -cvf',
    COMPRESS  => 'gzip -9',
  },

  META_MERGE        => {
    'meta-spec' => { version => 2 },
    resources => {
       repository => {
         type => 'git',
         url  => 'https://github.com/hoehrmann/Algorithm-ConstructDFA-XS.git',
         web  => 'https://github.com/hoehrmann/Algorithm-ConstructDFA-XS',
      },
    },
  },
);

if ($^O eq "MSWin32" and $Config{'cc'} eq 'cl')
{
  $options{CC}   = "cl -TP -EHsc";
  $options{LIBS} = "-lMSVCPRT";

} else {
  # assume some compatible Linux
  $options{LD}   = "g++ -gdwarf-2";
  $options{CC}   = "g++ -std=c++0x -gdwarf-2";
  $options{LIBS} = "-lstdc++";
}

WriteMakefile(%options);
