# Makefile.PL -- Makefile for App::Music::PlayTab
# Author          : Johan Vromans
# Created On      : Mon Feb  8 11:46:56 1999
# Last Modified By: Johan Vromans
# Last Modified On: Wed Apr 12 15:45:48 2017
# Update Count    : 81
# Status          : Stable

# Verify perl version.
require 5.008;

use ExtUtils::MakeMaker;

my @scripts = qw(playtab);

WriteMakefile
  (
   NAME         => 'App::Music::PlayTab',
   AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
   ABSTRACT	=> 'Print play tabs (griles, grids) of songs',
   VERSION_FROM => "lib/App/Music/PlayTab.pm",
   PREREQ_PM	=> {
   		     Clone => 0,
   		     App::Packager => 1.420,
		   },
   EXE_FILES    => [ map { "script/$_" } @scripts ],
 );
