#! /usr/bin/env perl # -*- perl -*-

# Makefile generator for Data-Find.
# Copyright (C) 2005-2016 Guido Flohr <guido.flohr@cantanea.com>, 
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.use ExtUtils::MakeMaker;

use 5.004;
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME		    => 'Data::Walk',
    VERSION_FROM	=> 'lib/Data/Walk.pm',
    ($] >= 5.005 ?
		(ABSTRACT	=> 'Traverse Perl data structures.',
	 	 AUTHOR		=> 'Guido Flohr <guido.flohr@cantanea.com>',
    ) : (),
    ),
    PREREQ_PM => {
        'Scalar::Util' => 1.38,
    },
    PL_FILES => {},
    LICENSE => 'lgpl',
);

sub MY::postamble {
   	q ( 
all :: Credits ReleaseNotes

# Make search.cpan.org happy but still follow GNU standards:
# (Thanks to Graham Barr for the hint)
ReleaseNotes: NEWS
	cat NEWS >$@

Credits: THANKS
	cat THANKS >$@
	);
}
