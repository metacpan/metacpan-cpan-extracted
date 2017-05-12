use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::HTMLDumper',
    'VERSION_FROM'	=> 'HTMLDumper.pm', # finds $VERSION
    'PREREQ_PM'		=> {Test::More => 0,
                            Parse::RecDescent => 0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'HTMLDumper.pm', # retrieve abstract from module
       AUTHOR     => 'Phil Crow <philcrow2000@yahoo.com>') : ()),
);
