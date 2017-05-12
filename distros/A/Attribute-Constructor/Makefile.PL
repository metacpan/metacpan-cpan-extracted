use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Attribute::Constructor',
    'VERSION_FROM'	=> 'Constructor.pm',
    'PREREQ_PM'		=> { 'Attribute::Handlers' => 0.78 },
    'dist'      	=> {COMPRESS => 'gzip', SUFFIX => '.gz'},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Constructor.pm', # retrieve abstract from module
       AUTHOR     => 'Eric Anderson, <eric.anderson@cordata.net>') : ()),
);
