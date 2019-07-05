#!/usr/bin/env perl
use 5.10.1;
use warnings;
use strict;
use ExtUtils::MakeMaker 6.64;
use Alien::Build::MM;
 
my $abmm = Alien::Build::MM->new;
 
WriteMakefile($abmm->mm_args(

  ABSTRACT => 'Build and install Swiss Ephemeris shared library',
  DISTNAME => 'Alien-libswe',
  NAME     => 'Alien::libswe',
  VERSION_FROM => 'lib/Alien/libswe.pm',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 6.64,
    'Alien::Build::MM' => 0,
  },
  PREREQ_PM => {
    'Alien::Base' => 0,
    'parent' => 0,
    'Sort::Versions' => 1.62,
  },
  TEST_REQUIRES => {
    'Test::More' => 0.88,
    'Test2::V0' => 0,
    'Test::Alien' => 0,
  },

));
 
sub MY::postamble {
  $abmm->mm_postamble;
}
