
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'DBICx-DataDictionary',
  NAME      => 'DBICx::DataDictionary',
  AUTHOR    => "Pedro\ Melo\ \<melo\@cpan\.org\>",
  ABSTRACT  => "Define\ a\ data\ dictionary\ to\ use\ with\ your\ DBIx\:\:Class\ Schema",
  VERSION   => '0.002',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0.92',
    "parent" => '0',
    "DBIx::Class" => '0',
    "Test::Deep" => '0',
  },
  test => {TESTS => 't/*.t'}
);

