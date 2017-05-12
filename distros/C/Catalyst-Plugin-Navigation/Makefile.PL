use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Catalyst::Plugin::Navigation',
	AUTHOR        => q{Derek Wueppelmann <derek@roaringpenguin.com>},
	VERSION_FROM  => 'lib/Catalyst/Plugin/Navigation.pm',
	ABSTRACT_FROM => 'lib/Catalyst/Plugin/Navigation.pm',
	PL_FILES      => {},
	PREREQ_PM     => {
		'Moose::Role' => 0,
		'Moose' => 0,
		'File::Find::Rule'	=> '0'
	},
	dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean         => { FILES => 'Catalyst-Plugin-Navigation-*' },
);
