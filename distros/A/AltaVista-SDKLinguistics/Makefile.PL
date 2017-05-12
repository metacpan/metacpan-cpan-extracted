use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'AltaVista::SDKLinguistics',
    'VERSION_FROM' => 'SDKLinguistics.pm', # finds $VERSION
    'LIBS' => ['-lm -L. -lavsl30 -lavs30'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-I.' # '-I/usr/include' 
);
