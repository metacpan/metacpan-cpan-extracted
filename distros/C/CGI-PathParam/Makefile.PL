#!/usr/bin/env perl
#
# $Revision: 1.1 $
# $Source: /home/cvs/CGI-PathParam/Makefile.PL,v $
# $Date: 2006/05/30 22:29:06 $
#
use strict;
use warnings;
our $VERSION = '0.01';

use inc::Module::Install;
eval {
    require ExtUtils::MakeMaker::Coverage;
    ExtUtils::MakeMaker::Coverage->import;
};

name 'CGI-PathParam';
all_from 'lib/CGI/PathParam.pm';

WriteAll;
