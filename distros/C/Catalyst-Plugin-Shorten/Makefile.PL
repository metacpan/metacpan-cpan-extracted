use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'Catalyst::Plugin::Shorten',
    AUTHOR           => q{LNATION <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Catalyst/Plugin/Shorten.pm',
    ABSTRACT_FROM    => 'lib/Catalyst/Plugin/Shorten.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
		'Module::Metadata' => '1.000033',
	},
    BUILD_REQUIRES => {
        'Test::More' => '0',
		'JSON' => '0',
	},
    PREREQ_PM => {
        'Catalyst::Runtime' => '5.80001',
		'Bijection' => '0.04',
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Catalyst-Plugin-Shorten-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/ThisUsedToBeAnEmail/Catalyst-Plugin-Shorten.git',
				web  => 'https://github.com/ThisUsedToBeAnEmail/Catalyst-Plugin-Shorten',
			},
		},
	},
	META_ADD => {
		provides => Module::Metadata->provides(version => '2', dir => 'lib'),
	}, 
);
