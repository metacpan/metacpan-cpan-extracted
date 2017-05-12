#!/usr/local/bin/perl -sw
# $Id: Makefile.PL,v 1.1 2001/10/13 21:08:47 joe Exp $
#
# Copyright (c) 1997  Thomas K. Wenrich
# portions Copyright (c) 1994,1995,1996  Tim Bunce
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.
#

BEGIN { require 5.003 }	# 5.003 fixes very important bugs
use ExtUtils::MakeMaker 5.16, qw(&WriteMakefile $Verbose);
use strict;
use File::Find;			# for searching Solid files
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts = 
(
    'NAME'	=> 'DBD::Solid::Const',
    'VERSION_FROM' => 'Const.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
     dist  => { DIST_DEFAULT=> 'clean distcheck disttest ci tardist',
                PREOP => '$(MAKE) -f Makefile.old distdir' },
    'OBJECT'    => qw( $(O_FILES) ),
#   'OPTIMIZE'  => '-g -O0',
);
$opts{INC}  = "\$(SOLID_INCLUDE)";
$opts{macro} = {EXTRALIBS => '$(SOLID_LIBRARY)'};
WriteMakefile(%opts);
__END__
