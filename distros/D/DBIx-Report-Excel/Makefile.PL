use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'DBIx::Report::Excel',
    VERSION_FROM      => 'lib/DBIx/Report/Excel.pm',
    PREREQ_PM         => {
			  Data::Tabular::Dumper => 0.06,
			  Data::Tabular::Dumper::Excel => 0,
			  SQL::Parser => 1.24,
			  SQL::Script => 1.05,
			  YAML => 0.68,
			  'Spreadsheet::WriteExcel'	=> '0',
			   # Prereq for tests
			   'DBI' => 0,
			   'DBD::SQLite' => 0,

			 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/DBIx/Report/Excel.pm', # retrieve abstract from module
       AUTHOR         => 'Dmytro Kovalov <dmytro.kovalov@gmail.com>') : ()),
    clean             => { FILES => "t/tmp/*" }
);
