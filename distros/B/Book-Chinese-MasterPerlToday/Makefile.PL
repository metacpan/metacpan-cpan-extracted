
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Book-Chinese-MasterPerlToday',
  NAME      => 'Book::Chinese::MasterPerlToday',
  AUTHOR    => 'Fayland\ Lam\ \<fayland\@gmail\.com\>',
  ABSTRACT  => 'free\ book\ in\ Chinese\ \<Master\ Perl\ Today\>',
  VERSION   => '0.02',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'mit') : ()),
  PREREQ_PM    => {

  },
);
