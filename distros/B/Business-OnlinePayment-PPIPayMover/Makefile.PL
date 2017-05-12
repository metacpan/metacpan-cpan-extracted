use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::OnlinePayment::PPIPayMover',
    VERSION_FROM      => 'lib/Business/OnlinePayment/PPIPayMover.pm', # finds $VERSION
    PREREQ_PM         => { 'Business::OnlinePayment' => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/OnlinePayment/PPIPayMover.pm', # retrieve abstract from module
       AUTHOR         => 'Ivan Kohler <ivan-ppipaymover@420.am>') : ()),
);
