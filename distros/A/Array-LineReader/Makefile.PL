use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Array::LineReader',
    'VERSION_FROM'	=> 'LineReader.pm', # finds $VERSION
    'PREREQ_PM'		=> {Tie::Array => 0.01, IO::File => 0.01}, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'LineReader.pm', # retrieve abstract from module
       AUTHOR     => 'Bjoern Holsten <bholsten + At + freenet + DoT + de>') : ()),
);
