
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'DBIx-Class-ResultSet-Void',
  NAME      => 'DBIx::Class::ResultSet::Void',
  AUTHOR    => 'Fayland\ Lam\ \<fayland\@gmail\.com\>',
  ABSTRACT  => 'improve DBIx::Class::ResultSet with void context',
  VERSION   => '0.06',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "DBIx::Class" => '0.08100',
  },
);
