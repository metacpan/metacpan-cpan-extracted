use 5.008005;
use strict;
use warnings;

use Alien::Base::Wrapper qw(WriteMakefile);

WriteMakefile(
	NAME => 'Digest::MD5',
	DISTNAME => 'Alt-Digest-MD5-OpenSSL',
	VERSION_FROM => 'lib/Alt/Digest/MD5/OpenSSL.pm',
	BUILD_REQUIRES => {
		'Alien::Base::Wrapper' => 0.32,
		'ExtUtils::MakeMaker' => '6.52',
	},
	CONFIGURE_REQUIRES => {
		'Alien::Base::Wrapper' => 0.32,
		'ExtUtils::MakeMaker' => '6.52',
	},
	META_MERGE => {
		no_index => {
			directory => [qw(lib/Digest)],
		},
	},
	PREREQ_PM => {
		'Digest::base' => '1.00',
		'XSLoader' => 0,
	},
	($] >= 5.005 ? (
		ABSTRACT_FROM  => 'lib/Alt/Digest/MD5/OpenSSL.pm',
		AUTHOR => 'Michal Josef Spacek <michal.josef.spacek@gmail.com>',
	) : ()),
	'alien_requires' => {
		'Alien::OpenSSL' => 0,
	},
);
