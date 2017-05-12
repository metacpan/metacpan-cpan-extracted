# File:		Makefile.PL
# Author:	Daniel Hagerty, hag@linnaean.org
# Date:		Mon Jul  5 18:21:08 1999
# Description:	Makefile for BSD::Itimer
#
# Copyright (c) 1999 Daniel Hagerty. All rights reserved. This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.
#
# $Id: Makefile.PL,v 1.2 1999/07/28 02:27:34 hag Exp $

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'BSD::Itimer',
    'VERSION_FROM' => 'Itimer.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm'
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING'
    'INC'	=> '',     # e.g., '-I/usr/include/other'

    'dist'    => {
		    COMPRESS => 'gzip -9f',
		    SUFFIX   => '.gz',
		    DIST_DEFAULT => 'all tardist',
		 },
);
