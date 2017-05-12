# Makefile.PL for CIDR::Assign module
# $Id: Makefile.PL,v 1.1 1998/03/10 01:50:47 mrp Exp $
use ExtUtils::MakeMaker;
WriteMakefile (NAME         => 'CIDR::Assign',
	       DISTNAME     => 'CIDR-Assign',
               VERSION_FROM => 'Assign.pm',
	       dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' });
