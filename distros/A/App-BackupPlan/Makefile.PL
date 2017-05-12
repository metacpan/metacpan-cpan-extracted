use 5.012003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'App::BackupPlan',
    VERSION_FROM      => 'lib/App/BackupPlan.pm', # finds $VERSION
    LICENSE	  		  => 'perl',
    PREREQ_PM         => {'XML::DOM'      => 1.44,
    	                  'Log::Log4perl' => 1.33,
                          'File::Find'    => 1.15,
                          'Archive::Tar'  => 1.76,
    					  'DateTime'	  => 0.78}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/App/BackupPlan.pm', # retrieve abstract from module
       AUTHOR         => 'gualtiero chiaia') : ()),
);

