use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		    =>   'Apache::Authen::Program',
    'VERSION_FROM'	=>   'Program.pm',
    'PREREQ_PM'		=>   {
                          'Apache::Constants' => 0
                         },
    ($] >= 5.005 ?       ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM =>  'Program.pm', # retrieve abstract from module
       AUTHOR     =>     'Mark Leighton Fisher <mark-fisher@fisherscreek.com>') : ()),
);
