
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Apache-Mojo',
  NAME      => 'Apache::Mojo',
  AUTHOR    => 'Dave\ Sherohman\ \<dave\@sherohman\.org\>',
  ABSTRACT  => 'mod_perl handler for Mojo',
  VERSION   => '0.003',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Mojo" => '0',
    "Apache" => '0',
  },
);
