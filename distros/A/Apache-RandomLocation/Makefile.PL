use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::RandomLocation',
    'VERSION_FROM' => 'RandomLocation.pm', # finds $VERSION
    'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    'PREREQ_PM' => { 
	'Apache::Constants' => '1.00',
	'CGI' => '2.38',
     },
);
