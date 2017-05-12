# This -*-perl-*- script writes the Makefile for installing this distribution.
#
# See "perldoc perlmodinstall" or "perldoc ExtUtils::MakeMaker" for
# info on how to control how the installation goes.
#
#                                       Time-stamp: "2004-12-29 20:21:08 AST"

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Array::Autojoin',
    'VERSION_FROM' => 'lib/Array/Autojoin.pm', # finds $VERSION
    'dist'        => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);
