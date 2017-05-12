
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'CatalystX-MooseComponent',
  NAME      => 'CatalystX::MooseComponent',
  AUTHOR    => 'Hans\ Dieter\ Pearcey\ \<hdp\@cpan\.org\>',
  ABSTRACT  => 'Ensure your Catalyst component isa Moose::Object',
  VERSION   => '0.004',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Catalyst::Runtime" => '0',
    "Moose" => '0.70',
  },
);
