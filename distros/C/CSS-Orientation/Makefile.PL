
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'CSS::Orientation',
	'VERSION_FROM'	=> 'lib/CSS/Orientation.pm',
	'PREREQ_PM'	=> {},
	'ABSTRACT_FROM'	=> 'lib/CSS/Orientation.pm',
	'EXE_FILES'	=> ['script/css-orientation'],
	'AUTHOR'	=> 'Simon Bertrang <janus@cpan.org>',
);

