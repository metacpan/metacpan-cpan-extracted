use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'App-MyPerl',
  VERSION_FROM => 'lib/App/MyPerl.pm',
  PREREQ_PM => {
    Moo => '1.000008',
    'IO::All' => '0.46',
    'lib::with::preamble' => '0.001',
    'File::Which' => '1.09',
    'Module::Runtime' => '0.013',
  },
  EXE_FILES => [ 'bin/myperl', 'bin/myprove', 'bin/myperl-rewrite' ],
);
