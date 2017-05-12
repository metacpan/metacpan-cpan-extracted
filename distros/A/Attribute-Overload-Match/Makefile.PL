use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'	=> 'Attribute::Overload::Match',
	'VERSION_FROM' => 'Match.pm', 
	'dist'    => {
		COMPRESS => 'gzip -9f',
		SUFFIX   => '.gz', 
		DIST_DEFAULT => 'all tardist',
	},
	'PREREQ_PM'   => {
		'Attribute::Handlers' => '0', # or a minimum working version
	},
	'DISTNAME' => 'Attribute-Overload-Match',
	'ABSTRACT' => 'Argument-dependent handlers for overloaded operators',
	'AUTHOR'   => 'Dmitry Karasik <dmitry@karasik.eu.org>',
);
