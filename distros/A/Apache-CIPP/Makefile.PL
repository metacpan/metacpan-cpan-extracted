# $Id: Makefile.PL,v 1.2 2000/08/07 20:27:07 joern Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Apache::CIPP',
    'VERSION_FROM' => 'CIPP.pm',
    'PREREQ_PM' => {
    		'CIPP' => 2.13,
		'Apache' => 0
		},
    'dist' => {
	PREOP => 'pod2text CIPP.pm > README',
        COMPRESS => "gzip",
        SUFFIX => "gz"
    }
);
