#
# $Header$
#
# this is based off of code that i based off of other modules i've found in the
# distant past. if you are the original author and you recognize this code let
# me know and you'll be credited
#
# Copyright (C) 2003 by Ross McFarland
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
# 
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the 
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307  USA.
#

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'AI::LibNeural',
	'VERSION_FROM'	=> 'LibNeural.pm',
	'ABSTRACT_FROM'	=> 'LibNeural.pm',
	'LIBS'		=> [ '-lneural' ],
	'TYPEMAPS'	=> [ './typemap' ],
	# this is going to be linked with a c++ lib so special magic is 
	# required. MakeMaker will complain that it doesn't know anything
	# about CC, and LD, but appearently it does
	'CC'		=> 'g++',
	'LD'		=> '$(CC)',
	'XSOPT'		=> '-C++',
);
