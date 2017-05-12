use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'Config::INI::Access',
	'VERSION_FROM' => 'lib/Config/INI/Access.pm',
	($] >= 5.005 ?
		(
			ABSTRACT_FROM => 'lib/Config/INI/Access.pm',
			AUTHOR => 'Andrew Shitov <andy@shitov.ru>'
		)
		:
		()
	),
	'PREREQ_PM' => {
		'Config::INI::Reader' => 0,
	}
);
