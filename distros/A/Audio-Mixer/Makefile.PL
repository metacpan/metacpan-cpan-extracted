use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Audio::Mixer',
    'VERSION_FROM' => 'Mixer.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
     clean     => {'FILES' => 'Mix.o'},
    'MYEXTLIB' => 'Mix.o', 
    AUTHOR => "Sergey Gribov <sergey@sergey.com>",
    ABSTRACT_FROM => "Mixer.pm",
);
