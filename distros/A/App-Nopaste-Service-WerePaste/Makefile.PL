use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::Nopaste::Service::WerePaste',
  AUTHOR           => q{Matthew Connelly <maff@cpan.org>},
  VERSION_FROM     => 'lib/App/Nopaste/Service/WerePaste.pm',
  ABSTRACT_FROM    => 'lib/App/Nopaste/Service/WerePaste.pm',
  LICENSE          => 'mit',
  PL_FILES         => {},
  MIN_PERL_VERSION => 5.006,
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
  },
  BUILD_REQUIRES => {
    'Test::More' => 0.47,
  },
  PREREQ_PM => {
    'App::Nopaste'	=> 0.91,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'App-Nopaste-Service-WerePaste-*' },
);