use ExtUtils::MakeMaker;
#
# Last Update:		$Author: marvin $
# Update Date:		$Date: 2007/12/13 15:06:46 $
# Source File:		$Source: /home/cvsroot/tools/FileSystem/Makefile.PL,v $
# CVS/RCS Revision:	$Revision: 1.2 $
# Status:		$State: Exp $
# 
# CVS/RCS Log:
# $Log: Makefile.PL,v $
# Revision 1.2  2007/12/13 15:06:46  marvin
# - using multiple 'use constant' instead of single one to be
#   compatible with older perls
# - added missing requirement "Test::Simple" to Makefile.PL
#
# Revision 1.1.1.1  2003/04/09 11:07:10  marvin
# Imported Sources
#
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DBIx::FileSystem',
    'VERSION_FROM' => 'FileSystem.pm', # finds $VERSION
    'PREREQ_PM'    => { 
			 'DBI' => 1,
			 'Test::Simple' => 0.47,
		      },

);
