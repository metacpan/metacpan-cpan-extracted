
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'DBIx-Class-Snowflake',
  NAME      => 'DBIx::Class::Snowflake',
  AUTHOR    => 'Matt\ Follett',
  ABSTRACT  => 'Easily use DBIC with snowflake schemas.',
  VERSION   => '0.10',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "DBIx::Class" => 'any',
  },
);
