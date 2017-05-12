require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Database::Wrapper',
    'VERSION_FROM' => 'lib/Database/Wrapper.pm',
    'PREREQ_PM'    => {
	                'DBI' => '1.00',
                      },
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
