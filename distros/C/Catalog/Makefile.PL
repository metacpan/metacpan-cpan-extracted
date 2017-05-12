#
#   Copyright (C) 1998, 1999 Loic Dachary
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
# 
# $Header: /cvsroot/Catalog/Catalog/Makefile.PL,v 1.42 1999/09/07 14:48:03 loic Exp $
#
# This -*- perl -*- script writes the Makefile for Catalog

require 5.005;
use strict;

#--- Configuration section ---

my(@programs_to_install) = qw(convert_dmoz sengacontrib);

use ExtUtils::MakeMaker;

require "conf/lib.pl";

version_check('DBI', '1.08', 'require DBI;');
version_check('MD5', '1.7', 'require MD5;');
version_check('CGI', '2.46', 'require CGI;');
version_check('XML::Parser', '2.26', 'require XML::Parser;');
version_check('XML::DOM', '1.19', 'require XML::DOM;');
version_check('MIME::Base64', '2.11', 'require MIME::Base64;');
version_check('Unicode::String', '2.02', 'require Unicode::String;');
version_check('Unicode::Map8', '0.06', 'require Unicode::Map8;');
version_check('Text::Query', '0.07', 'require Text::Query;');
version_check('Text::Query::BuildSQL', '0.05', 'require Text::Query::BuildSQL;');

my($subdirs) = "cgi-bin conf example images doc";

sub MY::postamble { 
return '
clean ::
	rm -fr t/fulcrum t/tmp t/conf/mysql.conf t/conf/install.conf

ptags:
	ptags lib/Catalog.pm lib/Catalog/???*.pm lib/Catalog/db/*pm lib/Catalog/tools/[cmst]*.pm

cvs_diff_tag :
	$(MAKE) realclean
	cvs diff -c -r`sed "s/^T//" CVS/Tag` > `sed "s/^T//" CVS/Tag`-`date "+%Y%m%d"`.diff

realclean ::
	rm -fr MANIFEST MANIFEST.bak Catalog-*

install:: 
	for i in ' . $subdirs . ' ; do ( cd $$i ; $(MAKE) install ) ; done
	@echo ; echo "Read the Catalog management guide chapter in the Catalog documentation "
	@echo "at http://www.senga.org/Catalog/current/doc/catalog_toc.html"
	@echo "Go to the URL http://www.mymachine.org/Catalog/ for the ready to use example."

';
}

WriteMakefile(
  'VERSION_FROM' => 'lib/Catalog.pm',
  'NAME'	 => 'Catalog',
  'DIR'          => [ split(" ", $subdirs) ],
  'PL_FILES'     => { map {("bin/$_.PL" => "bin/$_")} @programs_to_install },
  'EXE_FILES'    => [ map {"bin/$_"} @programs_to_install ],
  'MAN1PODS'     => { 'doc/Catalog.pod' => 'blib/man1/Catalog.1' },
  'dist'         => { COMPRESS => 'gzip', SUFFIX => '.gz' },
  'clean'	 => { FILES => '$(EXE_FILES)' },
);

