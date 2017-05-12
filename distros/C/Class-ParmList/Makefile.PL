use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	     => 'Class::ParmList',
    'VERSION_FROM'   => 'lib/Class/ParmList.pm',
    'linkext'        => { LINKTYPE=>'' },	# no link needed
    'dist'           => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
	                 'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'},
    'PREREQ_PM'      => {}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/ParmList.pod', # retrieve abstract from module
       AUTHOR         => 'Benjamin Franz <snowhare@nihongo.org>') : ()),

       ($] >= 5.800 ?     ## Add these new keywords supported since 5.8
             (NO_META      => 1) : ()),

       PL_FILES       => {},

);
