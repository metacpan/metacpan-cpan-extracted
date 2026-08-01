use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'App::plx',
  VERSION_FROM => 'bin/plx',
  MIN_PERL_VERSION => '5.010',
  PREREQ_PM => {
    'local::lib' => 2,
    'File::Which' => 0,
  },
  EXE_FILES => [ 'bin/plx', 'bin/plx-packed' ],
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      bugtracker => {
        web => 'https://github.com/NicholasBHubbard/plx/issues',
      },
      repository => {
        type => 'git',
        url => 'https://github.com/NicholasBHubbard/plx.git',
        web => 'https://github.com/NicholasBHubbard/plx',
      },
    },
  },
);
