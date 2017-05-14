#####################################################################
# Makefile.PL 
# Copyright (c) 1999, 2000 by Markus Winand       <mws@fatalmind.com>
#
# Script to generate a Makefile for the CONFIG:: packages 
#
# $Id: Makefile.PL,v 1.4 2000/04/24 08:36:08 mws Exp $
#

use ExtUtils::MakeMaker;
WriteMakefile( 'NAME' => "CONFIG::Plain", 
		'PM'   => {'Plain.pm' => '$(INST_LIBDIR)/Plain.pm',
		           'Hash.pm'  => '$(INST_LIBDIR)/Hash.pm'}
	       );
