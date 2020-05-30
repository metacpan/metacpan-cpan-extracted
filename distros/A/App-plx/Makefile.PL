use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'App::plx',
  VERSION_FROM => 'bin/plx',
  PREREQ_PM => {
    'local::lib' => 2,
    'File::Which' => 0,
  },
  EXE_FILES => [ 'bin/plx', 'bin/plx-packed' ],
);
