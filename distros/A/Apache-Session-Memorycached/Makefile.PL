use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache::Session::Memorycached',
    VERSION_FROM      => 'lib/Apache/Session/Memorycached.pm', # finds $VERSION
    PREREQ_PM         => {Apache::Session=> '0.0', 
                          Cache::Memcached=> '1.0.12',
                            }, # e.g., Module::Name => 1.1
     ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       (AUTHOR         => 'Eric German <germanlinux@yahoo.fr>') : ()),
);
