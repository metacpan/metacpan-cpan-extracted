#
# Makefile.PL - build file for Config::General
#
# Copyright (c) 2000-2014 Thomas Linden <tom@daemon.de>.
# All Rights Reserved. Std. disclaimer applies.
# Artistic License, same as perl itself. Have fun.
#

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'	       => 'Config::General',
	'VERSION_FROM' => 'General.pm',
	'clean'        => {
				FILES                   => 't/*.out t/test.cfg *~ */*~'
			  },
	'PREREQ_PM'    => {
				'IO::File'              => 0,
				'FileHandle'            => 0,
				'File::Spec::Functions' => 0,
				'File::Glob'            => 0
			  },
	'META_MERGE' => {
			resources => {
			repository => 'http://dev.catalyst.perl.org/repos/Config-General/trunk/',
			},
	},
	($ExtUtils::MakeMaker::VERSION ge '6.31'? 
	('LICENSE'		=> 'perl', ) : ()),
);

