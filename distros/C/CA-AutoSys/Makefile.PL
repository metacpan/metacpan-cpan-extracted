#
# $Id: Makefile.PL 59 2007-10-29 17:41:06Z sini $
#
# CA::AutoSys - Perl Interface to CA's AutoSys job control.
# Copyright (c) 2007 Sinisa Susnjar <sini@cpan.org>
# See LICENSE for terms of distribution.
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'CA::AutoSys',
	VERSION_FROM	=> 'lib/CA/AutoSys.pm',
	EXE_FILES		=> [ 'bin/autorep', 'bin/sendevent' ],
	PREREQ_PM		=> { 'DBI' },
	($] >= 5.005 ?
		(ABSTRACT_FROM	=> 'lib/CA/AutoSys.pm',
		 AUTHOR			=> 'Sinisa Susnjar (sini@cpan.org)') : ())
);
