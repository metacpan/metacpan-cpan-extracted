use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Bio::SCF',
    'VERSION_FROM' => 'SCF.pm', # finds $VERSION
    'LICENSE'   => 'perl',
    'LIBS'	=> ['-lstaden-read -lz'],   # e.g., '-lm' 
    'DEFINE'	=> '-DLITTLE_ENDIAN',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other'
);
