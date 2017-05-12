# This -*-perl-*- script writes the Makefile for installing this distribution.
#
# See "perldoc perlmodinstall" or "perldoc ExtUtils::MakeMaker" for
# info on how to control how the installation goes.
#
#                                       Time-stamp: "2004-12-29 20:20:52 AST"

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Class::ISA',
    'VERSION_FROM' => 'lib/Class/ISA.pm', # finds $VERSION
    'PREREQ_PM' => {
      'if' => '0',
    },
    'dist'        => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
    'INSTALLDIRS' => ((($] >= 5.007003) && ($] < 5.011)) ? 'perl' : 'site'),
);
