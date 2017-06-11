use 5.008005;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'CHI::Driver::Reddit',
  VERSION_FROM   => 'lib/CHI/Driver/Reddit.pm',
  PREREQ_PM      => { 'Cache::Reddit' => 0, 'CHI' => 0, 'Moo' => 0 },
  ABSTRACT_FROM  => 'lib/CHI/Driver/Reddit.pm',
  AUTHOR         => 'David Farrell',
  LICENSE        => 'FreeBSD',
);
