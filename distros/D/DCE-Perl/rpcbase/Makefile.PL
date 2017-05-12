use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
     TYPEMAPS => '../typemap',	       
    'NAME'	=> 'DCE::rpcbase',
    'VERSION_FROM' => 'rpcbase.pm', # finds $VERSION
);
