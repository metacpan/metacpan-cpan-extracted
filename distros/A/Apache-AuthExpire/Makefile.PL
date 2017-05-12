use ExtUtils::MakeMaker;
use Apache::src ();
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'		=> 'J. J. Horner jjhorner@bellsouth.net',
    'NAME'		=> 'Apache::AuthExpire',
    'VERSION_FROM'	=> 'AuthExpire.pm', # finds $VERSION
    'PREREQ_PM'		=> {Apache::Log}, # e.g., Module::Name => 1.1
    'INC'		=> Apache::src->new->inc,
);


