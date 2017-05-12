
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'DBIx-Class-BitField',
  NAME      => 'DBIx::Class::BitField',
  AUTHOR    => 'Moritz\ Onken\ \<onken\@netcubed\.de\>',
  ABSTRACT  => 'Store\ multiple\ boolean\ fields\ in\ one\ integer\ field',
  VERSION   => '0.13',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'bsd') : ()),
  PREREQ_PM    => {
    "File::Find::Rule" => '0',
    "Test::More" => '0.92',
    "DBD::SQLite" => '0',
    "DBIx::Class" => '0.08107',
  },
);
