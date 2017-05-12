##
## Makefile.PL -- perl Makefile.PL for Apache::Mmap module
##
## Copyright (c) 1997
## Mike Fletcher <lemur1@mindspring.com>
## 08/28/97
##
## THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED 
## WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
## OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
##
## See the files 'Copying' or 'Artistic' for conditions of use.
##

##
## $Id: Makefile.PL,v 1.2 1997/09/09 06:15:55 fletch Exp $
##

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'Apache::Mmap',
	      'VERSION_FROM' => 'Mmap.pm', # finds $VERSION
	      PM => {
		     'Mmap.pm' => '$(INST_LIBDIR)/Mmap.pm',
		     'Handle.pm' => '$(INST_LIBDIR)/Mmap/Handle.pm',
		    },
	      'dist'    => {
			    COMPRESS=> 'gzip -9f', SUFFIX=>'gz',
			   },
);
