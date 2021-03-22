use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

use 5.008000;

(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'App::opan',
  VERSION_FROM => 'script/opan',
  EXE_FILES => [
    'script/opan'
  ],
  PREREQ_PM => {
    'Dist::Metadata' => '0.926',
    'Mojolicious' => '9.11',
    strictures => 2,
    'List::UtilsBy' => '0.09',
    'Import::Into' => '1.002004',
    'File::Open' => '1.0001',
    'IPC::System::Simple' => '1.21',
    'Test::More' => '0.88',
    'File::chdir' => '0.1010',
    'Capture::Tiny' => '0.27',
  },
);
