use ExtUtils::MakeMaker;
$Verbose = 1;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CookBookB::Mstruct',
    'VERSION_FROM' => 'Mstruct.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'OBJECT'    => '$(O_FILES)',
    'XSPROTOARG'        => '-noprototypes',
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'TYPEMAPS'  => ['../perlobject.map' ],
);
