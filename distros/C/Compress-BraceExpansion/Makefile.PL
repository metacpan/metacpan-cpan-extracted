
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Compress-BraceExpansion',
  NAME      => 'Compress::BraceExpansion',
  AUTHOR    => 'Alex\ White\ \<VVu\@geekfarm\.org\>',
  ABSTRACT  => 'create\ a\ human\-readable\ compressed\ string\ suitable\ for\ shell\ brace\ expansion',
  VERSION   => '0.1.7',
  EXE_FILES => [ qw(bin/brace-compress bin/brace-compress-tester.pl bin/trie-compress.pl) ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'bsd') : ()),
  PREREQ_PM    => {
    "Test::More" => '0',
    "Class::Std::Utils" => '0',
    "Data::Dumper" => '0',
  },
  test => {TESTS => 't/*.t'}
);

