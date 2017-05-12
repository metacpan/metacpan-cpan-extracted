
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Catalyst-Authentication-Store-FromSub',
  NAME      => 'Catalyst::Authentication::Store::FromSub',
  AUTHOR    => 'Fayland\ Lam\ \<fayland\@gmail\.com\>',
  ABSTRACT  => 'A\ storage\ class\ for\ Catalyst\ Authentication\ using\ one\ Catalyst\ Model\ class',
  VERSION   => '0.01',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Catalyst::Plugin::Authentication" => '0.10015',
    "Catalyst" => '0',
  },
  test => {TESTS => 't/*.t t/hash/*.t t/object/*.t'}
);

