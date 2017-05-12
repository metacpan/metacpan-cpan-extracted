use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		    => 'Date::LastModified',
    'VERSION_FROM'	=> 'LastModified.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                        AppConfig    => 1.52,
                        Date::Format => 0,
                        Date::Parse  => 0,
                        DBI          => 1.2,
				        File::Find   => 0,
				        File::stat   => 0,
                        Test::More   => 0,
			           },
    'PL_FILES'          => { "bin/dlmup.PL" => "bin/dlmup" },
    'EXE_FILES'         => [ "bin/dlmup" ],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM    => 'LastModified.pm', # retrieve abstract from module
       AUTHOR           => 'Mark Leighton Fisher <mark-fisher@mindspring.com>') : ()),
);
