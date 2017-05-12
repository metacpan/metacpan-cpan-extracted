use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
     TYPEMAPS => '../typemap',	       
    'NAME'	=> 'DCE::login_base',
    'VERSION_FROM' => 'login_base.pm', # finds $VERSION
);
