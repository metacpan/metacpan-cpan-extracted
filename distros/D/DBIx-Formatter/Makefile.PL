use ExtUtils::MakeMaker;

%mods = (
	'DBI'		=> '1'
	);

WriteMakefile(
	'NAME' 		=> 	"DBIx::Formatter",
	'VERSION_FROM' 	=> 	"Formatter.pm",
	'PREREQ_PM'	=>	\%mods,
	'dist'		=>	{
				COMPRESS	=>	'gzip -9f',
				SUFFIX		=>	'gz',
				DIST_DEFAULT	=>	'all tardist',
				DIST_CP		=>	'ln'
				}
);
