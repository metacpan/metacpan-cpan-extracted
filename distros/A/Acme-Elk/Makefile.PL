
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Acme-Elk',
  NAME      => 'Acme::Elk',
  AUTHOR    => "Sterling\ Hanenkamp",
  ABSTRACT  => "it\ isn\'t\ Moose",
  VERSION   => '1.001',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Moose" => '0',
  },
  test => {TESTS => 't/*.t'}
);

