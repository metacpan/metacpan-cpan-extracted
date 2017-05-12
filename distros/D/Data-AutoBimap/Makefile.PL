use 5.012000;
use ExtUtils::MakeMaker;

WriteMakefile(
  MIN_PERL_VERSION  => 5.012000,
  NAME              => 'Data::AutoBimap',
  VERSION_FROM      => 'lib/Data/AutoBimap.pm',
  PREREQ_PM         => {
    'Test::More'         =>  0,
  },
  ABSTRACT_FROM     => 'lib/Data/AutoBimap.pm',
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
         url  => 'https://github.com/hoehrmann/Data-AutoBimap.git',
         web  => 'https://github.com/hoehrmann/Data-AutoBimap',
      },
    },
  },
);
