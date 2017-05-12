use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Authen::Challenge::Basic',
    'VERSION_FROM' => 'Basic.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'CONFIG'	=> ['byteorder'],	# Used to determine 64-bitness
    'DEFINE'	=> '-DPERL_BYTEORDER=$(BYTEORDER)',
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);
