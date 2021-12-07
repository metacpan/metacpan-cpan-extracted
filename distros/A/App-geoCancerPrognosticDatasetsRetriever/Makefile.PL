use strict;
use warnings;

use 5.008000;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::geoCancerPrognosticDatasetsRetriever',
  VERSION_FROM     => 'lib/App/geoCancerPrognosticDatasetsRetriever.pm',
  ABSTRACT_FROM    => 'lib/App/geoCancerPrognosticDatasetsRetriever.pm',
  AUTHOR           => 'Abbas Alameer',
  LICENSE          => 'gpl_2',
  MIN_PERL_VERSION => '5.008000',
  EXE_FILES        => ['bin/geoCancerPrognosticDatasetsRetriever'],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'Term::ANSIColor' => 0,
    'Getopt::Std' => 0,
    'LWP::Simple' => 0,
    'File::Basename' => 0,
    'File::HomeDir' => 0
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/AbbasAlameer/geoCancerPrognosticDatasetsRetriever.git',
              web  => 'https://github.com/AbbasAlameer/geoCancerPrognosticDatasetsRetriever',
          },
      }})
   : ()
  ),
);
