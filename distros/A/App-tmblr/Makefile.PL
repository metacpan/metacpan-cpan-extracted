use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::tmblr',
  AUTHOR => q{bie <bie@kyber.io>},
  LICENSE => 'perl',

  VERSION_FROM => 'lib/App/tmblr.pm',
  ABSTRACT => 'a silly tumblr client',

  PREREQ_PM => {
    'CGI' => 0,
    'WWW::Tumblr' => '5.00'
  },
  EXE_FILES => ['bin/tmblr', 'bin/tmblr-rm'],

  META_MERGE => {
    resources => {
      homepage => 'http://kyber.io/tmblr',
      repository => 'http://git.kyber.io/tmblr'
    }
  },

  dist => { COMPRESS => 'gzip', SUFFIX => 'gz' },
  clean => { FILES => 'App-tmblr-*' }
);

