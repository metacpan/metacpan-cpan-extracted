#!/usr/bin/perl

# Creation date: 2004-01-31 20:13:44
# Authors: Don
# Change log:
# $Id: Makefile.PL,v 1.1 2004/02/01 05:00:17 don Exp $

use strict;
use Carp;

# main
{
    local($SIG{__DIE__}) = sub { &Carp::cluck(); exit 0 };

    use ExtUtils::MakeMaker;

    WriteMakefile(
                  NAME => 'Class::Config',
                  DISTNAME => 'Class-Config',
                  VERSION_FROM => 'Config.pm',
                  ABSTRACT => 'Methods From Config Files',
                  AUTHOR => 'DON OWENS <don@owensnet.com>',
                  PM => { 'Config.pm' => '$(INST_LIBDIR)/Config.pm',
                          'Config/File.pm' => '$(INST_LIBDIR)/Config/File.pm',
                        },
                  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
                  DIR => [],
                  EXE_FILES => [],
                  PREREQ_PM => { Carp => 0,
                                 # 'Tie::Hash' => 0,
                               },
                  );

}

exit 0;

###############################################################################
# Subroutines

