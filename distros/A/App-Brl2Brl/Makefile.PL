use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::Brl2Brl',
  VERSION_FROM     => 'lib/App/Brl2Brl.pm',
  ABSTRACT_FROM    => 'lib/App/Brl2Brl.pm',
  AUTHOR           => 'Lars Bjørndal',
  LICENSE          => 'Artistic',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => ['script/brl2brl'],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'utf8' => 0,
    'open' => 0,
    'Getopt::Long' => 0,
  },
 );
