use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'         => 'DBIx::MyPassword',
  'VERSION_FROM' => 'lib/DBIx/MyPassword.pm', 
  'AUTHOR'       => 'Josh McAdams <joshua dot mcadams at gmail dot com>',
  'ABSTRACT'     => 'DBIx::MyPassword - My Own Password Cache',
  'PREREQ_PM'    => {
	'Text::CSV' => 0,
	'Carp' => 0,
	'DBI' => 0,
	'IO::File' => 0,
	'File::Spec' => 0,
  },
);

