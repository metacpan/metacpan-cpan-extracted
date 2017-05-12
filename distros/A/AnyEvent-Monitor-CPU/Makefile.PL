
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'AnyEvent-Monitor-CPU',
  NAME      => 'AnyEvent::Monitor::CPU',
  AUTHOR    => "Pedro\ Melo",
  ABSTRACT  => "monitors\ your\ process\ CPU\ usage\,\ with\ high\/low\ watermark\ triggers",
  VERSION   => '0.3',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0.92',
    "AnyEvent" => '5.201',
    "parent" => '0',
    "Test::Exception" => '0',
    "Proc::CPUUsage" => '0',
    "common::sense" => '0',
  },
  test => {TESTS => 't/*.t'}
);

