#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Archive::ByteBoozer2',
  VERSION_FROM => 'lib/Archive/ByteBoozer2.pm',
  PREREQ_PM    => {
                    File::Slurp     => 0,
                    File::Touch     => 0,
                    Test::Exception => 0,
                    Test::More      => 0,
                  },
  ($] >= 5.005 ?
    (AUTHOR    => 'Pawel Krol <djgruby@gmail.com>') : ()),
  DEFINE       => '',
  OBJECT       => 'ByteBoozer2.o cruncher.o file.o',
  OPTIMIZE     => '-O3',
);