#!/usr/bin/perl


use strict;
use ExtUtils::MakeMaker;


my %opts = (
  NAME          => 'DBIx::Wrap',
  VERSION_FROM  => 'Wrap.pm',
  PREREQ_PM     => {
    'DBI'               => 1.30,
  }
);
if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
  $opts{AUTHOR}   = 'Jonathan Waxman <jowaxman@bbl.med.upenn.edu>';
  $opts{ABSTRACT} = 'An object oriented wrapper around DBI.';
}
WriteMakefile (%opts);
