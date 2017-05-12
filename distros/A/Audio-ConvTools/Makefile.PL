use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Audio::ConvTools',
	AUTHOR              => 'Michael Hooreman <mhooreman@skynet.be>',
	VERSION_FROM        => 'lib/Audio/ConvTools.pm',
	ABSTRACT_FROM       => 'lib/Audio/ConvTools.pm',
	PL_FILES            => {},
	EXE_FILES           => ['bin/audioconv', 'bin/audiocdmaker'],
	PREREQ_PM => {
		'Test::More'         => 0,
		'File::NCopy'        => 0.32,
		'File::Temp'         => 0.17,
		'Getopt::Long'       => 0,
		'Pod::Usage'         => 0,
		'String::ShellQuote' => 1.03,
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Audio-ConvTools-*' },
	PREREQ_PRINT        => 1,
	LIBS                => [''],
	DEFINE              => '',
	INC                 => '',
);

