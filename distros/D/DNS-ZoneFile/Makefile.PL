require 5.005;
use ExtUtils::MakeMaker;

# $Id$
WriteMakefile(
	'NAME'		=>	'DNS::ZoneFile',
	'VERSION_FROM'	=>	'ZoneFile.pm',
	dist		=>	{ COMPRESS => 'gzip -9f', SUFFIX => 'gz'}
	);
