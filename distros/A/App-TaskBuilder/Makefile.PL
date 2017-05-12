
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'App-TaskBuilder',
  NAME      => 'App::TaskBuilder',
  AUTHOR    => 'Hans\ Dieter\ Pearcey\ \<hdp\@cpan\.org\>',
  ABSTRACT  => 'build empty, dependency-only distributions',
  VERSION   => '1.000',
  EXE_FILES => [ qw(script/task-builder) ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {

  },
);
