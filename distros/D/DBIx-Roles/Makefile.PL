use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'	=> 'DBIx::Roles',
	'VERSION_FROM' => 'Roles.pm', 
	'dist'    => {
		COMPRESS => 'gzip -9f',
		SUFFIX   => '.gz', 
		DIST_DEFAULT => 'all tardist',
	},
	'PREREQ_PM'   => {
		'DBI'	=> '0', # or a minimum working version
		'SQL::Abstract' => '0',
		'Scalar::Util' => '0',
	},
	'DISTNAME' => 'DBIx-Roles',
	'ABSTRACT' => 'Various roles for DBI handles',
	'AUTHOR'   => 'Dmitry Karasik <dk@catpipe.net>',
);
