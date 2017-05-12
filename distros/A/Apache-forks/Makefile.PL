#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval "use Devel::Required";

WriteMakefile (
 NAME		=> 'Apache::forks',
 AUTHOR		=> 'Eric Rybski (rybskej@yahoo.com)',
 ABSTRACT	=> 'Transparent Apache ithreads interface using forks',
 VERSION_FROM	=> 'lib/Apache/forks.pm',
 PREREQ_PM	=> {
  'Devel::Required' => 0.07,
  'forks' => 0.26,
  'mod_perl' => 0,
  'Test::More' => 0,
 },
 (MM->can('signature_target') ? (SIGN => 1) : ()),
);
