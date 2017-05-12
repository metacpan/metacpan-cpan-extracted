#!/usr/bin/env perl

# Creation date: 2005-10-23 19:38:19
# Authors: don

use strict;
use warnings;
use Carp;

# main
{
    use ExtUtils::MakeMaker;

    WriteMakefile(
                  NAME => 'DBIx::Wrapper::Config',
                  DISTNAME => 'DBIx-Wrapper-Config',
                  VERSION_FROM => 'lib/DBIx/Wrapper/Config.pm',
                  ABSTRACT => 'Config Module for DBIx::Wrapper',
                  AUTHOR => 'DON OWENS <don@regexguy.com>',
                  PM => { 'lib/DBIx/Wrapper/Config.pm' => '$(INST_LIBDIR)/Config.pm',
                        },
                  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
                  DIR => [],
                  EXE_FILES => [],
                  PREREQ_PM => {
                                'DBIx::Wrapper' => 0,
                                'XML::Parser::Wrapper' => 0,
                               },
                  );

}

exit 0;

###############################################################################
# Subroutines

