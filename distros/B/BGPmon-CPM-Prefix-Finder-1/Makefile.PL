use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'BGPmon::CPM::Prefix::Finder',
    VERSION           => 'VERSION', # finds $VERSION
    PREREQ_PM         => {
                         Net::DNS => 0.67, 
                         JSON => 2.53, 
                         Data::Dumper => 2.124,
                         LWP::UserAgent => 5.834 ,
                         Net::IP => 1.25},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/BGPmon/CPM/Prefix/Finder.pm', # retrieve abstract from module
       AUTHOR         => 'Catherine Olschanowsky <cathie@cs.colostate.edu>') : ()),
);
