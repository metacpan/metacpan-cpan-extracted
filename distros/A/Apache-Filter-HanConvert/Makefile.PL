#!/usr/bin/perl
# $File: //member/autrijus/Apache-Filter-HanConvert/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 2677 $ $DateTime: 2002/12/11 16:52:29 $

use 5.007003;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Filter between Chinese variant and encodings',
    NAME		=> 'Apache::Filter::HanConvert',
    VERSION_FROM	=> 'HanConvert.pm', 
    DISTNAME		=> 'Apache-Filter-HanConvert',
    BINARY_LOCATION	=> 'x86/HanConvert.tar.gz',
    PREREQ_PM		=> {
	'Apache2'		=> 0,
	'Encode'		=> 0,
	'Encode::HanConvert'    => 0.10,
    },
    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);
