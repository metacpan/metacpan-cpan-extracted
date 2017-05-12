# $Id: Makefile.PL,v 1.2 2001/02/28 23:50:23 cgilmore Exp cgilmore $

use strict;
use Config qw(%Config);
use ExtUtils::MakeMaker;

WriteMakefile 
  (
   'NAME'         => 'Apache::AuthzCache',
   'VERSION_FROM' => 'AuthzCache.pm',
   'PREREQ_PM'    => { 'Apache' => '1.24',
		       'Apache::Log' => '1.01',
		       'Cache::Cache' => '1.01', 
		       'Text::ParseWords' => '3.2' },
   'dist'         => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', },
  );
