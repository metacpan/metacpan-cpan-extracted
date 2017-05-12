use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Catalyst::Model::DBI',
	AUTHOR    => 'Alex Pavlovic (alex.pavlovic@taskforce-1.com)',
	PREREQ_PM => {
		Catalyst	=> '5.00',
		DBI		=> 0,
		MRO::Compat	=> 0,
		DBIx::Connector => 0
	},
	VERSION_FROM => 'lib/Catalyst/Model/DBI.pm'
);