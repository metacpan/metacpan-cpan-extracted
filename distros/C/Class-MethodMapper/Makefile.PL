#!/usr/bin/perl
# -*- Mode: perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(
   MAKEFILE     => 'Makefile',
   VERSION_FROM => 'lib/Class/MethodMapper.pm',
   NAME         => 'Class::MethodMapper',  
   dist         => {
      COMPRESS =>'gzip',
      SUFFIX   =>'gz'
   },
   PREREQ_PM => {
      'Data::Dumper' => 0,
   },
);

