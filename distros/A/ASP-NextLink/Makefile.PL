use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'			=> 'ASP::NextLink',
	'VERSION_FROM'	=> 'NextLink.pm',
	'dist'			=> {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
	($] ge '5.005')
		? (
			'AUTHOR'	=> 'Tim Hammerquist (cafall@voffice.net)',
			'ABSTRACT'	=> 'Perl implementation of the NextLink ASP component',
		) : (),
);
