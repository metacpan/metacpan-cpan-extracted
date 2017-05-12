use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $VERSION = q$Revision$ =~ /(\d+)/;
WriteMakefile(
    NAME              => 'BGPmon::CPM',
    VERSION           => VERSION,
    PREREQ_PM         => {Rose::DB::Object => 0.797, 
                          BGPmon::CPM::Prefix::Finder => 1.00,
                          Net::DNS => 0.67, 
                          JSON => 2.53, 
                          Net::IP => 1.25, 
                          DBD::Pg => 2 }, 
    ($] >= 5.005 ?     
      (
       AUTHOR         => 'bgpmon<bgpmon@netsec.colostate.edu>') : ()),
);
