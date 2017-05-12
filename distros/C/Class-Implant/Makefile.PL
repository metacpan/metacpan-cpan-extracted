
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Class-Implant',
  NAME      => 'Class::Implant',
  AUTHOR    => 'shelling\ \<shelling\@cpan\.org\>',
  ABSTRACT  => 'Manipulating mixin and inheritance out of packages',
  VERSION   => '0.01',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'mit') : ()),
  PREREQ_PM    => {
    "Class::Inspector" => '0',
  },
);
