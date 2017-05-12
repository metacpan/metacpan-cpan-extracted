use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'  => 'Btrees',
    'VERSION_FROM' => 'lib/Btrees.pm', # finds $VERSION
#    'LIBS' => [''],   # e.g., '-lm' 
#    'DEFINE'   => '',     # e.g., '-DHAVE_SOMETHING' 
#    'INC'  => '',     # e.g., '-I/usr/include/other' 
     'PREREQ_PM' => { Carp => 0 },
     'dist'      => {COMPRESS => 'gzip -9',
                     SUFFIX   => '.gz',
                     DIST_DEFAULT => 'all tardist',
                    },
);
