# $Id: Makefile.PL,v 1.2 2006/05/16 09:50:26 joern Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'CIPP',
    'VERSION_FROM' => 'lib/CIPP.pm',
    'EXE_FILES' => [ 'bin/cipp-l10n','bin/cipp-link-static' ],
    'PREREQ_PM' => {
        'Locale::TextDomain' => 1.16,
    },
    'dist' => {
        COMPRESS => "gzip",
        SUFFIX => "gz",
	POSTOP => "mv *.tar.gz dist",
    }
);
