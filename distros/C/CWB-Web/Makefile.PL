##
##  Perl makefile for the official CWB/Perl interface (support for Web interfaces)
##

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => "CWB::Web",
  VERSION_FROM => "lib/CWB/Web.pm",
  PREREQ_PM    => {
    'CWB'            => 'v3.5.0',
    'CWB::CL'        => 'v3.5.0',
    'HTML::Entities' => 0,
  },
  LICENSE      => 'perl',
  META_MERGE   => {
    resources => {
      homepage => 'https://cwb.sourceforge.io/',
      repository => 'http://svn.code.sf.net/p/cwb/code/perl/trunk',
    },
  },
);

