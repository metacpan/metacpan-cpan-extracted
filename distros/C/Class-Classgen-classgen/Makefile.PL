use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Classgen::classgen',
    'dist' 		=> {SUFFIX=>'gz', COMPRESS=> 'gzip '},
    'VERSION'	 	=> '3.03',
#    'VERSION_FROM' 	=> 'classgen', # finds $VERSION,
    'EXE_FILES'		=> [ qw/ classgen / ]
);
