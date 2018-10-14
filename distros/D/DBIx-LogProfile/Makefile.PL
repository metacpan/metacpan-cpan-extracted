use 5.018;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'DBIx::LogProfile',
  VERSION_FROM      => 'lib/DBIx/LogProfile.pm', # finds $VERSION
  PREREQ_PM         => {
  },
  TEST_REQUIRES       => {
    'Test::More'      => 0,
    'Log::Any'        => '1.050',
    'Sub::Util'       => '1.40',
    'DBI::Profile'    => 0,
  },
  ($] >= 5.005 ?     
    (ABSTRACT_FROM  => 'lib/DBIx/LogProfile.pm', # retrieve abstract from module
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
         url  => 'https://github.com/hoehrmann/DBIx-LogProfile.git',
         web  => 'https://github.com/hoehrmann/DBIx-LogProfile',
      },
    },
  },
);

