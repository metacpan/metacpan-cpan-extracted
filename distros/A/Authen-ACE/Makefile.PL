# $Id: Makefile.PL,v 1.2 1997/09/18 22:08:37 carrigad Exp $

# Copyright (C), 1997, Interprovincial Pipe Line Inc.

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Authen::ACE',
    'VERSION_FROM' => 'ACE.pm',
    'LIBS'	=> ['-L/ipl/src/Source/commercial/ace -lsdiclient'],
    'DEFINE'	=> '',
    'INC'	=> '-I/ipl/src/Source/commercial/ace',
);
