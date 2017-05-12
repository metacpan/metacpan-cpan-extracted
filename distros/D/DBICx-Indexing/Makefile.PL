
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'DBICx-Indexing',
  NAME      => 'DBICx::Indexing',
  AUTHOR    => "Pedro\ Melo\ \<melo\@cpan\.org\>",
  ABSTRACT  => "Easy\ way\ do\ declare\ extra\ indices\ to\ your\ tables",
  VERSION   => '0.002',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0.92',
    "SQL::Translator" => '0',
    "Test::Exception" => '0',
    "DBIx::Class" => '0',
    "Test::Deep" => '0',
  },
  test => {TESTS => 't/*.t'}
);

