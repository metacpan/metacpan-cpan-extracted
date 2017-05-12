#
# Makefile.PL for Apache::SimpleTemplate
# 
# perl Makefile.PL
# make
# make install
#

use ExtUtils::MakeMaker;
WriteMakefile(
	      'NAME'         => 'Apache::SimpleTemplate',
	      'VERSION_FROM' => 'SimpleTemplate.pm',
	      'PREREQ_PM'    => {
		  'Apache' => 1,
	      },
	      );


