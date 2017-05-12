use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Data::Paginated',
	'VERSION_FROM' => 'lib/Data/Paginated.pm',
	'PREREQ_PM'    => { 'Data::Pageset' => 0, },
);
