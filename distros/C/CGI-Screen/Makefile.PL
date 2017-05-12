#                              -*- Mode: Perl -*- 
# $Basename: Makefile.PL $
# $Revision: 1.7 $
# Author          : Ulrich Pfeifer
# Created On      : Tue Dec  2 08:38:26 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Tue Mar  3 15:04:55 1998
# Language        : CPerl
# Update Count    : 4
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
# 
# 

use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'	=> 'CGI::Screen',
   # $Format: "   'VERSION'    => sprintf('%5.3f', ($ProjectMajorVersion$ * 100 + ( $ProjectMinorVersion$-1))/1000),"$ 
   'VERSION'    => sprintf('%5.3f', (1 * 100 + ( 22))/1000),
   'dist'       => {
                    COMPRESS => 'gzip -9f',
                    PREOP    => 'pod2text lib/CGI/Screen.pm > README',
                   },
   'PREREQ_PM'  => { 'CGI' => 0},
  );


