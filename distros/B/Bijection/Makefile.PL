use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
	NAME             => 'Bijection',
	AUTHOR           => q{lnation <thisusedtobeanemail@gmail.com>},
	VERSION_FROM     => 'lib/Bijection.pm',
	ABSTRACT_FROM    => 'lib/Bijection.pm',
	LICENSE          => 'artistic_2',
	PL_FILES         => {},
	MIN_PERL_VERSION => '5.006',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
		'Module::Metadata' => '1.000033',
	},
	BUILD_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
 		'Carp' => '0',
		'Import::Export' => '0.08',
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Bijection-*' },
	 META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/ThisUsedToBeAnEmail/Bijection.git',
				web  => 'https://github.com/ThisUsedToBeAnEmail/Bijection',
			},
		},
	},
	META_ADD => {
		provides => Module::Metadata->provides(version => '2', dir => 'lib'),
	}, 
);
