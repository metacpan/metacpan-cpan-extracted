
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Catalyst-View-JavaScript',
  NAME      => 'Catalyst::View::JavaScript',
  AUTHOR    => "Moritz\ Onken\ \<onken\@netcubed\.de\>",
  ABSTRACT  => "Cache\ and\/or\ compress\ JavaScript\ output",
  VERSION   => '0.995',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'bsd') : ()),
  PREREQ_PM    => {
    "JavaScript::Minifier::XS" => '0',
    "Catalyst::Runtime" => '0',
    "Test::WWW::Mechanize::Catalyst" => '0',
    "MRO::Compat" => '0',
  },
  test => {TESTS => 't/*.t'}
);

