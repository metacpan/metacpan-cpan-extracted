#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'      => 'Continuus',
	      'VERSION_FROM' => 'Continuus.pm',
	      'dist'       => {
#			       PREOP        => q{(cd docs ; make)},
			       COMPRESS     =>'gzip',
			       SUFFIX       =>'gz',	      
			      },
	      
	     );
