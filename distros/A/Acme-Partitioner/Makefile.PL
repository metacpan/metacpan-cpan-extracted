use 5.012000;
use ExtUtils::MakeMaker;
use Config;

my %options = (
  MIN_PERL_VERSION  => 5.012000,
  NAME              => 'Acme::Partitioner',
  VERSION_FROM      => 'lib/Acme/Partitioner.pm',
  PREREQ_PM         => {
    'Test::More'         =>  0,
    'List::Util'         =>  0,
  },
  ABSTRACT_FROM  => 'lib/Acme/Partitioner.pm',
  AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>',
  LIBS              => [''], # e.g., '-lm'
  DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
  INC               => '', # e.g., '-I/usr/include/other'
  XSOPT             => '',
  OBJECT            => '',
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
         url  => 'https://github.com/hoehrmann/Acme-Partitioner.git',
         web  => 'https://github.com/hoehrmann/Acme-Partitioner',
      },
    },
  },
);

WriteMakefile(%options);
