
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Apache2-Mojo',
  NAME      => 'Apache2::Mojo',
  AUTHOR    => 'Uwe\ Voelker\ \<uwe\.voelker\@gmx\.de\>',
  ABSTRACT  => 'mod_perl2 handler for Mojo',
  VERSION   => '0.004',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Mojo" => '0.9',
    "mod_perl2" => '2.0',
  },
);
