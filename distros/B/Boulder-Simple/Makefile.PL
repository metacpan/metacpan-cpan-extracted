use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Boulder::Simple',
    'VERSION_FROM'	=> 'lib/Boulder/Simple.pm',
    'PREREQ_PM'		=> { CGI::Util=>0 }, 
);
