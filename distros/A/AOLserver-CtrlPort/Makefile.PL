use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AOLserver::CtrlPort',
    VERSION_FROM      => 'lib/AOLserver/CtrlPort.pm', # finds $VERSION
    PREREQ_PM         => { Net::Telnet   => 0,
                           Log::Log4perl => 0,
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AOLserver/CtrlPort.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Schilli <m@perlmeister.com>') : ()),
);
