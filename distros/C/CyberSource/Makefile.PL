use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CyberSource',
    'VERSION_FROM'	=> 'CyberSource.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'CyberSource.pm', 
       AUTHOR     => 'Pavel Smirnov <huge@ax.ru>') : ()),
    'LIBS'		=> ['-L/opt/ics/lib -lics2'], 
    'DEFINE'		=> '',
    'INC'		=> '-I /opt/ics/include',
);
