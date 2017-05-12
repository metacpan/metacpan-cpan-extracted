use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
     TYPEMAPS => '../typemap',	       
    'NAME'	=> 'DCE::rgybase',
    'VERSION_FROM' => 'rgybase.pm', # finds $VERSION
);
