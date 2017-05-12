#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Data::Password::Meter',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Check the strength of passwords',
  VERSION_FROM => 'lib/Data/Password/Meter.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'strict'       => 0,
    'warnings'     => 0,
    'utf8'         => 0,
    'bytes'        => 0
  },
  LICENSE      => 'mit',
  META_MERGE   => {
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/MIT',
      repository  => 'https://github.com/Akron/Data-Password-Meter'
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {
    TESTS => 't/*.t'
  }
);
