use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'C::Scan',
    'dist'      => { COMPRESS => 'gzip', SUFFIX => '.gz'},
    'VERSION_FROM' => 'Scan.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'PREREQ_PM' => {'Data::Flow' => 0.05},
);
