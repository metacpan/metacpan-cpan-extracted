use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.3 2006/01/20 21:31:27 tans Exp $

# Copyright (c) 2002 Shufeng Tan.  All rights reserved.
# 
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Crypt::OICQ',
    'VERSION_FROM'	=> 'OICQ.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'OICQ.pm', # retrieve abstract from module
       AUTHOR     => 'Shufeng Tan <perloicq@yahoo.com>') : ()),
    'LIBS'		=> [''],
    'DEFINE'		=> '',
    'INC'		=> '-I.'
);
