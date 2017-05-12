use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# perl 5.005 is required Data::Table module
# see README in Data::Table for details
#
require 5.005;

WriteMakefile(
    'NAME'	   => 'Data::Table::Excel',
    'VERSION_FROM' => 'Excel.pm', # finds $VERSION
    'PREREQ_PM'    => {
                         Data::Table => 1.52,
                         Spreadsheet::WriteExcel => 0,
                         Spreadsheet::ParseExcel => 0,
                         Spreadsheet::ParseXLSX => 0,
	                 Excel::Writer::XLSX => 0
                      }
);
