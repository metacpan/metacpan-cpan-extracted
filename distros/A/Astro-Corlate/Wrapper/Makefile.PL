use ExtUtils::MakeMaker;
use ExtUtils::F77 qw(linux f95);

# Library location
$location = '-LFortran';

# list of libraries
$cor_lib = '-lCorlate';

# LIBS line for ExtUtils::MakeMaker
$libs = "$location $cor_lib -lm"; 
#$libs = $libs . ExtUtils::F77->runtime;

WriteMakefile(
    'NAME'		=> 'Astro::Corlate::Wrapper',
    'VERSION_FROM'	=> 'Wrapper.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> [ $libs ], # e.g., '-lm',
    'LD'                => 'f95' ,
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);
