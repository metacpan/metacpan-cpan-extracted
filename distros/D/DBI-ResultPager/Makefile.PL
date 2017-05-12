use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'DBI::ResultPager',
	'VERSION_FROM'	=> 'lib/DBI/ResultPager.pm',
	'PREREQ_PM'	=> {
				DBI => 1.48,
				CGI => 3.10,}
);

