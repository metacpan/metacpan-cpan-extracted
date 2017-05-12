use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'App::Environ',
  VERSION_FROM  => 'lib/App/Environ.pm',
  MIN_PERL_VERSION => '5.008000',
  PREREQ_PM => {
    'Config::Processor' => '0.10',
    'Carp'              => '0',
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 6.64,
  },
  BUILD_REQUIRES => {
    'Test::More'        => 0.98,
  },
  ABSTRACT_FROM => 'lib/App/Environ.pm',
  AUTHOR        => 'Eugene Ponizovsky <ponizovsky@gmail.com>',
  LICENSE       => 'perl',
);
