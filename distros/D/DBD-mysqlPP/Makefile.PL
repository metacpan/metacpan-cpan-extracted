use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'DBD::mysqlPP',
	'VERSION_FROM'	=> 'mysqlPP.pm',
	'PREREQ_PM'		=> {
		'DBI'        => 1.0,
		'Net::MySQL' => 0.08,
	},
	($] >= 5.005 ?
	(AUTHOR     => 'Hiroyuki OYAMA <oyama@module.jp>') : ()),
);
