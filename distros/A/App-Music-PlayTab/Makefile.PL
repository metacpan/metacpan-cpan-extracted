# Makefile.PL -- Makefile for App::Music::PlayTab
# Author          : Johan Vromans
# Created On      : Mon Feb  8 11:46:56 1999
# Last Modified By: Johan Vromans
# Last Modified On: Wed Jan 16 15:47:50 2008
# Update Count    : 78
# Status          : Stable

# Verify perl version.
require 5.008;

use ExtUtils::MakeMaker;

my @scripts = qw(playtab);

WriteMakefile
  (
   NAME         => 'App::Music::PlayTab',
   AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
   ABSTRACT	=> 'Print play tabs of songs',
   VERSION_FROM => "lib/App/Music/PlayTab.pm",
   PREREQ_PM	=> { },
   EXE_FILES    => [ map { "script/$_" } @scripts ],
   # *.pm files will be picked up automatically from ./lib
 );
