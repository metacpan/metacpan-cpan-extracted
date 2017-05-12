use ExtUtils::MakeMaker;
$Verbose = 1;

$CC = 'CC';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CookBookB::CCsimple',
    'VERSION_FROM' => 'CCsimple.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'CC'	=> $CC,
    'LD'	=> '$(CC)',
#    'LINKTYPE'	=> 'static',
    'XSPROTOARG'	=> '-noprototypes',
    'TYPEMAPS'	=> ['../perlobject.map' ],
    'realclean'	=> {'FILES' => 'perl'},
);
