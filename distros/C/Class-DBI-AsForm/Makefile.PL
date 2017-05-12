use ExtUtils::MakeMaker;
WriteMakefile(
	NAME         => 'Class::DBI::AsForm',
	VERSION_FROM => 'lib/Class/DBI/AsForm.pm',
	ABSTRACT_FROM => 'lib/Class/DBI/AsForm.pm',          
	PREREQ_PM    => {
		'Class::DBI'               => 0.94,
		'DBI'                      => 1.21,
		'HTML::Element'            => 0,
		'Class::DBI::Plugin::Type' => 0,
	},                                      
	AUTHOR => 'Tony Bowden <TMTM@cpan.org>'
);
