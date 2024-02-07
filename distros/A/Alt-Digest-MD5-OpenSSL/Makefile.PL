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
		'ExtUtils::MakeMaker' => '6.76',
	},
	CONFIGURE_REQUIRES => {
		'Alien::Base::Wrapper' => 0.32,
		'ExtUtils::MakeMaker' => '6.76',
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
	TEST_REQUIRES => {
		'Alien::OpenSSL' => 0,
		'Encode' => 0,
		'MIME::Base64' => 0,
		'Test::Alien::Diag' => 0,
		'Test::More' => 0,
		'Test::NoWarnings' => 0,
	},
	($] >= 5.005 ? (
		ABSTRACT_FROM  => 'lib/Alt/Digest/MD5/OpenSSL.pm',
		AUTHOR => 'Michal Josef Spacek <michal.josef.spacek@gmail.com>',
	) : ()),
	'alien_requires' => {
		'Alien::OpenSSL' => 0,
	},
	'test' => {
		RECURSIVE_TEST_FILES => 1,
	},
);
