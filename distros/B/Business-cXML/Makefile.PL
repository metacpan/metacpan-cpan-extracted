use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Business::cXML',
	AUTHOR           => q{Stéphane Lavergne <https://github.com/vphantom/>},
	VERSION_FROM     => 'lib/Business/cXML.pm',
	ABSTRACT_FROM    => 'lib/Business/cXML.pm',
	LICENSE          => 'mit',
	PL_FILES         => {},
	MIN_PERL_VERSION => '5.014',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	BUILD_REQUIRES => {
		'Test::Deep'                  => '0',
		'Test::MockModule'            => '0',
		'Test::More'                  => '0',
		'Test::Trap'                  => '0',
		'File::Slurp'                 => '0',
		'Pod::Coverage::CountParents' => '0',  # Not really, but I couldn't figure out how to avoid it
	},
	PREREQ_PM => {
		'Clone'              => '0.31',
		'Carp'               => '1.20',
		'DateTime'           => '0.75',
		'HTML::Entities'     => '3.69',
		'LWP::UserAgent'     => '6.0',
		'MIME::Base64'       => '3.13',
		'Scalar::Util'       => '1.23',
		'Sys::Hostname'      => '1.16',
		'XML::LibXML::Ferry' => '0',
		'XML::LibXML'        => '2.0',
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Business-cXML-*' },
);
