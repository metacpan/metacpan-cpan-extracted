use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Chooser',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Chooser.pm',
			  ABSTRACT_FROM       => 'lib/Chooser.pm',
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More' => 0,
							'IO::Socket::SSL'=>0,
							'Sys::Hostname'=>0,
							'Text::NeatTemplate'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Chooser-*' },
			  );
