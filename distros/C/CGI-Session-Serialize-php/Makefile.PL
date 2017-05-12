use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'CGI::Session::Serialize::php',
	LICENSE			=> 'bsd',
	ABSTRACT		=> 'CGI::Session::Serialize::php - PHP serializer for CGI::Session',
	AUTHOR			=> 'Ian McWilliam <kaosagnt@gmail.com>',
	VERSION_FROM	=> 'lib/CGI/Session/Serialize/php.pm',
	BUILD_REQUIRES => {
		'Test::More' => 0,
		'Test::Pod'  => 0
	},
	PREREQ_PM => {
		'CGI::Session' => 0,
		'PHP::Session' => 0
	}
);