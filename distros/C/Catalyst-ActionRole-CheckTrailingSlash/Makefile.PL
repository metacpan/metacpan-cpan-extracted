use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Catalyst::ActionRole::CheckTrailingSlash',
	AUTHOR        => 'Anatoliy Lapitskiy <nuclon@cpan.org>',
	VERSION_FROM  => 'lib/Catalyst/ActionRole/CheckTrailingSlash.pm',
	LICENSE       => 'perl',
	ABSTRACT_FROM => 'lib/Catalyst/ActionRole/CheckTrailingSlash.pm',
	PL_FILES      => {},
	PREREQ_PM     => {
		'Catalyst::Runtime'                => '5.80',
		'Moose::Role'                      => '0',
		'namespace::autoclean'             => '0',
		'Catalyst::Controller::ActionRole' => '0',
		},

	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'Test-Output-*' },
);
