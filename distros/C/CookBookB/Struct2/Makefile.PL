use ExtUtils::MakeMaker;
$Verbose = 1;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CookBookB::Struct2',
    'VERSION_FROM' => 'Struct2.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'OBJECT'    => '$(O_FILES)',
    'XSPROTOARG'	=> '-noprototypes',
);
