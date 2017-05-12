use ExtUtils::MakeMaker;
$Verbose = 1;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CookBookA::Ex_SDV',
    'VERSION_FROM' => 'Ex_SDV.pm',
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'XSPROTOARG'	=> '-noprototypes',
);
