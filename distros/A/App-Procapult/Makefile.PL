use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'App::Procapult',
  VERSION_FROM => 'lib/App/Procapult.pm',
  PREREQ_PM => {
    Moo => 2,
    strictures => 2,
    'IO::Async' => '0.70',
    Future => '0.33',
    curry => 1,
    'Object::Tap' => 1,
    'MooX::Options' => 4,
    'String::ShellQuote' => 1,
  },
  EXE_FILES => [ 'bin/procapult' ],
);
