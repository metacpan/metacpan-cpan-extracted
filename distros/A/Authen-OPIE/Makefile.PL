use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Authen::OPIE',
    'VERSION_FROM' => 'OPIE.pm', # finds $VERSION
    'LIBS'	=> ['-L/usr/local/opie/lib -lopie'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-I/usr/local/opie/include',     
);
