use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
$optionals{LICENSE} = 'perl' if $Config{api_version} > 8;
WriteMakefile(
    'NAME'	        => 'Algorithm::Permute',
    'VERSION_FROM'  => 'Permute.pm', # finds $VERSION
    'LIBS'	        => [''],   # e.g., '-lm' 
    'DEFINE'	    => '-DPERL_EXT',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	        => '',     # e.g., '-I/usr/include/other' 
    'OBJECT'        => 'coollex.o Permute.o',
    'CCFLAGS'       => $Config{ccflags}, # '-Wall -fno-strict-aliasing',
    %optionals,
);
