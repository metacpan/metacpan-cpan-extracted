use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'Date::Converter',
	'VERSION_FROM' => 'lib/Date/Converter.pm',
	($] >= 5.005 ?
		(
			ABSTRACT_FROM => 'lib/Date/Converter.pm',
			AUTHOR => 'Andrew Shitov <andy@shitov.ru>'
		)
		:
		()
	)
);
