use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Crypt::Passwd',
    'VERSION_FROM' => 'Passwd.pm', # finds $VERSION
    'LIBS'	=> ['-lufc'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'PREREQ_PM' => { 'MD5' => 0 }
);
