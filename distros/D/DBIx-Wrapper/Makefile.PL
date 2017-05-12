#!/usr/bin/env perl

# Creation date: 2003-03-30 17:52:14
# Authors: Don
# Change log:
# $Id: Makefile.PL 1962 2012-01-17 15:41:43Z don $

use strict;
use Carp;

# main
{
    use ExtUtils::MakeMaker;

    WriteMakefile(
                  NAME => 'DBIx::Wrapper',
                  DISTNAME => 'DBIx-Wrapper',
                  VERSION_FROM => 'lib/DBIx/Wrapper.pm',
                  ABSTRACT => 'Wrapper Module for the DBI',
                  AUTHOR => 'DON OWENS <don@owensnet.com>',
                  PM => { 'lib/DBIx/Wrapper.pm' => '$(INST_LIBDIR)/Wrapper.pm',
                          'lib/DBIx/Wrapper/Request.pm' => '$(INST_LIBDIR)/Wrapper/Request.pm',
                          'lib/DBIx/Wrapper/SelectLoop.pm' => '$(INST_LIBDIR)/Wrapper/SelectLoop.pm',
                          'lib/DBIx/Wrapper/SelectExecLoop.pm' => '$(INST_LIBDIR)/Wrapper/SelectExecLoop.pm',
                          'lib/DBIx/Wrapper/SQLCommand.pm' => '$(INST_LIBDIR)/Wrapper/SQLCommand.pm',
                          'lib/DBIx/Wrapper/StatementLoop.pm' => '$(INST_LIBDIR)/Wrapper/StatementLoop.pm',
                          'lib/DBIx/Wrapper/Statement.pm' => '$(INST_LIBDIR)/Wrapper/Statement.pm',
                          'lib/DBIx/Wrapper/Delegator.pm' => '$(INST_LIBDIR)/Wrapper/Delegator.pm',
                          'lib/DBIx/Wrapper/DBIDelegator.pm' => '$(INST_LIBDIR)/Wrapper/DBIDelegator.pm',
                          'lib/DBIx/Wrapper/Changes.pm' => '$(INST_LIBDIR)/Wrapper/Changes.pm',
                        },
                  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
                  DIR => [],
                  EXE_FILES => [],
                  PREREQ_PM => {
                                DBI => 0,
                                'Test::More' => 0,
                                # 'Scalar::Util' => 0,
                                # 'SQL::Abstract' => 0
                               },
                  );

}

exit 0;

###############################################################################
# Subroutines

