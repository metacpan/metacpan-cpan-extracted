# $Id: Makefile.PL,v 1.2 2001/03/02 21:13:12 cgilmore Exp $

use strict;
use Config qw(%Config);
use ExtUtils::MakeMaker;

WriteMakefile 
  (
   'NAME'         => 'Apache::ProxyRewrite',
   'VERSION_FROM' => 'ProxyRewrite.pm',
   'PREREQ_PM'    => { 'Apache'           => '1.24', 
		       'Apache::Log'      => '0',
		       'LWP'              => '5.43', 
		       'URI'              => '1.0' },
   'dist'         => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz' },
  );
