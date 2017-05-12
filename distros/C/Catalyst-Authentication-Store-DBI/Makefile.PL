use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Catalyst::Authentication::Store::DBI',
	'LICENSE'	=> 'perl',
	'VERSION_FROM'	=> 'lib/Catalyst/Authentication/Store/DBI.pm',
	'PREREQ_PM'	=> {
		'Catalyst::Plugin::Authentication'	=> 0,
		'Catalyst::Model::DBI'			=> 0,
	},
	'ABSTRACT_FROM'	=> 'lib/Catalyst/Authentication/Store/DBI.pm',
	'AUTHOR'	=> 'Simon Bertrang <simon.bertrang@puzzworks.com>',
);

