
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'BBDB-Export',
  NAME      => 'BBDB::Export',
  AUTHOR    => 'Alex\ White\ \<VVu\@geekfarm\.org\>',
  ABSTRACT  => 'export\ data\ from\ The\ Insidious\ Big\ Brother\ Database\.',
  VERSION   => '0.015',
  EXE_FILES => [ qw(bin/bbdb-export) ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'bsd') : ()),
  PREREQ_PM    => {
    "Test::More" => '0',
    "Term::ANSIColor" => '0',
    "Data::Dumper" => '0',
    "BBDB" => '0',
    "Text::vFile::asData" => '0',
  },
  test => {TESTS => 't/*.t'}
);

