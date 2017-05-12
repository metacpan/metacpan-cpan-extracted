use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	      'NAME'	     => 'Audio::SID',
	      'VERSION_FROM' => 'SID.pm',
          ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
            (ABSTRACT_FROM => 'SID.pm', # retrieve abstract from module
             AUTHOR      => 'LaLa <LaLa@C64.org>') : ()),
);
