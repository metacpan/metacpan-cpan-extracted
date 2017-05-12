use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Bit::ShiftReg',
    'VERSION_FROM'	=> 'ShiftReg.pm', # finds $VERSION
    'LIBS'		=> [''],   # e.g., '-lm' 
    'DEFINE'		=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'		=> '',     # e.g., '-I/usr/include/other' 
    'dist'		=> { COMPRESS=>"gzip -9", SUFFIX=>"gz" }
);
