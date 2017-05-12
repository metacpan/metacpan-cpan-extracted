use 5.008005;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	      NAME              => 'Apache::Emulator',
	      VERSION_FROM      => 'lib/Apache/Emulator.pm', # finds $VERSION
);
