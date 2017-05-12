use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::RPC',
    VERSION_FROM      => 'lib/Acme/RPC.pm', # finds $VERSION
    PREREQ_PM         => {
        Continuity => 0.0,
        'IO::Handle' => 0.0,
        JSON => 0.0, 
        'Devel::Caller' => 0.0,
        PadWalker => 0.0, 
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/RPC.pm', # retrieve abstract from module
       AUTHOR         => 'Scott Walters <scott@slowass.net>') : ()),
);
