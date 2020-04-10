use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Async::Methods',
  VERSION_FROM => 'lib/Async/Methods.pm'
);
