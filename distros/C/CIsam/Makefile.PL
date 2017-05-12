use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'	=> 'Ilya Verlinsky ilya@wsi.net',
    'ABSTRACT'	=> 'Object Oriented Interface to C-ISAM files',
    'NAME'	=> 'CIsam',
    'VERSION_FROM' => 'CIsam.pm', # finds $VERSION
    'LIBS'	=> ['-lm -lisam'],   # e.g., '-lm' 
    'DEFINE'	=> '-DCISAM4',     # e.g., '-DHAVE_SOMETHING' if you use Informix C-Isam v.4.xx do '-DCISAM4'
    'INC'	=> '-I/home/wsi/r56work/src/include',     # e.g., '-I/usr/include/other' 
    'PMLIBDIRS'	=> [ 'lib', ${BASEEXT}, 'eg' ],
);
