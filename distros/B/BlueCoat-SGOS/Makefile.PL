use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	($ExtUtils::MakeMaker::VERSION >= 6.18
		? (MM->can('signature_target') ? (SIGN => 1) : ())
		: ()),
	NAME             => 'BlueCoat::SGOS',
	AUTHOR           => q{Matthew Lange <mmlange@cpan.org>},
	VERSION_FROM     => 'lib/BlueCoat/SGOS.pm',
	ABSTRACT_FROM    => 'lib/BlueCoat/SGOS.pm',
	MIN_PERL_VERSION => '5.6.0',
	(
		$ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE' => 'GPL_2')
		: ()
	),
	PL_FILES  => {},
	PREREQ_PM => {
		'Date::Parse'          => '0',
		'Test::More'           => '0',
		'LWP::UserAgent'       => '6.00',    # requires ssl_opts
		'HTTP::Request'        => '6.00',
		'LWP::Protocol::https' => '0',
	},
	BUILD_REQUIRES => {
		'TAP::Harness'     => '3.18',
		'Test::NoWarnings' => '1.04',
	},

	dist => {
		COMPRESS => 'gzip -9f',
		SUFFIX   => 'gz',
	},
	clean => {FILES => 'BlueCoat-SGOS-*'},
);
