#!/usr/bin/perl

# Creation date: 2003-08-13 20:59:11
# Authors: Don
# Change log:
# $Id: Makefile.PL,v 1.6 2006/05/26 22:56:05 don Exp $

use strict;
use Carp;

# main
{
    use ExtUtils::MakeMaker;

    WriteMakefile(
                  NAME => 'CGI::Utils',
                  DISTNAME => 'CGI-Utils',
                  VERSION_FROM => 'lib/CGI/Utils.pm',
                  ABSTRACT => 'CGI utilities',
                  AUTHOR => 'DON OWENS <don@regexguy.com>',
                  PM => { 'lib/CGI/Utils.pm' => '$(INST_LIBDIR)/Utils.pm',
                          'lib/CGI/Utils/UploadFile.pm' => '$(INST_LIBDIR)/Utils/UploadFile.pm',
                        },
                  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
                  DIR => [],
                  EXE_FILES => [],
                  NO_META => 0,
                  );


}

exit 0;

###############################################################################
# Subroutines

