
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'DBIx-InsertHash',
  NAME      => 'DBIx::InsertHash',
  AUTHOR    => 'Uwe\ Voelker\ \<uwe\.voelker\@gmx\.de\>',
  ABSTRACT  => 'insert/update a database record from a hash',
  VERSION   => '0.011',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0',
    "Class::Accessor" => '0',
    "Test::Deep" => '0',
  },
);
