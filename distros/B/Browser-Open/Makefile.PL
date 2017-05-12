
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Browser-Open',
  NAME      => 'Browser::Open',
  AUTHOR    => "Pedro\ Melo\ \<melo\@cpan\.org\>",
  ABSTRACT  => "open\ a\ browser\ in\ a\ given\ URL",
  VERSION   => '0.04',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0.92',
    "parent" => '0',
  },
  test => {TESTS => 't/*.t'}
);

