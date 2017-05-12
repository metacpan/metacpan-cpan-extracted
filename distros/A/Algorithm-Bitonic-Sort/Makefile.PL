use utf8;
use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Algorithm::Bitonic::Sort',
	AUTHOR              => q{BlueT - Matthew Lien - 練喆明 <BlueT@BlueT.org>},
	VERSION_FROM        => 'lib/Algorithm/Bitonic/Sort.pm',
	ABSTRACT_FROM       => 'lib/Algorithm/Bitonic/Sort.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES	=> {},
	PREREQ_PM => {
		'Test::Simple'	=> 0,
		'common::sense'	=> 0,
		'feature'	=> 0,
	},
	dist	=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean	=> { FILES => 'Algorithm-Bitonic-Sort-*' },
);
