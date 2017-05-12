use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Controller::DBIC::Transaction',
    VERSION_FROM      => 'lib/Catalyst/Controller/DBIC/Transaction.pm', # finds $VERSION
    PREREQ_PM         => { Catalyst::Runtime => 5.7011, MRO::Compat => 0,
                           Sub::Name => 0},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Controller/DBIC/Transaction.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel Ruoso <daniel@ruoso.com>') : ()),
);
